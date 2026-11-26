class_name BattleMarkers
extends Node3D
## Instanced tabletop markers: legal movement positions or selectable targets.

var _layers: Array[MultiMeshInstance3D] = []
var board: Board


func clear() -> void:
	for layer in _layers:
		layer.visible = false
		layer.queue_free()
	_layers.clear()


func show_points(points: Array[Vector2], color: Color, radius: float, append: bool = false) -> void:
	if not append:
		clear()
	if points.is_empty():
		return
	var marker := MultiMeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = radius
	disk.bottom_radius = radius
	disk.height = 0.025
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	disk.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = disk
	mm.instance_count = points.size()
	for i in points.size():
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, TableSpace.to_world(points[i], 0.035 + (board.height_at(points[i]) if board != null else 0.0))))
	marker.multimesh = mm
	add_child(marker)
	_layers.append(marker)
