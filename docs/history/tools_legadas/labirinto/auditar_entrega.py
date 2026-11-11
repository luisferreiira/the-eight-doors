"""Preservation, resource references, spatial drawing and delivery inventory."""
from pathlib import Path
import hashlib
import json
import re
import difflib

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/expansao_2026-10-30'
BACKUP = ROOT / '../arquivo-the-eight-doors/backups/expansao_2026-10-30'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()

baseline = json.loads((OUT/'hashes_preservados_antes.json').read_text(encoding='utf-8-sig'))
changed = [entry['Path'] for entry in baseline if not Path(entry['Path']).exists() or sha(Path(entry['Path'])) != entry['Hash']]
originals = {}
for backup in BACKUP.glob('*.bak'):
    relative = backup.name[:-4].replace('__','/')
    current = ROOT / relative
    originals[relative] = {'unchanged':sha(backup)==sha(current),'before':sha(backup),'after':sha(current)}
missing = []
for path in (ROOT/'scenes/labirinto').glob('*'):
    if path.suffix not in ('.gd','.tscn'): continue
    # Metadata can describe a historical source; only actual paths/loads are dependencies.
    pattern = r'(?:path=|preload\(|load\()["\'](res://[^"\']+)'
    for reference in re.findall(pattern,path.read_text(encoding='utf-8')):
        if not (ROOT/reference[6:]).exists(): missing.append({'file':str(path.relative_to(ROOT)),'reference':reference})
project_before = (BACKUP/'project.godot.bak').read_text(encoding='utf-8').splitlines()
project_after = (ROOT/'project.godot').read_text(encoding='utf-8').splitlines()
(OUT/'project.diff').write_text('\n'.join(difflib.unified_diff(project_before,project_after,fromfile='project.godot antes',tofile='project.godot depois')),encoding='utf-8')
result = {'protected_files':len(baseline),'protected_changes':changed,'backed_up_originals':originals,'missing_expansion_references':missing,'reference_scene_currently_exists':(ROOT/'scenes/dungeon/sala_central_referencia.tscn').exists()}
(OUT/'preservacao.json').write_text(json.dumps(result,indent=2,ensure_ascii=False),encoding='utf-8')

rooms = {'S01':(0,0),'S02':(0,-1),'S03':(1,-1),'S04':(1,0),'S05':(0,1),'S06':(-1,1)}
portals = {'N':(560,192),'NE':(928,320),'L':(1056,576),'S':(560,960),'SO':(192,832),'O':(64,576)}
opposites = {'N':'S','NE':'SO','L':'O','S':'N','SO':'NE'}
links = {'N':'S02','NE':'S03','L':'S04','S':'S05','SO':'S06'}
contour = [(320,192),(800,192),(1056,448),(1056,704),(800,960),(320,960),(64,704),(64,448)]
svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="880" height="800" viewBox="-1600 -1500 4400 4000">', '<rect x="-1600" y="-1500" width="4400" height="4000" fill="#10151c"/>', '<g font-family="sans-serif">']
svg.append('<text x="-1450" y="-1270" font-size="105" fill="#ece2ca">THE EIGHT DOORS · mapa físico</text>')
for direction, target in links.items():
    a = portals[direction]
    p = portals[opposites[direction]]
    coord = rooms[target]
    b = (coord[0]*1440+p[0],coord[1]*1216+p[1])
    svg.append(f'<path d="M {a[0]} {a[1]} L {b[0]} {b[1]}" stroke="#679e9c" stroke-width="80"/>')
for name, coord in rooms.items():
    x,y = coord[0]*1440,coord[1]*1216
    points = ' '.join(f'{x+px},{y+py}' for px,py in contour)
    svg.append(f'<rect x="{x}" y="{y}" width="1120" height="1024" fill="none" stroke="#33414d" stroke-width="8" stroke-dasharray="24 20"/>')
    svg.append(f'<polygon points="{points}" fill="{"#34484a" if name=="S01" else "#222f3c"}" stroke="#c5b78f" stroke-width="14"/>')
    svg.append(f'<text x="{x+560}" y="{y+560}" text-anchor="middle" font-size="110" fill="#f1e7ca">{name}</text>')
    svg.append(f'<text x="{x+560}" y="{y+690}" text-anchor="middle" font-size="80" fill="#a6bdc5">{coord}</text>')
svg.append('<text x="-1450" y="2380" font-size="74" fill="#b4c4ce">Passagens implícitas · uma sala visível por vez · escala física proporcional</text></g></svg>')
(OUT/'mapa.svg').write_text('\n'.join(svg),encoding='utf-8')
created = []
for folder in ['scenes/labirinto','tools/labirinto','docs/expansao_2026-10-30','../arquivo-the-eight-doors/backups/expansao_2026-10-30']:
    created += [str(path.relative_to(ROOT)).replace('\\','/') for path in (ROOT/folder).rglob('*') if path.is_file()]
created += [str(path.relative_to(ROOT)).replace('\\','/') for path in (ROOT/'tests').glob('*labirinto*') if path.is_file()]
(OUT/'arquivos.json').write_text(json.dumps({'modified_existing':['project.godot'],'created':sorted(created)},indent=2),encoding='utf-8')
print(json.dumps({'protected':len(baseline),'changed':changed,'missing':missing,'original_scene_unchanged':originals['scenes/world/environments/sala_central_jogavel.tscn']['unchanged']},ensure_ascii=False))
assert not changed and not missing
assert all(data['unchanged'] for name,data in originals.items() if name != 'project.godot')
