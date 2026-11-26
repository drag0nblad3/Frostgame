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
	for piece in board.pieces:
		add_child(_piece(piece))


func _piece(piece: TerrainPiece) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var h := piece.kind.height
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
