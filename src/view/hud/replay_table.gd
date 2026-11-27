class_name ReplayTable
extends SubViewportContainer
## Lightweight historical table. Never attaches live figures or controllers.
var _viewport: SubViewport
var _root: Node3D
var _camera: Camera3D
var _frame: Dictionary={}
var _surface := ""
var _angle := 0
var _materials := {}


func _ready() -> void:
	custom_minimum_size=Vector2(140,140)
	stretch=true
	stretch_shrink=2
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	_viewport=SubViewport.new()
	_viewport.own_world_3d=true
	_viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	add_child(_viewport)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("16232e")
	_viewport.add_child(environment)
	_root=Node3D.new()
	_viewport.add_child(_root)
	_camera=Camera3D.new()
	_camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	_viewport.add_child(_camera)
	_camera.current=true
	resized.connect(_render)


func show_frame(frame: Dictionary,surface: String="") -> void:
	if _frame!=frame or _surface!=surface:
		_frame=frame
		_surface=surface
		_rebuild()
	_render()


func rotate_view() -> void:
	_angle=(_angle+1)%4
	_render()


func _render() -> void:
	if _viewport==null or _frame.is_empty() or not visible:
		return
	var board: Vector2=_frame["size"]
	var center:=Vector3(board.x*0.5,1.0,board.y*0.5)
	var direction:=Vector3(1.0,1.35,1.0).rotated(Vector3.UP,float(_angle)*PI*0.5)
	_camera.position=center+direction*maxf(board.x,board.y)*1.8
	_camera.look_at(center)
	var aspect:=maxf(0.25,size.x/maxf(1.0,size.y))
	_camera.size=maxf(board.x,board.y)*1.65*maxf(1.0,1.0/aspect)
	_viewport.render_target_update_mode=SubViewport.UPDATE_ONCE


func _rebuild() -> void:
	for child in _root.get_children():
		_root.remove_child(child)
		child.queue_free()
	if _frame.is_empty():
		return
	var board: Vector2=_frame["size"]
	_box(Vector3(board.x*0.5,-0.22,board.y*0.5),Vector3(board.x,0.4,board.y),Color("334957"))
	for r: Rect2 in _frame.get("voids",[]):
		_box(_center(r,0.0),Vector3(r.size.x,0.04,r.size.y),Color("101923"))
	for p: Dictionary in _frame["terrain"]:
		if not _surface.is_empty() and str(p["surface"]) not in ["",_surface]:
			continue
		var r: Rect2=p["rect"]
		var h:=maxf(0.08,float(p.get("height",1.2 if p["solid"] else 0.1)))
		var at:=_center(r,float(p.get("base",0.0))+h*0.5)
		var color:=Color("788894") if p["solid"] else Color("4d6876")
		if p["circular"]:
			_cylinder(at,r.size.x*0.5,h,color)
		else:
			_box(at,Vector3(r.size.x,h,r.size.y),color)
	if _surface.is_empty():
		for solid: AABB in _frame.get("solids",[]):
			_box(solid.get_center(),solid.size,Color("536673"))
	for floor: Dictionary in _frame["floors"]:
		if floor["id"]=="street" or (not _surface.is_empty() and floor["id"]!=_surface):
			continue
		_floor_slab(floor)
	for t: Dictionary in _frame["tokens"]:
		if not _surface.is_empty() and t["surface"]!=_surface:
			continue
		var pos: Vector2=t["pos"]
		_box(Vector3(pos.x,float(t.get("height",0.0))+0.28,pos.y),Vector3(0.55,0.5,0.55),Color("e5bd62"))
	for f: Dictionary in _frame["figures"]:
		if not f["in_play"] or (not _surface.is_empty() and f["surface"]!=_surface):
			continue
		var pos: Vector2=f["pos"]
		var at:=Vector3(pos.x,float(f["height"]),pos.y)
		var side:=int(f["side"])
		var color:=Color("b79be9") if side<0 else (Color("6ba9f8") if side==0 else Color("ef8a7a"))
		_cylinder(at+Vector3.UP*0.08,0.52,0.16,Color("f5d17c") if f["id"]==_frame["active"] else color.darkened(0.4))
		_cylinder(at+Vector3.UP*0.67,0.28,1.1,color)
		var label:=Label3D.new()
		label.text="%d · %d HP"%[f["id"],f["health"]]
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size=42
		label.pixel_size=0.018
		label.no_depth_test=true
		label.position=at+Vector3.UP*1.65
		_root.add_child(label)


func _floor_slab(floor: Dictionary) -> void:
	var r: Rect2=floor["rect"]
	var h:=float(floor["height"])
	var end:=float(floor.get("end_height",h))
	var axis_y:=bool(floor.get("axis_y",false))
	var run:=r.size.y if axis_y else r.size.x
	var slab:=_box(_center(r,(h+end)*0.5-0.08),Vector3(r.size.x,0.16,r.size.y),Color("688e9f"))
	var angle:=atan2(end-h,maxf(0.001,run))
	if axis_y:
		slab.rotation.x=-angle
		slab.scale.z=Vector2(run,end-h).length()/maxf(0.001,run)
	else:
		slab.rotation.z=angle
		slab.scale.x=Vector2(run,end-h).length()/maxf(0.001,run)


func _center(r: Rect2,height: float) -> Vector3:
	return Vector3(r.get_center().x,height,r.get_center().y)


func _box(at: Vector3,dimensions: Vector3,color: Color) -> MeshInstance3D:
	var mesh:=BoxMesh.new()
	mesh.size=dimensions
	return _mesh(at,mesh,color)


func _cylinder(at: Vector3,radius: float,height: float,color: Color) -> void:
	var mesh:=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=12
	_mesh(at,mesh,color)


func _mesh(at: Vector3,mesh: Mesh,color: Color) -> MeshInstance3D:
	var instance:=MeshInstance3D.new()
	instance.mesh=mesh
	if not _materials.has(color):
		var material:=StandardMaterial3D.new()
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color=color
		_materials[color]=material
	instance.material_override=_materials[color]
	instance.position=at
	_root.add_child(instance)
	return instance
