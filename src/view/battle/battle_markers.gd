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


func show_world_plan(path: PackedVector3Array,risky: bool=false) -> void:
	clear_move_plan()
	if path.is_empty():
		return
	_plan=Node3D.new()
	add_child(_plan)
	var gold := Color("f0a275") if risky else Color("f6d487")
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
	var shape:=ImmediateMesh.new()
	var ribbon:=StandardMaterial3D.new()
	ribbon.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ribbon.vertex_color_use_as_albedo=true
	ribbon.cull_mode=BaseMaterial3D.CULL_DISABLED
	var segments:=0
	for i in range(1,path.size()):
		var a:=path[i-1]+Vector3.UP*0.12
		var b:=path[i]+Vector3.UP*0.12
		var delta:=b-a
		# A linked edge can jump across the board: do not draw a false route.
		if delta.length()<0.001 or Vector2(delta.x,delta.z).length()>1.5:
			continue
		var color:=gold
		if delta.y>0.03:
			color=Color("8bd7f5")
		elif delta.y<-0.03:
			color=Color("f6a47d")
		var across:=Vector3(-delta.z,0,delta.x).normalized()*0.055
		if across.length_squared()<0.00001:
			across=Vector3.RIGHT*0.055
		if segments==0:
			shape.surface_begin(Mesh.PRIMITIVE_TRIANGLES,ribbon)
		for vertex in [a-across,a+across,b+across,a-across,b+across,b-across]:
			shape.surface_set_color(color)
			shape.surface_add_vertex(vertex)
		segments+=1
	if segments>0:
		shape.surface_end()
		var line:=MeshInstance3D.new()
		line.mesh=shape
		line.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_plan.add_child(line)
	var rise:=path[-1].y-path[0].y
	if absf(rise)>=0.5:
		var height_label:=Label3D.new()
		height_label.text="%+.1f″"%rise
		height_label.font_size=42
		height_label.pixel_size=0.008
		height_label.outline_size=8
		height_label.modulate=Color("8bd7f5") if rise>0 else Color("f6a47d")
		height_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		height_label.position=path[-1]+Vector3.UP*1.05
		_plan.add_child(height_label)
