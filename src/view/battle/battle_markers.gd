class_name BattleMarkers
extends Node3D
## Instanced tabletop markers: legal movement positions or selectable targets.

var _layers: Array[MultiMeshInstance3D] = []
var board: Board
var _plan: Node3D


func clear() -> void:
	clear_move_plan()
	for layer in _layers:
		layer.visible = false
		layer.queue_free()
	_layers.clear()


func show_points(points: Array[Vector2], color: Color, radius: float, append: bool = false) -> void:
	var world:=PackedVector3Array()
	for p in points:
		world.append(TableSpace.to_world(p,board.height_at(p) if board!=null else 0.0))
	show_world_points(world,color,radius,append)


func show_world_points(points: PackedVector3Array,color: Color,radius: float,append: bool=false) -> void:
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
		mm.set_instance_transform(i, Transform3D(basis, points[i]+Vector3.UP*0.065))
	marker.multimesh = mm
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(marker)
	_layers.append(marker)


## Keep the expensive reachable-area multimesh intact while the finger moves.
func clear_move_plan() -> void:
	if is_instance_valid(_plan):
		remove_child(_plan)
		_plan.queue_free()
	_plan=null


func show_move_plan(path: PackedVector2Array) -> void:
	var world:=PackedVector3Array()
	for p in path:
		world.append(TableSpace.to_world(p,board.height_at(p)))
	show_world_plan(world)


func show_world_plan(path: PackedVector3Array) -> void:
	clear_move_plan()
	if path.is_empty():
		return
	_plan=Node3D.new()
	add_child(_plan)
	var gold := Color("f6d487")
	var mat := StandardMaterial3D.new()
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=gold
	var ring := TorusMesh.new()
	ring.inner_radius=0.52
	ring.outer_radius=0.66
	ring.rings=24
	ring.ring_segments=6
	var end := MeshInstance3D.new()
	end.mesh=ring
	end.material_override=mat
	end.position=path[-1]+Vector3.UP*0.10
	end.scale.y=0.28
	end.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_plan.add_child(end)
	if path.size()<2:
		return
	var vertices := PackedVector3Array()
	for i in range(1,path.size()):
		# A linked edge can jump across the board: do not draw a false route.
		var length := path[i-1].distance_to(path[i])
		if length<0.001 or Vector2(path[i].x-path[i-1].x,path[i].z-path[i-1].z).length()>1.5:
			continue
		for p in [path[i-1],path[i]]:
			vertices.append(p+Vector3.UP*0.12)
	if vertices.is_empty():
		return
	var shape := ImmediateMesh.new()
	shape.surface_begin(Mesh.PRIMITIVE_LINES,mat)
	for vertex in vertices:
		shape.surface_add_vertex(vertex)
	shape.surface_end()
	var line := MeshInstance3D.new()
	line.mesh=shape
	line.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_plan.add_child(line)
