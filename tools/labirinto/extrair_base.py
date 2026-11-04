"""Extract the current authored room once; never rewrite character/source scenes."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
source = (ROOT / 'scenes/world/environments/sala_central_jogavel.tscn').read_text(encoding='utf-8')
header, nodes = source.split('[node ', 1)
header = re.sub(r'\[gd_scene[^\n]+', '[gd_scene format=3]', header, count=1)
header = re.sub(r'^\[ext_resource .*id="(?:6_lsg2n|8_boyux)"\]\n', '', header, flags=re.M)
header = header.replace('res://scripts/world/passagem_preparada.gd', 'res://scripts/world/porta.gd')
header = re.sub(r' uid="[^"]+"', '', header)
header = header.replace('[sub_resource ', '[ext_resource type="Script" path="res://scripts/world/sala.gd" id="20_sala"]\n\n[sub_resource ', 1)
blocks = ['[node ' + block for block in nodes.split('[node ')]
kept = []
for block in blocks:
    declaration = block.split('\n', 1)[0]
    if any(s in declaration for s in ['name="Aelin"', 'parent="Aelin"', 'name="Atmosfera"', 'parent="Atmosfera"']):
        continue
    block = re.sub(r' unique_id=\d+', '', block)
    if 'name="SalaCentralJogavel"' in declaration:
        block = block.replace('SalaCentralJogavel', 'SalaOctogonalBase')
        block = block.replace('\n', '\nscript = ExtResource("20_sala")\n', 1)
    kept.append(block)
(ROOT / 'scenes/world/labyrinth/sala_octogonal_base.tscn').write_text(header + ''.join(kept), encoding='utf-8')

# Preserve the shader and its parameters, but anchor the vignette to the viewport.
material = re.search(r'\[sub_resource type="ShaderMaterial"[^\n]+\n.*?(?=\n\[)', source, re.S).group()
shader = re.search(r'\[ext_resource type="Shader"[^\n]+', source).group()
atmosphere = '\n'.join([
    '[gd_scene format=3]', shader, material,
    '[node name="Atmosfera" type="CanvasLayer"]', 'layer = 10', '',
    '[node name="Vinheta" type="ColorRect" parent="."]',
    'material = SubResource("ShaderMaterial_ruge2")', 'anchors_preset = 15',
    'anchor_right = 1.0', 'anchor_bottom = 1.0', 'grow_horizontal = 2',
    'grow_vertical = 2', 'mouse_filter = 2', '',
])
(ROOT / 'scenes/world/environments/atmosfera.tscn').write_text(atmosphere, encoding='utf-8')
print('Sala-base extraida; origem e personagens preservados.')
