extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var suite = load("res://tests/test_fase_caverna_visual.gd").new()
 root.add_child(suite)
 for method in suite.get_method_list():
  if str(method.name).begins_with("test_"):
   print("CAVERNA: ", method.name)
   suite.call(method.name)
 suite.queue_free()
 quit()
