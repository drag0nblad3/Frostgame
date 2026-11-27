class_name LayeredGatehouseArt
extends Node3D
## Visualize the authored volumes and floor surfaces without modifying rules.
var upper_nodes: Array[Node3D] = []


func build(layout: FloorLayout,include_ground: bool=true,scenario: String="") -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	upper_nodes.clear()
	for s in layout.surfaces:
		if s.id.begins_with("bridge:"):
			_bridge(s)
		elif s.id=="stairs" or s.id.begins_with("stair_") and not is_equal_approx(s.level,s.end_level):
			_stairs(s)
		elif s.id=="street" and include_ground:
			var ground := _box(Vector3(s.rect.get_center().x,-0.16,s.rect.get_center().y),Vector3(s.rect.size.x,0.3,s.rect.size.y),Color(0.63,0.74,0.81),false)
			var mat := StoneFinish.material(Color(0.48,0.59,0.66),true)
			mat.set_shader_parameter("footprint_size",s.rect.size)
			mat.set_shader_parameter("city_paving",true)
			mat.set_shader_parameter("snow_amount",0.8)
			ground.material_override=mat
		elif s.id=="landing" or s.id.ends_with("_landing"):
			_box(Vector3(s.rect.get_center().x,s.level-0.09,s.rect.get_center().y),Vector3(s.rect.size.x,0.18,s.rect.size.y),Color(0.51,0.60,0.67),true)
	for solid in layout.solids:
		var roof := solid.position.y>=2.5
		var color := Color(0.43,0.54,0.62) if roof else Color(0.35,0.43,0.49)
		var slab := _box(solid.get_center(),solid.size,color,roof)
		var stone:=StoneFinish.material(color,false,solid.size.y>2.0,Vector2(solid.position.x,solid.position.z))
		stone.set_shader_parameter("footprint_size",Vector2(solid.size.x,solid.size.z))
		stone.set_shader_parameter("building_height",solid.end.y)
		stone.set_shader_parameter("walkable_roof",solid.size.y<=0.5)
		slab.material_override=stone
		if solid.size.y<=0.5:
			_deck_edge(solid)
		elif solid.size.y>=1.7:
			var relief:=Node3D.new()
			add_child(relief)
			relief.position.y=solid.position.y
			relief.set_meta("cut_height",solid.get_center().y)
			BattlefieldDetail.wall_relief(relief,Rect2(solid.position.x,solid.position.z,solid.size.x,solid.size.z),solid.size.y,scenario)
			if roof:
				upper_nodes.append(relief)
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
	var w := (s.rect.size.y if s.axis_y else s.rect.size.x)/float(count)
	for i in count:
		var at:=s.rect.get_center()
		if s.axis_y:
			at.y=s.rect.position.y+w*(i+0.5)
		else:
			at.x=s.rect.position.x+w*(i+0.5)
		var h:=s.height_at(at)
		_box(Vector3(at.x,h-0.08,at.y),Vector3(s.rect.size.x,0.16,w+0.012) if s.axis_y else Vector3(w+0.012,0.16,s.rect.size.y),Color(0.55,0.65,0.72),h>=2.5 and s.id!="stairs")


func _deck_edge(solid: AABB) -> void:
	# Inlaid perimeter stones, flush with the deck; no collision changes.
	var y := solid.end.y-0.015
	var center := solid.get_center()
	var color := Color(0.74,0.82,0.86)
	for z: float in [solid.position.z+0.09,solid.end.z-0.09]:
		_box(Vector3(center.x,y,z),Vector3(solid.size.x,0.03,0.18),color,true)
	for x: float in [solid.position.x+0.09,solid.end.x-0.09]:
		_box(Vector3(x,y,center.z),Vector3(0.18,0.03,solid.size.z),color,true)


func _box(at: Vector3,size: Vector3,color: Color,upper: bool) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size=size
	node.mesh=mesh
	node.material_override=BoardView._mat(color,0.92)
	node.position=at
	add_child(node)
	if upper:
		upper_nodes.append(node)
	return node


func cut_at(height: float) -> void:
	for child in get_children():
		if child is Node3D:
			child.visible=float(child.get_meta("cut_height",child.position.y))<=height+0.1


func show_upper(on: bool) -> void:
	for n in upper_nodes:
		n.visible=on
