"""Execute the historical generator and verify production stays byte-identical."""
from pathlib import Path
import hashlib, subprocess, sys
root=Path(__file__).resolve().parents[2]
paths=list((root/'assets/generated/personagens').rglob('*.png'))
paths += [root/f'scenes/players/{who}.tscn' for who in ('aelin','dorian')]
manifest=root/'docs/history/dungeon_jogavel/sprites_manifest.json'
if manifest.exists(): paths.append(manifest)
before={p:hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
subprocess.run([sys.executable,str(root/'tools/personagens/preparar_quadros.py')],check=True)
assert all(hashlib.sha256(p.read_bytes()).hexdigest()==h for p,h in before.items())
print(f'PASS: {len(before)} production files unchanged after actual regeneration.')
