from pathlib import Path
import json, shutil, zipfile
r=Path.cwd()
if (r/"docs/organizacao_manifesto.json").exists():
 raise SystemExit("Organização já aplicada. Migração bloqueada para proteger os arquivos.")
archive=r.parent/'arquivo-the-eight-doors'; archive.mkdir(exist_ok=True)
# Snapshot textual permite restaurar caminhos e referências anteriores.
with zipfile.ZipFile(archive/'antes_organizacao.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in r.rglob('*'):
  if p.is_file() and not any(x in p.parts for x in ['.godot','addons','backups']) and p.suffix in ['.gd','.tscn','.tres','.godot','.uid','.import','.md','.py']:
   z.write(p,p.relative_to(r))
moves={}
def directory(src,dst):
 for p in (r/src).rglob('*'):
  if p.is_file(): moves[p.relative_to(r).as_posix()]=(Path(dst)/p.relative_to(r/src)).as_posix()
def file(src,dst):
 if (r/src).exists(): moves[src]=dst
 if (r/(src+'.uid')).exists(): moves[src+'.uid']=dst+'.uid'
for a,b in [('scenes/menus','scenes/ui/menus'),('scenes/players','scenes/characters/players'),('scenes/salas','scenes/world/rooms'),('scenes/labirinto','scenes/world/labyrinth'),('scenes/dungeon','scenes/world/environments'),('assets/personagens','assets/characters'),('assets/poderes','assets/characters/poderes'),('assets/mapa','assets/environments/mapa'),('assets/generated','assets/environments/generated'),('assets/RF_Catacombs_v1.0','assets/environments/RF_Catacombs_v1.0'),('assets/RPGW_Caves_v2.1','assets/environments/RPGW_Caves_v2.1'),('assets/menus','assets/ui'),('docs','docs/history')]: directory(a,b)
for p in (r/'scenes').rglob('*.gd'):
 category='world'
 if p.parent.name=='shared': category='characters'
 elif p.name.startswith('camera_'): category='camera'
 elif p.name=='transicao_fade.gd': category='effects'
 elif p.name=='mapa_editor.gd': category='editor'
 dest=('tools/editor/' if category=='editor' else 'scripts/'+category+'/')+p.name
 file(p.relative_to(r).as_posix(),dest)
file('scenes/dungeon/vinheta.gdshader','assets/shaders/vinheta.gdshader')
file('scenes/labirinto/atmosfera.tscn','scenes/world/environments/atmosfera.tscn')
file('fase_caverna.tscn','scenes/world/environments/fase_caverna.tscn')
for n in ['estado_jogo','pause_overlay']: file('scripts/ui/'+n+'.gd','scripts/autoload/'+n+'.gd')
for p in (r/'assets/menus/sons').glob('*'):
 moves[p.relative_to(r).as_posix()]='assets/audio/'+('music/' if p.name.startswith('trilha') else 'sfx/')+p.name
for p in (r/'assets').rglob('*.tres'):
 old=p.relative_to(r).as_posix(); moves[old]='resources/'+p.relative_to(r/'assets').as_posix()
# Documentação atual permanece acessível; relatórios vão ao histórico.
moves['docs/arquitetura_codigo.md']='docs/arquitetura_codigo.md'
# Substituição simultânea evita converter um caminho duas vezes.
import re
mapping={a:b for a,b in moves.items() if a!=b}
# Diretórios de saída usados pelas ferramentas e testes.
for p in (r/'docs').iterdir():
 if p.is_dir(): mapping['docs/'+p.name+'/']='docs/history/'+p.name+'/'
pattern=re.compile('|'.join(re.escape(k) for k in sorted(mapping,key=len,reverse=True)))
for p in list(r.rglob('*')):
 if not p.is_file() or any(x in p.parts for x in ['.godot','addons','backups','art_reviews']): continue
 if p.name=='reorganizar_projeto.py': continue
 if p.suffix not in ['.gd','.tscn','.tres','.godot','.import','.md','.py','.json','.cfg']: continue
 try: s=p.read_text(encoding='utf-8-sig')
 except UnicodeError: continue
 t=pattern.sub(lambda m:mapping[m[0]],s)
 if t!=s: p.write_text(t,encoding='utf-8')
for a,b in moves.items():
 if a==b: continue
 src=r/a; dest=r/b; dest.parent.mkdir(parents=True,exist_ok=True); shutil.move(str(src),str(dest))
for name in ['backups','art_reviews']:
 if (r/name).exists(): shutil.move(str(r/name),str(archive/name))
for p in r.glob('*.bak'): shutil.move(str(p),str(archive/p.name))
# Somente diretórios vazios dentro do projeto.
for p in sorted(r.rglob('*'),key=lambda x:len(x.parts),reverse=True):
 if p.is_dir() and not any(x in p.parts for x in ['.godot','addons']):
  try:p.rmdir()
  except OSError:pass
(r/'docs').mkdir(exist_ok=True)
(r/'docs/organizacao_manifesto.json').write_text(json.dumps(moves,indent=2,ensure_ascii=False),encoding='utf-8')
print('Movidos',len(moves),'arquivos; arquivo histórico:',archive)
