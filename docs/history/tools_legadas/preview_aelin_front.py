from pathlib import Path
from PIL import Image, ImageDraw
import hashlib, shutil

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'assets/environments/generated/personagens/aelin/aelin_run_frente.png'
OUT = ROOT / '../arquivo-the-eight-doors/art_reviews/aelin_front_v1'
OUT.mkdir(parents=True, exist_ok=True)
original = Image.open(SRC).convert('RGBA')
assert original.size == (256, 64), original.size
backup = OUT / 'aelin_run_frente.original.png'
if not backup.exists():
    shutil.copy2(SRC, backup)
original.resize((1536,384), Image.Resampling.NEAREST).save(OUT/'original_ampliado.png')
print(OUT)
before_hash = hashlib.sha256(SRC.read_bytes()).hexdigest()
frames = [original.crop((i*64,0,(i+1)*64,64)) for i in range(4)]
edited = [f.copy() for f in frames]
# Reflect only the lower limb region around the fixed body center.
# Upper body, hands, cape, hair and face retain their exact original pixels.
for i in (2,3):
    legs = frames[i].crop((24,47,40,64))
    edited[i].paste(legs.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (24,47))
sheet = Image.new('RGBA', original.size)
for i, frame in enumerate(edited):
    sheet.paste(frame,(64*i,0))
    frames[i].save(OUT/f'original_frame_{i+1}.png')
    frame.save(OUT/f'corrigido_frame_{i+1}.png')
sheet.save(OUT/'aelin_run_frente.candidato.png')
comparison = Image.new('RGB',(1024,560),(42,44,50))
draw = ImageDraw.Draw(comparison)
draw.text((8,4),'ORIGINAL - quadros 1, 2, 3, 4',(255,255,255))
draw.text((8,284),'CANDIDATO - alteracao apenas nas pernas dos quadros 3 e 4',(255,255,255))
for row, strip in enumerate((original,sheet)):
    scaled = strip.resize((1024,256),Image.Resampling.NEAREST)
    comparison.paste(scaled,(0,row*280+24),scaled)
comparison.save(OUT/'comparacao_quadros.png')
animation=[]
for i in range(4):
    canvas=Image.new('RGB',(544,288),(42,44,50))
    d=ImageDraw.Draw(canvas)
    d.text((8,4),'ORIGINAL',(255,255,255)); d.text((280,4),'CANDIDATO',(255,255,255))
    for x,f in ((0,frames[i]),(280,edited[i])):
        enlarged=f.resize((256,256),Image.Resampling.NEAREST)
        canvas.paste(enlarged,(x,24),enlarged)
    animation.append(canvas)
animation[0].save(OUT/'comparacao_animada.gif',save_all=True,append_images=animation[1:],duration=125,loop=0,disposal=2)
assert hashlib.sha256(SRC.read_bytes()).hexdigest()==before_hash
assert sheet.size==(256,64)
for i in range(4):
    assert edited[i].crop((0,0,64,47)).tobytes()==frames[i].crop((0,0,64,47)).tobytes()
print('Original preservado; RGBA 256x64; quatro frames; regiao superior identica; 8 FPS.')
