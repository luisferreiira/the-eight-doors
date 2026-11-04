"""Record a rejected generation without modifying any production assets."""
from pathlib import Path
import shutil, json
from PIL import Image

root=Path(__file__).resolve().parents[2]
source=Path(r'C:\Users\luisg\.codex\generated_images\01a17f9a-3c6f-7a20-b590-31afa1573c03\exec-ac04c451-f923-45a1-83bc-d874a9d37984.png')
out=root/'../arquivo-the-eight-doors/art_reviews/aelin_front_reference_edit'
out.mkdir(parents=True,exist_ok=True)
shutil.copy2(source,out/'aelin_frente_reprovado.png')
im=Image.open(source).convert('RGBA')
cell_width=(im.width+3)//4
frames=[]
for i in range(4):
    left=round(i*im.width/4)
    frame=im.crop((left,0,left+cell_width,im.height))
    bg=Image.new('RGB',frame.size,(45,45,50)); bg.paste(frame,(0,0),frame)
    frames.append(bg)
frames[0].save(out/'loop_reprovado.gif',save_all=True,append_images=frames[1:],duration=125,loop=0)
original=Image.open(root/'assets/environments/generated/personagens/aelin/aelin_run_frente.png')
report={'status':'REPROVADO - NAO INTEGRADO','original_size':original.size,'generated_size':im.size,'frames':4,'reason':'Geracao alterou resolucao, proporcoes e pixels fora das pernas. Nao preserva identidade pixel a pixel.','method':'imagegen com referencia; pedido de edicao somente das pernas, quatro poses alternadas, transparencia, 256x64 e preservacao do restante.'}
(out/'validacao.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
