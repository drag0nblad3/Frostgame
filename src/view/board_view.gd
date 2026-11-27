class_name BoardView
extends Node3D
## Draws a frozen city district around the unchanged logical battlefield.

const COLORS := {
	"ruin": Color(0.42, 0.44, 0.5),
	"wall": Color(0.34, 0.36, 0.4),
	"rubble": Color(0.42, 0.39, 0.36),
}


var scenario_id := ""
var cinematic := false
var _scenery: Node3D
var _board_size := Vector2.ZERO
var _board: Board
var _pieces := {}
var _decoration: Node3D
var _ground: Node3D
var _floor: MeshInstance3D
var _boundary_view: Node3D
var _boundary_key := ""
var _ground_key := ""
var _decoration_key := ""
var _camera_at := Vector3(INF,INF,INF)
var _city_key := ""
var _city_next := 4
var _city_board: Board
var _city_scenario := ""
var _city_started := 0


func _process(_delta: float) -> void:
	if not is_instance_valid(_scenery):
		return
	if _city_next<4:
		var district_started := Time.get_ticks_usec()
		_scenery.add_child(CityScenery.build_district(_city_board,_city_scenario,false,_city_next))
		_city_next+=1
		_camera_at=Vector3(INF,INF,INF)
		print("Map load: district %d %.1f ms"%[_city_next,float(Time.get_ticks_usec()-district_started)/1000.0])
		if _city_next==4:
			_city_board=null
			print("Map load: outskirts ready after %.1f ms"%[float(Time.get_ticks_usec()-_city_started)/1000.0])
	var camera := get_viewport().get_camera_3d()
	if camera!=null and camera.global_position!=_camera_at:
		_camera_at=camera.global_position
		CityScenery.update_foreground(_scenery,_camera_at,_board_size)


func build(board: Board) -> void:
	# New encounter only. Reuse static surroundings for identical scenarios.
	var scenario := board.id if scenario_id.is_empty() else scenario_id
	var city_key := str([board.size,scenario,cinematic,GraphicsQuality.mode()])
	var keep_city := is_instance_valid(_scenery) and city_key==_city_key
	for c in get_children():
		if keep_city and c==_scenery:
			continue
		remove_child(c)
		c.queue_free()
	_pieces.clear()
	_board=board
	_ground=null
	_boundary_view=null
	_boundary_key=""
	_floor=null
	_decoration=null
	_ground_key=""
	_decoration_key=""
	_camera_at=Vector3(INF,INF,INF)
	_board_size=board.size
	if not keep_city:
		_city_key=city_key
		_city_next=4
		_city_board=null
		_scenery=BakedMapAssets.instance(BakedMapAssets.city_path(board,scenario,cinematic))
		if _scenery!=null:
			print("Map load: pre-baked city ",scenario)
		elif cinematic or not is_inside_tree() or RealmScenery.special(scenario) or scenario in ["underground_library","training_yard"]:
			_scenery=CityScenery.build(board,scenario,cinematic)
		else:
			_scenery=Node3D.new()
			_scenery.name="CityScenery"
			# Snapshot only the size: the bot may be mutating the actual board.
			_city_board=Board.new()
			_city_board.size=board.size
			_city_scenario=scenario
			_city_next=0
			_city_started=Time.get_ticks_usec()
		add_child(_scenery)
	set_process(not cinematic)
	_install_baked_terrain(board,scenario)
	sync_terrain(board)


## Transfer independent nodes from the exact-match art bundle. Runtime terrain
## changes still use sync_terrain; animated hazards and spells are never baked.
func _install_baked_terrain(board: Board,scenario: String) -> void:
	var bundle := BakedMapAssets.instance(BakedMapAssets.terrain_path(board,scenario))
	if bundle==null:
		return
	var floor_node := BakedMapAssets.take(bundle,"Floor") as MeshInstance3D
	var ground_node := BakedMapAssets.take(bundle,"Ground")
	var decoration_node := BakedMapAssets.take(bundle,"Dressing")
	var pieces_node := bundle.get_node_or_null("Pieces")
	if floor_node==null or ground_node==null or decoration_node==null or pieces_node==null:
		for node in [floor_node,ground_node,decoration_node]:
			if is_instance_valid(node):
				node.free()
		bundle.free()
		return
	_floor=floor_node
	_ground=ground_node
	_decoration=decoration_node
	add_child(_ground)
	add_child(_floor)
	add_child(_decoration)
	var ground_parts: Array[String]=[]
	var static_parts: Array[String]=[]
	for i in board.pieces.size():
		var piece := board.pieces[i]
		var key := _piece_key(piece)
		if piece.kind.ground_surface:
			ground_parts.append(key)
		if piece.cast_turn<0 and not piece.kind.id.begins_with("spell_"):
			static_parts.append(key)
		if BakedMapAssets.static_piece(piece):
			var node := BakedMapAssets.take(pieces_node,"Piece_%d"%i)
			if node!=null:
				_pieces[piece]={"node":node,"key":key}
				add_child(node)
	_ground_key=str(ground_parts)
	_decoration_key=str(static_parts)
	bundle.free()
	print("Map load: pre-baked terrain ",scenario)


