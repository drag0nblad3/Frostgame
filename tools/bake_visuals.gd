extends SceneTree
## Bake deterministic scene resources before export, never during player startup.
## Run with a real renderer (Xvfb + GL on CI) so primitive mesh arrays exist.
var _written := {}
var _bytes := 0
var _failure := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var started := Time.get_ticks_msec()
	var sample := OS.get_cmdline_user_args().has("smoke")
	var packs: Array[String]=[]
	for id: String in ContentProfile.registered():
		if ContentProfile.playable(ContentProfile.registered()[id]):
			packs.append(id)
	var profile := ContentProfile.new(packs)
	var db := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,profile)
	var terrain := TerrainDb.load_file()
	var entries := ScenarioBriefing.available_entries(profile)
	for quality in ([1] if sample else [0,1,2]):
		# Override in this isolated build process; do not write the user's config.
		GraphicsQuality._mode=quality
		for id: String in entries:
			if sample and id!="treasure_skirmish":
				continue
			var state := ScenarioLoader.load_id(id,db,terrain)
			_bake_city(state.board,id,false)
			_bake_terrain(state.board,id)
			# All standard scenario deployments at Balanced; default roster at
			# the other settings. This avoids a huge cross-product of identities.
			if quality==1 or id=="treasure_skirmish":
				for f in state.figures:
					f.battle_ref=weakref(state)
					_bake_figure(f,_color(f))
					if sample:
						break
		if not sample:
			var title_board := BoardLoader.load_id("silent_tower",terrain)
			_bake_city(title_board,"silent_tower",true)
			_bake_terrain(title_board,"silent_tower")
			# Neutral creatures also occur as random encounters and summons.
			for id: String in db.figures:
				var def := db.get_def(id)
				if def.role=="creature":
					var f := Figure.new(0,def,-1,Vector2.ZERO,db.unarmed())
					_bake_figure(f,_color(f))
		if _failure:
			break
	if _failure or _written.is_empty():
		printerr("Visual bake failed")
		quit(1)
		return
	print("Visual bake: %d scenes, %.1f MiB, %d ms"%[_written.size(),float(_bytes)/1048576.0,Time.get_ticks_msec()-started])
	quit(0)


func _color(f: Figure) -> Color:
	return Color(0.65,0.45,0.75) if f.side<0 else FigureView.SIDE_COLORS[f.side%FigureView.SIDE_COLORS.size()]


func _bake_city(board: Board,id: String,cinematic: bool) -> void:
	var path := CityScenery.baked_path(board,id,cinematic)
	if not _written.has(path):
		var source:=CityScenery.build_procedural(board,id,cinematic)
		if not _outside_board(source,Transform3D.IDENTITY,Rect2(Vector2.ZERO,board.size)):
			printerr("Exterior art intersects playable rectangle: ",id)
			source.free()
			_failure=true
			return
		_save(path,source)


func _bake_terrain(board: Board,scenario: String) -> void:
	var path := BakedTerrain.path_for(board,scenario)
	if _written.has(path) or _failure:
		return
	var source := Node3D.new()
	source.name="BakedTerrain"
	var view := BoardView.new()
	view.scenario_id=scenario
	var floor := StoneFinish.floor_surface(board,scenario)
	floor.name="Floor"
	source.add_child(floor)
	var ground:=DistrictGround.build(board,floor.material_override,scenario)
	ground.name="Ground"
	source.add_child(ground)
	for i in board.pieces.size():
		var piece := board.pieces[i]
		if not BakedTerrain.supports(piece):
			continue
		var node := Node3D.new()
		node.name="Piece%d"%i
		view._build_piece(node,board,piece)
		source.add_child(node)
	var decoration := EnvironmentDressing.build(board,scenario)
	decoration.name="Decoration"
	source.add_child(decoration)
	view.free()
	_save(path,source)
	if not _failure:
		_verify_terrain(board,scenario)


func _verify_terrain(board: Board,scenario: String) -> void:
	var view := BoardView.new()
	view.scenario_id=scenario
	view.build(board)
	var valid := view._floor.has_meta("baked_visual") and view._ground.has_meta("baked_visual") and view._decoration.has_meta("baked_visual")
	for piece in board.pieces:
		if BakedTerrain.supports(piece):
			valid=valid and view._pieces[piece]["node"].has_meta("baked_visual")
	if not valid:
		printerr("Visual bake terrain runtime fallback unexpected: ",scenario)
		_failure=true
	view.free()


func _bake_figure(f: Figure,color: Color) -> void:
	if RedKingTethers.pylon(f):
		return
	var path := MiniatureFactory.baked_path(f,color)
	if not _written.has(path):
		_save(path,MiniatureFactory.create_procedural(f,color))


func _own_children(node: Node,owner_root: Node) -> void:
	for child in node.get_children():
		child.owner=owner_root
		_own_children(child,owner_root)


func _mesh_count(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D and node.mesh!=null:
		if node.mesh.get_surface_count()>0 and node.mesh.get_aabb().size.length_squared()>0.0:
			count+=1
	for child in node.get_children():
		count+=_mesh_count(child)
	return count


func _save(path: String,source: Node3D) -> void:
	if _failure:
		source.free()
		return
	var began := Time.get_ticks_usec()
	var expected := _mesh_count(source)
	if str(source.name).is_empty():
		source.name="BakedModel"
	_own_children(source,source)
	var scene := PackedScene.new()
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if error==OK:
		error=scene.pack(source)
	if error==OK:
		error=ResourceSaver.save(scene,path,ResourceSaver.FLAG_COMPRESS)
	if expected==0 or error!=OK:
		printerr("Visual bake cannot save ",path," meshes=",expected," error=",error)
		_failure=true
	else:
		# Use the same loader as the game; ensure the packed resource retains
		# mesh geometry, articulated node paths, and root transform.
		var loaded := BakedVisuals.load_scene(path)
		if loaded==null or _mesh_count(loaded)!=expected or not loaded.transform.is_equal_approx(source.transform):
			printerr("Visual bake round trip failed: ",path)
			_failure=true
		elif source.has_node("RightArm") and not loaded.has_node("RightArm"):
			printerr("Visual bake lost animation pivot: ",path)
			_failure=true
		else:
			_written[path]=true
			var file := FileAccess.open(path,FileAccess.READ)
			if file!=null:
				_bytes+=file.get_length()
			print("Baked ",path.get_file()," · ",expected," meshes · ",float(Time.get_ticks_usec()-began)/1000.0," ms")
		if loaded!=null:
			loaded.free()
	source.free()


## Check real baked mesh bounds, including nested landmark transforms,
## with a renderer available. No scenic geometry may enter the board.
func _outside_board(node: Node3D,parent: Transform3D,rect: Rect2) -> bool:
	var world:=parent*node.transform
	if node is MeshInstance3D and node.mesh!=null:
		var mesh_node:=node as MeshInstance3D
		var bounds: AABB=world*mesh_node.mesh.get_aabb()
		var footprint:=Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z))
		if footprint.intersects(rect):
			printerr("Exterior overlap at ",node.name,": ",footprint)
			return false
	for child in node.get_children():
		if child is Node3D and not _outside_board(child,world,rect):
			return false
	return true
