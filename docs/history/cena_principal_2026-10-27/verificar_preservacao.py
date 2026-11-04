from pathlib import Path
import hashlib
import json
import re

root = Path(__file__).resolve().parents[2]
doc = Path(__file__).resolve().parent
backup = root / 'backups/cena_principal_2026-10-27'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

preserved = [
    'scenes/dungeon/sala_central_referencia.tscn',
    'scenes/characters/players/aelin.tscn', 'scenes/characters/players/dorian.tscn',
    'scripts/characters/personagem_top_down.gd',
    'scripts/camera/camera_sala_central.gd',
    'scripts/world/passagem_lateral.gd',
]
checks = []
for name in preserved:
    original = root / name
    saved = backup / (name.replace('/', '__') + '.bak')
    checks.append({'path': name, 'unchanged': sha(original) == sha(saved),
                   'sha256': sha(original)})
assert all(c['unchanged'] for c in checks), checks

scene = root / 'scenes/world/environments/sala_central_jogavel.tscn'
dependencies = re.findall(r'\[ext_resource[^\n]*path="res://([^"]+)"', scene.read_text(encoding='utf-8'))
missing = [p for p in dependencies if not (root / p).exists()]
assert not missing, missing
for file in ['testes_funcionais.json', 'testes_mcp_runtime.json', 'testes_resolucoes.json']:
    assert not json.loads((doc / file).read_text(encoding='utf-8'))['failures'], file
logs = json.loads((doc / 'logs_final_mcp.json').read_text(encoding='utf-8'))['result']['structuredContent']
assert not [line for line in logs['lines'] if line.get('level') in ['error', 'warning']], logs
assert logs['helper_live'] and logs['is_running']

modified = ['project.godot', 'scenes/world/environments/sala_central_jogavel.tscn',
            'tools/dungeon_central/montar_jogavel.gd', 'tests/test_dungeon_jogavel.gd']
added = ['scripts/camera/camera_exploracao.gd', 'scripts/world/passagem_preparada.gd',
         'assets/shaders/vinheta.gdshader', 'tools/dungeon_central/corrigir_cena_principal.gd',
         'tools/dungeon_central/capturar_principal.gd', 'tests/test_cena_principal.gd',
         'tests/test_resolucoes.gd', 'tests/runtime_cena_principal.gd']
result = {'preserved': checks, 'missing_scene_dependencies': missing,
          'modified': [{'path': p, 'sha256': sha(root / p)} for p in modified],
          'added_implementation': [{'path': p, 'sha256': sha(root / p)} for p in added],
          'backups': [{'name': p.name, 'bytes': p.stat().st_size, 'sha256': sha(p)}
                      for p in sorted(backup.glob('*.bak'))],
          'evidence_files': sorted(p.name for p in doc.iterdir() if p.is_file())}
(doc / 'preservacao_e_arquivos.json').write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding='utf-8')
print(json.dumps({'preserved': len(checks), 'backups': len(result['backups']),
                  'missing_dependencies': missing, 'all_test_failures_empty': True,
                  'runtime_errors': 0}, ensure_ascii=False))