func scenery_ready() -> bool:
	return _city_next>=4


func sync_terrain(board: Board) -> void:
	if board!=_board:
		build(board)
		return
	var scenario := board.id if scenario_id.is_empty() else scenario_id
	var boundary_key := str(board.boundaries)+str(board.edge_links)+str(board.void_regions)
	if _boundary_view==null or _boundary_key!=boundary_key:
		_remove(_boundary_view)
		_boundary_view=BoundaryView.build(board)
		if not board.void_regions.is_empty():
			_boundary_view.add_child(VoidView.build(board))
		add_child(_boundary_view)
		_boundary_key=boundary_key
	var ground_parts: Array[String]=[]
	var static_parts: Array[String]=[]
	var live := {}
	for piece in board.pieces:
		var key := _piece_key(piece)
		if piece.kind.ground_surface:
			ground_parts.append(key)
		else:
			live[piece]=key
		if piece.cast_turn<0 and not piece.kind.id.begins_with("spell_"):
			static_parts.append(key)
	var ground_key := str(ground_parts)
	if _floor==null or _ground_key!=ground_key:
		_remove(_floor)
		_remove(_ground)
		_floor=StoneFinish.floor_surface(board,scenario)
		_ground=DistrictGround.build(board,_floor.material_override)
		add_child(_ground)
		add_child(_floor)
		_ground_key=ground_key
	for piece in _pieces.keys():
		if not live.has(piece) or _pieces[piece]["key"]!=live[piece]:
			_remove(_pieces[piece]["node"])
			_pieces.erase(piece)
	for piece in live:
		if not _pieces.has(piece):
			var root := Node3D.new()
			root.name="Terrain_"+piece.kind.id
			_build_piece(root,board,piece)
			_pieces[piece]={"node":root,"key":live[piece]}
			add_child(root)
	var deco_key := str(static_parts)
	if _decoration==null or _decoration_key!=deco_key:
		_remove(_decoration)
		_decoration=EnvironmentDressing.build(board,scenario)
		add_child(_decoration)
		_decoration_key=deco_key


func _remove(node: Node) -> void:
	if is_instance_valid(node):
		remove_child(node)
		node.queue_free()


static func _piece_key(p: TerrainPiece) -> String:
	return BakedMapAssets.piece_key(p)


func _build_piece(root: Node3D,board: Board,piece: TerrainPiece) -> void:
	match piece.kind.id:
		"rubble":
			TerrainDressing.rubble(root,piece)
		"museum_statue":
			TerrainDressing.statue(root,piece)
		"temple_column":
			TerrainDressing.column(root,piece)
		"red_king_portal","reality_portal":
			PortalView.build(root,piece)
		"red_king_sinkhole_orb":
			SinkholeView.build(root,piece)
		"reality_hoof":
			RealityHazardView.hoof(root,piece,board)
		"rk_worm_token":
			RealityHazardView.worm(root,piece,board)
		"library_shelf":
			SiteArt.shelf(root,piece)
		"arcane_disc","dreams_well":
			root.add_child(_piece(piece))
			TabletopDetails.decorate(root,piece)
			SiteArt.surface(root,piece,piece.kind.id=="dreams_well")
		_:
			root.add_child(_piece(piece))
			TabletopDetails.decorate(root,piece)
			if piece.kind.id in ["ruin","tower","wall","platform","hut_wall","null_annex","null_walk","null_lower","null_middle","null_upper"]:
				RuinSilhouette.decorate(root,piece)
				RuinedFacade.decorate(root,piece,scenario_id if not scenario_id.is_empty() else board.id)
			if board.id=="mausoleum" and piece.kind.id=="ruin" and piece.rect.has_point(board.size*0.5):
				SiteArt.crypt(root,piece)
	# Rubble is otherwise dozens of individual shadow-casting meshes.
	if piece.kind.id=="rubble":
		MiniatureBatch.bake(root)


