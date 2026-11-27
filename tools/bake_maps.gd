extends SceneTree
## Run with a real rendering backend (e.g. software GL under Xvfb). The dummy
## headless renderer is not a reliable source for serialized mesh buffers.
var _verify := false
var _failed := false
var _count := 0
var _bytes := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_verify=OS.get_cmdline_user_args().has("--verify")
	if not _verify:
		var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BakedMapAssets.DIR))
		if err!=OK:
			printerr("Cannot create baked assets directory: ",err)
			quit(1)
			return
	var terrain := TerrainDb.load_file()
	var ids: Array=ScenarioBriefing.all_entries().keys()
	ids.append("training_yard")
	for quality in 3:
		# Do not write or read player graphics preferences during development baking.
		GraphicsQuality._mode=quality
		for id: String in ids:
			var data: Dictionary=JsonFile.read(ScenarioLoader.DIR+id+".json")
			if not data.has("board"):
				_error("Missing scenario board: "+id)
				continue
			var board := BoardLoader.load_id(str(data["board"]),terrain)
			if id=="dreams_well":
				for p in board.pieces:
					if p.kind.id=="dreams_well":
						p.circular=true
			_city(board,id,false)
			_terrain(board,id)
		var title := BoardLoader.load_id("silent_tower",terrain)
		_city(title,"silent_tower",true)
	print("Baked map assets: %d scenes, %.2f MiB (%s)"%[_count,float(_bytes)/1048576.0,"verified" if _verify else "generated"])
	quit(1 if _failed else 0)


func _city(board: Board,id: String,cinematic: bool) -> void:
	var path := BakedMapAssets.city_path(board,id,cinematic)
	if _verify:
		var city := _load(path)
		if city!=null:
			var indoor := id in ["underground_library","training_yard"]
			if not indoor and (city.get_child_count()!=4 or _mesh_count(city)==0):
				_error("Empty or incomplete city: "+path)
			city.free()
		return
	_save(CityScenery.build(board,id,cinematic),path)


func _terrain(board: Board,id: String) -> void:
	var path := BakedMapAssets.terrain_path(board,id)
	if _verify:
		var scene := _load(path)
		if scene==null:
			return
		var floor_node := scene.get_node_or_null("Floor") as MeshInstance3D
		if floor_node==null or floor_node.mesh==null or not scene.has_node("Ground") or not scene.has_node("Dressing") or not scene.has_node("Pieces"):
			_error("Incomplete terrain bundle: "+path)
		for i in board.pieces.size():
			if BakedMapAssets.static_piece(board.pieces[i]):
				var piece := scene.get_node_or_null("Pieces/Piece_%d"%i)
				if piece==null or _mesh_count(piece)==0:
					_error("Missing terrain piece %d: %s"%[i,path])
		scene.free()
		return
	var bundle := Node3D.new()
	bundle.name="BakedTerrain"
	var floor_node := StoneFinish.floor_surface(board,id)
	floor_node.name="Floor"
	bundle.add_child(floor_node)
	var ground := DistrictGround.build(board,floor_node.material_override)
	ground.name="Ground"
	bundle.add_child(ground)
	var dressing := EnvironmentDressing.build(board,id)
	dressing.name="Dressing"
	bundle.add_child(dressing)
	var pieces := Node3D.new()
	pieces.name="Pieces"
	bundle.add_child(pieces)
	var builder := BoardView.new()
	builder.scenario_id=id
	for i in board.pieces.size():
		var p := board.pieces[i]
		if not BakedMapAssets.static_piece(p):
			continue
		var node := Node3D.new()
		node.name="Piece_%d"%i
		builder._build_piece(node,board,p)
		pieces.add_child(node)
	builder.free()
	_save(bundle,path)


func _save(node: Node3D,path: String) -> void:
	node.set_meta("baked_map",true)
	_own_children(node,node)
	var scene := PackedScene.new()
	var err := scene.pack(node)
	if err==OK:
		err=ResourceSaver.save(scene,path,ResourceSaver.FLAG_COMPRESS)
	if err!=OK:
		_error("Cannot save %s: %d"%[path,err])
	else:
		_record(path)
	node.free()


func _own_children(node: Node,owner_node: Node) -> void:
	for child in node.get_children():
		child.owner=owner_node
		_own_children(child,owner_node)


func _load(path: String) -> Node3D:
	var node := BakedMapAssets.instance(path)
	if node==null or not node.has_meta("baked_map"):
		_error("Cannot instantiate baked scene: "+path)
		if node!=null:
			node.free()
		return null
	_record(path)
	return node


func _mesh_count(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D and node.mesh!=null and node.mesh.get_aabb().size.length_squared()>0.000001:
		count=1
	elif node is MultiMeshInstance3D and node.multimesh!=null and node.multimesh.instance_count>0:
		count=1
	for child in node.get_children():
		count+=_mesh_count(child)
	return count


func _record(path: String) -> void:
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()==0:
		_error("Missing or empty file: "+path)
		return
	_bytes+=file.get_length()
	_count+=1


func _error(reason: String) -> void:
	_failed=true
	printerr(reason)
