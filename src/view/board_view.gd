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
	var box := BoxMesh.new()
	var h := piece.kind.height
	box.size = Vector3(piece.rect.size.x, h, piece.rect.size.y)
	mi.mesh = box
	var col: Color = COLORS.get(piece.kind.id, Color(0.6, 0.6, 0.6))
	mi.material_override = _mat(col, 0.95)
	mi.position = TableSpace.to_world(piece.rect.get_center(), h * 0.5)
	return mi


static func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m
