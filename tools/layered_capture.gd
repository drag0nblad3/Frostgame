extends SceneTree
var scene: Node3D
var frames := 0
var captured := false
var tower := false


func _initialize() -> void:
	call_deferred("_setup")


func _setup() -> void:
	tower=OS.get_cmdline_user_args().has("tower")
	if tower:
		root.set_meta("layered_board","layered_silent_tower")
	change_scene_to_file("res://scenes/layered_skirmish.tscn")
	await scene_changed
	scene=current_scene


func _process(_delta: float) -> bool:
	if scene==null:
		return false
	frames+=1
	if frames==45:
		var image := root.get_texture().get_image()
		if image==null or image.save_png("previews/tower-upper.png" if tower else "previews/gatehouse-upper.png")!=OK:
			quit(1)
			return true
		scene._select_floor("street")
		captured=true
	if frames==80 and captured:
		var image := root.get_texture().get_image()
		if image==null or image.save_png("previews/tower-cutaway.png" if tower else "previews/gatehouse-cutaway.png")!=OK:
			quit(1)
			return true
		print("Gatehouse captures complete")
		quit(0)
		return true
	return false
