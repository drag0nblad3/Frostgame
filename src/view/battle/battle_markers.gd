class_name BattleMarkers
extends Node3D
## Instanced tabletop markers: legal movement positions or selectable targets.

var _markers: MultiMeshInstance3D


func clear() -> void:
	if _markers != null:
		_markers.queue_free()
		_markers = null


func show_points(points: Array[Vector2], color: Color, radius: float) -> void:
	clear()
	if points.is_empty():
		return
	_markers = MultiMeshInstance3D.new()
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
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, TableSpace.to_world(points[i], 0.035)))
	_markers.multimesh = mm
	add_child(_markers)
