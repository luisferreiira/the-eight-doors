"""Inventory and conservative cleanup proposal. Does not delete files."""
from pathlib import Path
import hashlib,json,re,collections
R=Path(__file__).resolve().parents[1]
O=R/'docs/auditoria_limpeza_20261028'
assert (R/'project.godot').is_file()
files=sorted(p for p in R.rglob('*') if p.is_file() and not p.is_symlink() and not p.is_relative_to(O))
text_ext={'.gd','.tscn','.tres','.godot','.cfg','.py','.ps1','.md','.json','.txt','.toml','.ini','.import','.uid','.svg','.gdshader','.bat','.sh'}
texts={p.relative_to(R).as_posix():p.read_text(encoding='utf-8-sig',errors='replace') for p in files if p.suffix in text_ext and '.godot' not in p.relative_to(R).parts and p.stat().st_size<5000000}
rows=[]; hashes=collections.defaultdict(list)
direct=collections.defaultdict(set);missing=[];dynamic=[]
for src,t in texts.items():
    for ref in re.findall(r'res://([^\s"\'\)\],;]+)',t):
        direct[ref].add(src)
        if src.endswith(('.tscn','.tres','.godot')) and not (R/ref).exists(): missing.append({'source':src,'target':ref})
    for n,line in enumerate(t.splitlines(),1):
        if re.search(r'\b(load|preload|ResourceLoader|DirAccess|FileAccess|glob|rglob)\b',line): dynamic.append({'source':src,'line':n,'text':line[:240]})
for p in files:
    rel=p.relative_to(R).as_posix();size=p.stat().st_size
    h=hashlib.sha256(p.read_bytes()).hexdigest();hashes[h].append(rel)
    refs=sorted(direct.get(rel,set()) | {s for s,t in texts.items() if s!=rel and (rel in t or (p.name in t and p.suffix in {'.log','.tmp','.pyc'}))})
    if rel.startswith(('../arquivo-the-eight-doors/art_reviews/','docs/','../arquivo-the-eight-doors/backups/','tools/','tests/','.godot/')) or rel.endswith('.bak'): cat='C'
    elif rel.startswith('assets/') and not refs: cat='B'
    else: cat='A'
    reason='Preservar: essencial ou conservadoramente necessario' if cat=='A' else ('Preservar: recurso futuro/original' if cat=='B' else 'Preservar: desenvolvimento/cache/historico')
    # Only empty, unreferenced historical output logs are initially safe proposals.
    if rel.startswith('docs/') and p.suffix=='.log' and size==0 and not refs:
        cat='D';reason='Log historico vazio, sem conteudo e sem referencia identificada; recriavel como arquivo vazio'
    rows.append(dict(path=rel,bytes=size,sha256=h,category=cat,reason=reason,references=refs))
duplicates=[dict(sha256=h,paths=ps,bytes_each=next(r['bytes'] for r in rows if r['path']==ps[0]),action='Preservar; identidade de conteudo nao prova papel dispensavel') for h,ps in hashes.items() if len(ps)>1]
plugins=[dict(path=p.relative_to(R).as_posix(),enabled=p.relative_to(R).as_posix() in texts['project.godot'],config=texts.get(p.relative_to(R).as_posix(),'')) for p in files if p.name=='plugin.cfg']
summary=dict(root=str(R),files=len(rows),bytes=sum(r['bytes'] for r in rows),categories={c:dict(files=sum(r['category']==c for r in rows),bytes=sum(r['bytes'] for r in rows if r['category']==c)) for c in 'ABCD'},duplicate_groups=len(duplicates),extra_duplicate_copies=sum(len(d['paths'])-1 for d in duplicates),largest=sorted(rows,key=lambda r:r['bytes'],reverse=True)[:15],plugins=plugins,missing_references=missing)
O.mkdir(parents=True,exist_ok=True)
for name,data in [('inventario',rows),('duplicatas',duplicates),('cargas_dinamicas',dynamic),('resumo',summary)]:
    (O/f'{name}.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False,indent=2))
print('D:',json.dumps([r['path'] for r in rows if r['category']=='D']))
