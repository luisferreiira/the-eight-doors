extends Area2D
## Apenas dados para uma futura transicao. Nao emite sinais nem troca cenas.
## A grade e seu bloqueio permanecem fechados ate essa mecanica ser implementada.
@export_enum("Norte", "Nordeste", "Leste", "Sudeste", "Sul", "Sudoeste", "Oeste", "Noroeste") var direcao: String = "Norte"
@export_file("*.tscn") var cena_destino: String = ""
@export var ponto_entrada: StringName = &""
