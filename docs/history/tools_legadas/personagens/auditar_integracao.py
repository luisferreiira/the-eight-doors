"""Read-only production audit and review artifacts; no scene/asset rewrites."""
from pathlib import Path
import re, json, hashlib
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'../arquivo-the-eight-doors/art_reviews/integracao_20261028'
OUT.mkdir(parents=True,exist_ok=True)
runtime_files=[p for folder in ('scenes','resources') for p in (ROOT/folder).rglob('*') if p.suffix in ('.tscn','.tres','.gd')]
texts={p.relative_to(ROOT).as_posix():p.read_text(encoding='utf-8-sig') for p in runtime_files}
audit=[]
contact=Image.new('RGB',(1024,8*280),(45,45,50))
row=0
for who in ('aelin','dorian'):
    scene=texts[f'scenes/players/{who}.tscn']
    ext={key:path for path,key in re.findall(r'\[ext_resource type="Texture2D"[^\n]*path="res://([^\"]+)" id="([^\"]+)"\]',scene)}
    atlases={key:(texture,tuple(map(float,rect.split(',')))) for key,texture,rect in re.findall(r'\[sub_resource type="AtlasTexture" id="([^\"]+)"\]\s+atlas = ExtResource\("([^\"]+)"\)\s+region = Rect2\(([^)]+)\)',scene)}
    for block,name,speed in re.findall(r'"frames": \[(.*?)\],\s+"loop": (?:true|1),\s+"name": &"([^\"]+)",\s+"speed": ([\d.]+)',scene,re.S):
        ids=re.findall(r'SubResource\("([^\"]+)"\)',block)
        refs=[ext[atlases[k][0]] for k in ids]
        rects=[atlases[k][1] for k in ids]
        assert len(ids)==4,(who,name)
        assert rects==[(i*64.,0.,64.,64.) for i in range(4)],(who,name,rects)
        path=ROOT/refs[0]; im=Image.open(path).convert('RGBA')
        assert im.size==(256,64)
        frames=[im.crop((i*64,0,(i+1)*64,64)) for i in range(4)]
        original=list((ROOT/f'assets/personagens/{who}').rglob(path.name))
        audit.append(dict(character=who,animation=name,texture=refs[0],frames=4,fps=float(speed),loop=True,rects=rects,unique_frames=len({f.tobytes() for f in frames}),originals=[str(p.relative_to(ROOT)) for p in original],original_sizes=[Image.open(p).size for p in original]))
        if not name.startswith('correndo'): continue
        ImageDraw.Draw(contact).text((4,row*280+2),f'{who} {name} - CURRENT',fill='white')
        big=im.resize((1024,256),Image.Resampling.NEAREST);contact.paste(big,(0,row*280+22),big);row+=1
        previews=[]
        for f in frames:
            bg=Image.new('RGB',(256,256),(45,45,50));f=f.resize((256,256),Image.Resampling.NEAREST);bg.paste(f,(0,0),f);previews.append(bg)
        previews[0].save(OUT/f'{who}_{name}_atual.gif',save_all=True,append_images=previews[1:],duration=125,loop=0)
        # Show the entire source sheet; resizing here is for inspection only.
        for source in original:
            src=Image.open(source).convert('RGBA')
            src.thumbnail((1600,400),Image.Resampling.NEAREST)
            bg=Image.new('RGB',src.size,(45,45,50));bg.paste(src,(0,0),src)
            bg.save(OUT/f'{who}_{name}_fonte.png')
contact.save(OUT/'corridas_atuais.png')
(OUT/'auditoria.json').write_text(json.dumps(audit,indent=2,ensure_ascii=False),encoding='utf-8')
lines=['# Plano de limpeza — nenhuma exclusao executada','',
'Referencias abaixo verificadas em cenas, recursos e scripts. Ausencia de referencia direta nao prova ausencia de carregamento dinamico.', '',
'| Grupo | Arquivos | Bytes | Referencias diretas | Acao proposta / risco |','|---|---:|---:|---|---|']
for folder,proposal in [('../arquivo-the-eight-doors/art_reviews/aelin_front_v1','Arquivar apos revisao; baixo risco de runtime, preservar historico'),('../arquivo-the-eight-doors/art_reviews/run_cycles_v2','Arquivar estudos rejeitados; baixo risco de runtime'),('assets/personagens','Manter: fontes do gerador; alto risco de perda de material original'),('assets/generated/personagens','Manter: texturas atuais das cenas; alto risco visual'),('backups','Manter fora da distribuicao final; risco de perder recuperacao')]:
    files=[p for p in (ROOT/folder).rglob('*') if p.is_file()]
    refs=sorted({name for name,text in texts.items() if folder+'/' in text})
    lines.append(f'| {folder} | {len(files)} | {sum(p.stat().st_size for p in files)} | {", ".join(refs) or "Nenhuma literal encontrada"} | {proposal} |')
(OUT/'plano_limpeza.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(json.dumps(audit,ensure_ascii=False))
print('Review artifacts:',OUT)
