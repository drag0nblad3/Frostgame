class_name BoardView
extends Node3D
## Draws the table and its terrain pieces as simple blocks.

const COLORS := {
	"ruin": Color(0.42, 0.44, 0.5),
	"wall": Color(0.34, 0.36, 0.4),
	"rubble": Color(0.42, 0.39, 0.36),
}


func build(board: Board) -> void:
	for c in get_children():
		c.queue_free()
	var top := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(board.size.x, 0.5, board.size.y)
	top.mesh = slab
	top.material_override = _mat(Color(0.74, 0.79, 0.86), 0.9)
	top.position = TableSpace.to_world(board.size * 0.5, -0.25)
	add_child(top)
	add_child(TabletopDetails.ground(board))
	for piece in board.pieces:
		add_child(_piece(piece))
		TabletopDetails.decorate(self, piece)


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
		var slope := atan2(piece.ramp_end - piece.ramp_start, 6.0)
		var length := Vector2(6.0, piece.ramp_end - piece.ramp_start).length()
		box.size = Vector3(2.0, 0.08, length) if piece.ramp_rotated else Vector3(length, 0.08, 2.0)
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
	var mat := _mat(col, 0.95)
	if col.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.position = TableSpace.to_world(piece.rect.get_center(), h * 0.5)
	return mi


static func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m
