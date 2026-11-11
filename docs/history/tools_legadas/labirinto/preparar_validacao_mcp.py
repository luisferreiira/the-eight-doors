import json
from pathlib import Path
root = Path(__file__).resolve().parents[2]
calls = [
    {'name':'project_manage','label':'parar_teste','arguments':{'op':'stop'}},
    {'name':'project_manage','label':'principal','arguments':{'op':'set_main_scene','params':{'path':'res://scenes/world/labyrinth/labirinto.tscn'}}},
    {'name':'project_run','label':'execucao_final','arguments':{'mode':'main','autosave':False}},
]
for direction in ['N','NE','L','S','SO']:
    code = ('var game = get_tree().current_scene\n'
            'var suite = load("res://tests/runtime_labirinto.gd").new()\n'
            f'return await suite.run(game, "{direction}")')
    calls.append({'name':'editor_manage','label':'travessia_'+direction,'arguments':{'op':'game_eval','params':{'code':code}}})
calls.extend([
    {'name':'editor_state','label':'estado_final','arguments':{}},
    {'name':'logs_read','label':'logs_finais_jogo','arguments':{'source':'game','include_details':True}},
    {'name':'logs_read','label':'logs_finais_editor','arguments':{'source':'editor','include_details':True}},
])
(root/'docs/history/expansao_2026-10-30/validacao_final_mcp.json').write_text(json.dumps(calls,indent=2),encoding='utf-8')
