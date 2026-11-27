class_name BattleMarkers
extends Node3D
## Instanced tabletop markers: legal movement positions or selectable targets.

var _layers: Array[MultiMeshInstance3D] = []
var board: Board
var _planned: Node3D


func clear() -> void:
	clear_move_path()
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


## A separate lightweight overlay: dragging never rebuilds the reachable area.
func clear_move_path() -> void:
	if is_instance_valid(_planned):
		remove_child(_planned)
		_planned.queue_free()
	_planned=null


func show_move_path(path: PackedVector2Array) -> void:
	clear_move_path()
	if path.size()<2 or board==null:
		return
	_planned=Node3D.new()
	add_child(_planned)
	var tint := Color("f3ce80")
	var material := StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=tint
	var route := ImmediateMesh.new()
	route.surface_begin(Mesh.PRIMITIVE_LINE_STRIP,material)
	for at in path:
		route.surface_add_vertex(TableSpace.to_world(at,board.height_at(at)+0.16))
	route.surface_end()
	var line := MeshInstance3D.new()
	line.mesh=route
	line.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_planned.add_child(line)
	for i in [0,path.size()-1]:
		var ring := TorusMesh.new()
		ring.inner_radius=0.52
		ring.outer_radius=0.65
		ring.rings=20
		ring.ring_segments=6
		var node := MeshInstance3D.new()
		node.mesh=ring
		node.material_override=material
		node.scale.y=0.22
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.position=TableSpace.to_world(path[i],board.height_at(path[i])+0.10)
		_planned.add_child(node)
