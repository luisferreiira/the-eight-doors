from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[1]
O=R/'docs/auditoria_limpeza_20261028'
baseline=json.loads((O/'inventario.json').read_text(encoding='utf-8'))
changed=[];removed=[]
for item in baseline:
    p=R/item['path']
    if not p.exists():removed.append(item['path'])
    elif hashlib.sha256(p.read_bytes()).hexdigest()!=item['sha256']:changed.append(item['path'])
expected=['docs/history/animacoes_visual_20261027/captura_erros.log']
assert removed==expected,removed
protected=[p for p in changed if p.startswith(('assets/','scenes/','addons/','../arquivo-the-eight-doors/art_reviews/','../arquivo-the-eight-doors/backups/')) or p=='project.godot' or p=='tools/personagens/preparar_quadros.py']
assert not protected,protected
report=dict(removed=removed,changed=changed,protected_files_unchanged=True,recovered_bytes=0,restoration='New-Item -ItemType File -Path docs/history/animacoes_visual_20261027/captura_erros.log',files_after=sum(p.is_file() for p in R.rglob('*')),bytes_after=sum(p.stat().st_size for p in R.rglob('*') if p.is_file()))
(O/'verificacao_final.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
