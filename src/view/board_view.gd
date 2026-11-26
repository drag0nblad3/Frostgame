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


func build(board: Board) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var top := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(board.size.x, 0.5, board.size.y)
	top.mesh = slab
	top.material_override = _mat(Color(0.74, 0.79, 0.86), 0.9)
	top.position = TableSpace.to_world(board.size * 0.5, GroundMesh.bottom(board)-0.25)
	add_child(top)
	add_child(StoneFinish.floor_surface(board, scenario_id))
	TerrainDressing.slab_frame(self, board)
	add_child(CityScenery.build(board,board.id if scenario_id.is_empty() else scenario_id,cinematic))
	for piece in board.pieces:
		if piece.kind.ground_surface:
			continue
		match piece.kind.id:
			"rubble":
				TerrainDressing.rubble(self, piece)
			"museum_statue":
				TerrainDressing.statue(self, piece)
			"temple_column":
				TerrainDressing.column(self, piece)
			"library_shelf":
				SiteArt.shelf(self, piece)
			"arcane_disc", "dreams_well":
				add_child(_piece(piece))
				TabletopDetails.decorate(self, piece)
				SiteArt.surface(self, piece, piece.kind.id == "dreams_well")
			_:
				add_child(_piece(piece))
				TabletopDetails.decorate(self, piece)
				if piece.kind.id in ["ruin", "tower", "wall", "platform", "hut_wall", "null_annex", "null_walk", "null_lower", "null_middle", "null_upper"]:
					RuinSilhouette.decorate(self, piece)
				if board.id == "mausoleum" and piece.kind.id == "ruin" and piece.rect.has_point(board.size * 0.5):
					SiteArt.crypt(self, piece)
	add_child(EnvironmentDressing.build(board,board.id if scenario_id.is_empty() else scenario_id))


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
		mi.material_override = _mat(Color(0.87, 0.72, 0.38), 0.8)
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
		stone.set_shader_parameter("building_height",h)
		mi.material_override = stone
	else:
		mi.material_override = mat
	mi.position = TableSpace.to_world(piece.rect.get_center(), h * 0.5)
	return mi


static func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m
