extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	change_scene_to_file("res://scenes/layered_demo.tscn")
	await scene_changed
	var demo := current_scene
	if not demo.layout.errors.is_empty() or demo.targets.is_empty():
		printerr("Gatehouse setup invalid: ",demo.layout.errors)
		quit(1)
		return
	demo.floor_choice.select(demo.layout.index_of("street"))
	demo._refresh()
	if demo.art.upper_nodes[0].visible:
		printerr("Cutaway did not hide upper deck")
		quit(1)
		return
	demo._auto_route()
	if demo.controller.state.active().surface_id!="upper":
		printerr("Bot did not route onto upper deck")
		quit(1)
		return
	print("Layered demo smoke passed")
	quit(0)
