extends Control
## Somente o estado muda: posições, cores e texturas ficam salvas na cena.
@export var coracao_cheio: Texture2D
@export var coracao_vazio: Texture2D
func update_status(lives: int, score: int) -> void:
 for i in range(3):
  get_node("Coracao" + str(i + 1)).texture = coracao_cheio if i < lives else coracao_vazio
 $Pontos.text = "Pontos: %s" % score
 tooltip_text = "Vidas: %s de 3" % lives
