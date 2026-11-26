class_name LayeredGatehouseArt
extends Node3D
## Visualize the authored volumes and floor surfaces without modifying rules.
var upper_nodes: Array[Node3D] = []


func build(layout: FloorLayout) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	upper_nodes.clear()
	for s in layout.surfaces:
		if s.id.begins_with("bridge:"):
			_bridge(s)
		elif s.id=="stairs":
			_stairs(s)
		elif s.id=="street":
			_box(Vector3(s.rect.get_center().x,-0.16,s.rect.get_center().y),Vector3(s.rect.size.x,0.3,s.rect.size.y),Color(0.63,0.74,0.81),false)
		elif s.id=="landing":
			_box(Vector3(s.rect.get_center().x,s.level-0.09,s.rect.get_center().y),Vector3(s.rect.size.x,0.18,s.rect.size.y),Color(0.51,0.60,0.67),true)
	for solid in layout.solids:
		var roof := solid.position.y>=2.5
		_box(solid.get_center(),solid.size,Color(0.43,0.54,0.62) if roof else Color(0.35,0.43,0.49),roof)
	# Wall volumes get narrow masonry courses (visual only).
	for solid in layout.solids:
		if solid.position.y>0.1:
			continue
		for i in range(1,5):
			var p := solid.get_center()
			p.y=solid.position.y+solid.size.y*float(i)/5.0
			_box(p,Vector3(solid.size.x+0.035,0.035,solid.size.z+0.035),Color(0.23,0.32,0.39),false)


func _bridge(s: FloorSurface) -> void:
	var a := Vector3(s.rect.get_center().x,s.level,s.rect.get_center().y)
	var b := Vector3(s.rect.get_center().x,s.end_level,s.rect.get_center().y)
	if s.axis_y:
		a.z=s.rect.position.y
		b.z=s.rect.end.y
	else:
		a.x=s.rect.position.x
		b.x=s.rect.end.x
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size=Vector3(2.0,0.065,a.distance_to(b))
	node.mesh=mesh
	var mat := BoardView._mat(Color(0.42,0.85,0.95),0.4)
	mat.emission_enabled=true
	mat.emission=Color(0.18,0.42,0.60)
	node.material_override=mat
	add_child(node)
	node.position=(a+b)*0.5-Vector3.UP*0.035
	node.look_at(b-Vector3.UP*0.035,Vector3.UP)
	upper_nodes.append(node)


func _stairs(s: FloorSurface) -> void:
	var count := 12
	var w := s.rect.size.x/float(count)
	for i in count:
		var x := s.rect.position.x+w*(i+0.5)
		var h := s.height_at(Vector2(x,s.rect.get_center().y))
		_box(Vector3(x,h-0.08,s.rect.get_center().y),Vector3(w+0.012,0.16,s.rect.size.y),Color(0.55,0.65,0.72),false)


func _box(at: Vector3,size: Vector3,color: Color,upper: bool) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size=size
	node.mesh=mesh
	node.material_override=BoardView._mat(color,0.92)
	node.position=at
	add_child(node)
	if upper:
		upper_nodes.append(node)


func show_upper(on: bool) -> void:
	for n in upper_nodes:
		n.visible=on
