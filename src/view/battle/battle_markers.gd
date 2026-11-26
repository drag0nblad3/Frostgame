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
	var shape: PrimitiveMesh
	if radius >= 0.4:
		# Open target rings keep the actual miniature or treasure unobscured.
		var ring := TorusMesh.new()
		ring.inner_radius = radius * 0.84
		ring.outer_radius = radius
		ring.rings = 20
		ring.ring_segments = 6
		shape = ring
	else:
		# Small flat diamonds differentiate legal destinations from targets.
		var diamond := CylinderMesh.new()
		diamond.top_radius = radius * 0.81
		diamond.bottom_radius = radius * 0.81
		diamond.height = 0.018
		diamond.radial_segments = 4
		shape = diamond
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.25
	shape.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = shape
	mm.instance_count = points.size()
	for i in points.size():
		var basis := Basis.IDENTITY.scaled(Vector3(1, 0.18, 1)) if radius >= 0.4 else Basis(Vector3.UP, PI * 0.25)
		mm.set_instance_transform(i, Transform3D(basis, TableSpace.to_world(points[i], 0.065 + (board.height_at(points[i]) if board != null else 0.0))))
	marker.multimesh = mm
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(marker)
	_layers.append(marker)
