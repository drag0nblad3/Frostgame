extends SceneTree
## A renderable miniature lineup. No gameplay state is changed.
var _frames := 0
var _scene: Node3D
var _ready_to_capture := false


func _initialize() -> void:
	call_deferred("_setup")


func _setup() -> void:
	_scene = Node3D.new()
	root.add_child(_scene)
	var db := FigureDb.load_files()
	var ids := ["wizard", "apprentice", "knight", "templar", "ranger", "archer", "apothecary", "barbarian", "skeleton", "armoured_skeleton", "wraith", "genie", "ice_spider", "ice_toad", "white_gorilla", "werewolf", "snow_troll", "frost_giant", "wolf", "boar", "bear", "snow_leopard", "giant_rat", "large_construct"]
	var args := OS.get_cmdline_user_args()
	var school_gallery := args.size() > 1 and args[1] in ["schools","apprentices"]
	var schools: Array = SchoolArt.PALETTES.keys()
	var soldier_gallery := args.size()>1 and args[1]=="soldiers"
	var beast_gallery := args.size()>1 and args[1]=="beasts"
	if school_gallery:
		ids.clear()
		for school in schools:
			ids.append("apprentice" if args[1]=="apprentices" else "wizard")
	if args.size() > 1 and args[1] == "bestiary":
		ids = ["imp", "minor_demon", "major_demon", "small_construct", "medium_construct", "large_construct", "ghoul", "zombie", "vampire", "animated_skull", "giant_worm", "skeleton_archer", "thug", "thief", "crossbowman", "infantryman", "man_at_arms", "marksman", "treasure_hunter", "tracker", "war_hound", "wild_dog"]
	if soldier_gallery:
		ids=["thug","thief","archer","crossbowman","infantryman","man_at_arms","treasure_hunter","knight","barbarian","ranger","marksman","tracker","templar","apothecary","war_hound"]
	if beast_gallery:
		ids=["wolf","bear","boar","snow_leopard","giant_rat","wild_dog","war_hound","small_construct","medium_construct","large_construct"]
	var supernatural_gallery := args.size()>1 and args[1]=="supernatural"
	if supernatural_gallery:
		ids=["skeleton","armoured_skeleton","skeleton_archer","ghoul","zombie","animated_skull","wraith","genie","imp","minor_demon","major_demon","white_gorilla","werewolf","snow_troll","frost_giant","ice_spider","ice_toad","giant_worm","vampire"]
	var close_gallery := school_gallery or soldier_gallery or beast_gallery or supernatural_gallery
	for i in ids.size():
		var def := db.get_def(ids[i])
		var columns := 5 if close_gallery else 6
		var at := Vector2(2.0 + i % columns * (2.5 if close_gallery else 2.2), 2.0 + floori(float(i) / columns) * (3.5 if close_gallery else 3.1))
		var side := (i%2 if args[1]=="schools" else (i+1)%2) if school_gallery else (0 if def.role!="creature" else -1)
		if soldier_gallery:
			side=i%2
		var f := Figure.new(i + 1, def, side, at, db.unarmed())
		if school_gallery and args[1]=="apprentices":
			f.campaign_id=i+101
		var v := FigureView.new()
		_scene.add_child(v)
		var state: GameState
		if school_gallery:
			state = GameState.new()
			state.side_schools[f.original_side] = schools[i]
			f.battle_ref = weakref(state)
		v.setup(f, "Gallery")
		if school_gallery:
			v._plate.text = str(schools[i]).capitalize() + "\n" + f.def.name
		v.face_toward(Vector3(6, 0, -12))
	var base := BoxMesh.new()
	base.size = Vector3(15, 0.25, 14)
	MiniatureFactory.mesh(_scene, base, Vector3(7, -0.14, 7), Color(0.58, 0.65, 0.73))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	_scene.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-38, 145, 0)
	fill.light_energy = 0.6
	_scene.add_child(fill)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 15.0
	_scene.add_child(camera)
	camera.position = Vector3(7, 18, -14)
	camera.look_at(Vector3(7, 0, 6), Vector3.UP)
	if close_gallery:
		camera.size=15.4 if supernatural_gallery else (12.1 if soldier_gallery else 9.2)
		camera.position=Vector3(7,11,-12)
		camera.look_at(Vector3(7,0.8,7.25 if supernatural_gallery else (5.5 if soldier_gallery else 3.75)),Vector3.UP)
	camera.make_current()
	_ready_to_capture = true


func _process(_delta: float) -> bool:
	if not _ready_to_capture:
		return false
	_frames += 1
	if _frames < 40:
		return false
	var args := OS.get_cmdline_user_args()
	var out := args[0] if not args.is_empty() else "/tmp/miniatures.png"
	var img := root.get_texture().get_image()
	if img == null or img.save_png(out) != OK:
		quit(1)
		return true
	print("Gallery captured: ", out)
	return true
