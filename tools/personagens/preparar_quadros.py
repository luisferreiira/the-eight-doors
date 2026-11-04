"""Regeneracao historica para revisao; nunca sobrescreve cenas ou PNGs em uso.

Os templates de 26/10 nao representam as cenas atuais. A saida deve ser
avaliada visualmente antes de qualquer integracao manual em producao.
"""
from pathlib import Path
from PIL import Image
import numpy as np
import re,json,hashlib
BASE=Path(__file__).resolve().parents[2]
from datetime import datetime
OUTPUT=BASE/'../arquivo-the-eight-doors/art_reviews'/'regeneracao_historica'/datetime.now().strftime('%Y%m%d_%H%M%S_%f')
OUTPUT.mkdir(parents=True,exist_ok=False)
(OUTPUT/'.gdignore').touch()
report=[]
for who in ('aelin','dorian'):
 scene_path=BASE/f'scenes/players/{who}.tscn'
 text=(BASE/f'../arquivo-the-eight-doors/backups/dungeon_personagens_2026-10-26/{who}.tscn.bak').read_text(encoding='utf-8')
 textures={}
 matches=list(re.finditer(r'\[ext_resource type="Texture2D"[^\n]*path="res://([^\"]+)" id="([^\"]+)"\]',text))
 for match in matches:
  path,key=match.groups();im=Image.open(BASE/path).convert('RGBA');a=np.asarray(im)[:,:,3]
  projection=(a>127).sum(axis=0);w,h=im.size
  cuts=[0]
  for n in (1,2,3):
   nominal=round(w*n/4); candidates=list(range(nominal-58,nominal+59))
   cut=min(candidates,key=lambda x:(sum(projection[max(0,x-1):x+2]),abs(x-nominal)))
   cuts.append(cut)
  cuts.append(w)
  frames=[];boxes=[]
  for n in range(4):
   frame=im.crop((cuts[n],0,cuts[n+1],h))
   # Ignore near-transparent colored remnants at sheet edges, not character pixels.
   alpha=frame.getchannel('A').point(lambda v:255 if v>80 else 0)
   box=alpha.getbbox();assert box is not None,(who,path,n)
   frames.append(frame.crop(box));boxes.append([cuts[n]+box[0],box[1],cuts[n]+box[2],box[3]])
  textures[key]={'path':path,'frames':frames,'boxes':boxes,'size':[w,h]}
 # Fixed scale across every direction/state for each character; bottom aligned at y=64.
 max_h=max(f.height for t in textures.values() for f in t['frames'])
 max_w=max(f.width for t in textures.values() for f in t['frames'])
 factor=min(56/max_h,60/max_w)
 for key,t in textures.items():
  sheet=Image.new('RGBA',(256,64))
  for n,frame in enumerate(t['frames']):
   small=frame.resize((round(frame.width*factor),round(frame.height*factor)),Image.Resampling.NEAREST)
   sheet.alpha_composite(small,(n*64+(64-small.width)//2,64-small.height))
  dest=OUTPUT/f'assets/{who}/{Path(t["path"]).name}'
  dest.parent.mkdir(parents=True,exist_ok=True);sheet.save(dest)
  old=next(m.group(0) for m in matches if m.group(2)==key)
  text=text.replace(old,f'[ext_resource type="Texture2D" path="res://{dest.relative_to(BASE).as_posix()}" id="{key}"]')
  report.append({'character':who,'original':t['path'],'sha256':hashlib.sha256((BASE/t['path']).read_bytes()).hexdigest(),'original_size':t['size'],'cuts':t['boxes'],'output':dest.relative_to(BASE).as_posix(),'scale':factor})
 # Replace each existing atlas rectangle with its matching normalized frame.
 counts={}
 def normalize(m):
  block=m.group(0);key=re.search(r'atlas = ExtResource\("([^\"]+)"\)',block).group(1)
  n=counts.get(key,0);counts[key]=n+1
  return re.sub(r'region = Rect2\([^\n]+',f'region = Rect2({n*64}, 0, 64, 64)',block)
 text=re.sub(r'\[sub_resource type="AtlasTexture"[^\n]+\]\natlas = [^\n]+\nregion = [^\n]+',normalize,text)
 text=text.replace('[sub_resource type="SpriteFrames"', '[sub_resource type="SpriteFrames"',1)
 text=text.replace('[ext_resource type="Texture2D"', '[ext_resource type="Texture2D"',1)
 first_sub=text.index('[sub_resource')
 text=text[:first_sub]+'[ext_resource type="Script" path="res://scripts/characters/personagem_top_down.gd" id="10_movimento"]\n\n'+text[first_sub:]
 text=re.sub(r'(\[sub_resource type="CapsuleShape2D"[^\n]+\]\n)radius = [^\n]+\nheight = [^\n]+',r'\g<1>radius = 8.0\nheight = 18.0',text)
 text=re.sub(r'(\[node name="'+who.capitalize()+r'" type="CharacterBody2D"[^\n]+\]\n)',r'\g<1>texture_filter = 1\ncollision_layer = 2\ncollision_mask = 1\nscript = ExtResource("10_movimento")\nidle_prefix = "'+('parada' if who=='aelin' else 'parado')+'"\n',text)
 text=text.replace('metadata/_edit_group_ = true\n','')
 text=re.sub(r'(\[node name="AnimatedSprite2D"[^\n]+\]\n)',r'\g<1>position = Vector2(0, -32)\n',text)
 text=re.sub(r'(\[node name="CollisionShape2D"[^\n]+\]\n)',r'\g<1>position = Vector2(0, -6)\n',text)
 # Four walking frames at 8 fps; subtle idle at original 5 fps.
 text=re.sub(r'("name": &"correndo_[^\"]+",\n"speed": )5.0',r'\g<1>8.0',text)
 (OUTPUT/f'{who}.tscn.preview.txt').write_text(text,encoding='utf-8')
(OUTPUT/'sprites_manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('Prepared',len(report),'historical review sheets in',OUTPUT,'; production scenes and assets untouched')