func _piece(piece: TerrainPiece) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var h := piece.kind.height
	if piece.kind.id == "spell_wizard_eye":
		var orb := SphereMesh.new()
		orb.radius = 0.22
		orb.height = 0.44
		mi.mesh = orb
		var material := _mat(Color(0.4, 0.9, 1.0), 0.35)
		material.emission_enabled = true
		material.emission = Color(0.2, 0.6, 0.9)
		mi.material_override = material
		mi.position = TableSpace.to_world(piece.rect.get_center(), 1.5)
		return mi
	if piece.ramp:
		var box := BoxMesh.new()
		var run := piece.rect.size.y if piece.ramp_rotated else piece.rect.size.x
		var width := piece.rect.size.x if piece.ramp_rotated else piece.rect.size.y
		var slope := atan2(piece.ramp_end - piece.ramp_start, run)
		var length := Vector2(run, piece.ramp_end - piece.ramp_start).length()
		box.size = Vector3(width, 0.08, length) if piece.ramp_rotated else Vector3(length, 0.08, width)
		mi.mesh = box
		mi.rotation.x = -slope if piece.ramp_rotated else 0.0
		mi.rotation.z = 0.0 if piece.ramp_rotated else slope
		mi.position = TableSpace.to_world(piece.rect.get_center(), (piece.ramp_start + piece.ramp_end) * 0.5 - 0.04)
		var ramp_material := StoneFinish.material(Color("aa9975"))
		ramp_material.set_shader_parameter("snow_amount",0.20)
		ramp_material.set_shader_parameter("frost_detail",GraphicsQuality.mode()>0)
		mi.material_override=ramp_material
		return mi
	if piece.circular:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = piece.rect.size.x * 0.5
		cylinder.bottom_radius = cylinder.top_radius
		cylinder.height = h
		mi.mesh = cylinder
	elif piece.kind.id in ["ruin","wall"] and not piece.kind.walkable_top:
		mi.mesh = RuinedMesh.build(piece.rect.size,h,roundi(piece.rect.position.x*31.0+piece.rect.position.y*17.0))
	else:
		var box := BoxMesh.new()
		box.size = Vector3(piece.rect.size.x, h, piece.rect.size.y)
		mi.mesh = box
	var col: Color = COLORS.get(piece.kind.id, Color(0.6, 0.6, 0.6))
	match piece.kind.id:
		"spell_wall": col = Color(0.25, 0.7, 0.9)
		"spell_fog": col = Color(0.7, 0.85, 1.0, 0.4)
		"spell_mud": col = Color(0.3, 0.24, 0.15, 0.8)
		"spell_explosive_rune": col = Color(1.0, 0.35, 0.1)
		"spell_circle_of_protection": col = Color(0.9, 0.75, 0.25, 0.45)
		"museum_statue": col = Color(0.65, 0.71, 0.72)
		"dreams_well": col = Color(0.12, 0.38, 0.55)
		"library_shelf": col = Color(0.36, 0.24, 0.18)
		"arcane_disc": col = Color(0.24, 0.66, 0.76)
		"haunted_floor": col = Color(0.34, 0.39, 0.45)
		"hut_wall": col = Color(0.46, 0.48, 0.53)
		"null_annex", "null_walk", "null_lower", "null_middle", "null_upper": col = Color(0.26, 0.31, 0.38)
		"temple_column": col = Color(0.68, 0.62, 0.49)
	var mat := _mat(col, 0.95)
	if col.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if piece.kind.id in StoneFinish.STONE_KINDS:
		var stone := StoneFinish.material(col,false,piece.kind.id in ["ruin","tower","hut_wall","null_lower","null_middle","null_upper"],piece.rect.position)
		stone.set_shader_parameter("footprint_size",piece.rect.size)
		stone.set_shader_parameter("walkable_roof",piece.kind.walkable_top)
		stone.set_shader_parameter("facade_style",RuinedFacade.style(piece,scenario_id))
		stone.set_shader_parameter("building_height",h)
		stone.set_shader_parameter("frost_detail",GraphicsQuality.mode()>0)
		stone.set_shader_parameter("snow_amount",float(VisualPalette.for_scenario(scenario_id).get("snow",0.86)))
		mi.material_override = stone
	else:
		mi.material_override = mat
	mi.position = TableSpace.to_world(piece.rect.get_center(), h * 0.5)
	return mi


static var _shared_mats := {}


## A cached material for nodes that never change it. Use _mat() to get one to edit.
static func shared_mat(c: Color, rough: float) -> StandardMaterial3D:
	var key := Vector4(c.r, c.g, c.b, c.a * 10.0 + rough)
	if not _shared_mats.has(key):
		_shared_mats[key] = _mat(c, rough)
	return _shared_mats[key]


static func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m
