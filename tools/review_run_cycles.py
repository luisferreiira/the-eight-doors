from pathlib import Path
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'../arquivo-the-eight-doors/art_reviews/run_cycles_v2'
OUT.mkdir(parents=True,exist_ok=True)
paths=sorted((ROOT/'assets/generated/personagens').glob('*/*.png'))
paths=[p for p in paths if 'run_' in p.name or 'correndo_' in p.name]
canvas=Image.new('RGB',(1024,len(paths)*280),(45,45,50))
for i,p in enumerate(paths):
    im=Image.open(p).convert('RGBA')
    print(p.name,im.size)
    assert im.size==(256,64)
    ImageDraw.Draw(canvas).text((4,i*280+2),p.name,fill='white')
    big=im.resize((1024,256),Image.Resampling.NEAREST)
    canvas.paste(big,(0,i*280+22),big)
    for j in range(4):
        im.crop((j*64,0,(j+1)*64,64)).save(OUT/f'{p.stem}_{j+1}.png')
canvas.save(OUT/'originals.png')

# Front prototype: independently posed thighs, shins and boots, using only
# colors sampled from the original lower-body palette; no mirrored frame.
import shutil, hashlib
src=ROOT/'assets/environments/generated/personagens/aelin/aelin_run_frente.png'
digest=hashlib.sha256(src.read_bytes()).hexdigest()
backup=OUT/'aelin_run_frente.original.png'
if not backup.exists(): shutil.copy2(src,backup)
strip=Image.open(src).convert('RGBA')
frames=[strip.crop((i*64,0,(i+1)*64,64)) for i in range(4)]
palette=set(p for f in frames for p in f.crop((25,46,39,63)).getdata() if p[3]>128)
def color(rgb):
    return min(palette,key=lambda p:sum((p[k]-rgb[k])**2 for k in range(3)))
edge=color((27,19,19)); dark=color((43,30,26)); mid=color((70,45,30)); light=color((105,66,37)); gold=color((132,85,39))
# Viewer-left and viewer-right leg: knee, ankle, toe. Opposing contact and
# passing poses include different knee bends, rather than translating a leg.
poses=[(((28,51),(29,54),(28,55)),((35,53),(35,60),(36,61))),
       (((29,53),(28,58),(27,59)),((34,50),(33,55),(34,56))),
       (((28,53),(28,60),(27,61)),((35,51),(34,54),(35,55))),
       (((29,50),(30,55),(29,56)),((34,53),(35,58),(36,59)))]
edited=[]
for i,f in enumerate(frames):
    out=f.copy(); d=ImageDraw.Draw(out)
    d.rectangle((24,46,40,63),fill=(0,0,0,0))
    for side in ([0,1] if i<2 else [1,0]):
        hip=(28 if side==0 else 35,46)
        knee,ankle,toe=poses[i][side]
        d.line([hip,knee,ankle],fill=edge,width=6)
        d.line([hip,knee],fill=mid,width=4)
        d.line([knee,ankle],fill=dark,width=4)
        d.line([(hip[0]-1,hip[1]),(knee[0]-1,knee[1])],fill=light,width=1)
        d.line([(knee[0]-1,knee[1]),(knee[0]+1,knee[1])],fill=gold,width=1)
        d.line([ankle,toe],fill=edge,width=5)
        d.line([(ankle[0]-1,ankle[1]-2),ankle,toe],fill=mid,width=2)
    out.paste(f.crop((0,0,64,46)),(0,0))
    assert out.crop((0,0,64,46)).tobytes()==f.crop((0,0,64,46)).tobytes()
    out.save(OUT/f'aelin_front_pose_{i+1}.png'); edited.append(out)
candidate=Image.new('RGBA',(256,64))
for i,f in enumerate(edited): candidate.paste(f,(i*64,0))
candidate.save(OUT/'aelin_run_frente_estudo.png')
comparison=Image.new('RGB',(1024,560),(45,45,50))
for row,im in enumerate((strip,candidate)):
    ImageDraw.Draw(comparison).text((4,row*280+2),'ORIGINAL' if row==0 else 'ESTUDO DE POSES - NAO INTEGRADO',fill='white')
    big=im.resize((1024,256),Image.Resampling.NEAREST)
    comparison.paste(big,(0,row*280+22),big)
comparison.save(OUT/'aelin_front_comparacao.png')
gif=[]
for original,new in zip(frames,edited):
    im=Image.new('RGB',(512,280),(45,45,50))
    ImageDraw.Draw(im).text((4,2),'ORIGINAL                         ESTUDO',fill='white')
    for x,f in ((0,original),(256,new)):
        big=f.resize((256,256),Image.Resampling.NEAREST); im.paste(big,(x,24),big)
    gif.append(im)
gif[0].save(OUT/'aelin_front_loop.gif',save_all=True,append_images=gif[1:],duration=125,loop=0)
assert hashlib.sha256(src.read_bytes()).hexdigest()==digest
print('Front prototype saved. Original hash preserved. Upper body byte-identical.')
