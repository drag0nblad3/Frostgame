class_name ScenarioTablePreview
extends Control
## Cheap axonometric map: only CanvasItem polygons, never a live 3D city.
var _board: Board
var _pieces: Array[TerrainPiece]=[]
var _scale := 1.0
var _origin := Vector2.ZERO
var _high := 0.0
var _low := 0.0


func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func setup(board: Board) -> void:
	if board==_board:
		return
	_board=board
	_pieces.assign(board.pieces)
	_pieces.sort_custom(func(a: TerrainPiece,b: TerrainPiece) -> bool:
		if a.kind.ground_surface!=b.kind.ground_surface:
			return a.kind.ground_surface
		var da := a.rect.get_center().x+a.rect.get_center().y
		var db := b.rect.get_center().x+b.rect.get_center().y
		if is_equal_approx(da,db):
			return a.kind.height<b.kind.height
		return da<db)
	_high=0.0
	_low=0.0
	for p in _pieces:
		var a := p.surface_height(p.rect.position)
		var b := p.surface_height(p.rect.end)
		_high=maxf(_high,maxf(a,b))
		_low=minf(_low,minf(a,b))
	for surface: Dictionary in board.floor_layout.get("surfaces",[]):
		_high=maxf(_high,maxf(float(surface.get("level",0)),float(surface.get("end_level",0))))
	queue_redraw()


func _draw() -> void:
	if _board==null or size.x<16 or size.y<16:
		return
	var span := _board.size.x+_board.size.y
	var depth := span*0.48+_high-_low+1.0
	_scale=minf((size.x-16)/span,(size.y-16)/depth)
	_origin=Vector2((size.x-span*_scale)*0.5+_board.size.y*_scale,(size.y-depth*_scale)*0.5+_high*_scale)
	var bounds := Rect2(Vector2.ZERO,_board.size)
	_prism(bounds,-0.8,0.0,Color("9cb6c5"))
	for region in _board.void_regions:
		_face(_corners(region,0.02),Color("263547"))
	for p in _pieces:
		_draw_piece(p)
	for surface: Dictionary in _board.floor_layout.get("surfaces",[]):
		var h := float(surface.get("level",0))
		var end := float(surface.get("end_level",h))
		if maxf(h,end)<=0:
			continue
		var r: Array=surface["rect"]
		var rect := Rect2(r[0],r[1],r[2],r[3])
		if not is_equal_approx(h,end):
			_slope(rect,h,end,surface.get("axis","x")=="y",Color("bbad8c"))
		else:
			_prism(rect,h-0.25,h,Color("bbad8c"))


func _draw_piece(p: TerrainPiece) -> void:
	var tint := Color("748d9e")
	if p.kind.ground_surface:
		var h := p.surface_height(p.rect.position)
		if p.ramp:
			_slope(p.rect,p.ramp_start,p.ramp_end,p.ramp_rotated,Color("a0b4bd"))
		elif h<0:
			# Dark inset indicates a depression, not a hole in the table.
			_face(_corners(p.rect,0.04),Color("647e91"))
		else:
			_prism(p.rect,0.0,maxf(0.04,h),Color("a0b4bd"))
		return
	if p.kind.walkable_top:
		tint=Color("b0a48b")
	elif p.kind.id=="rubble":
		tint=Color("958575")
	elif p.circular:
		tint=Color("74aabd")
	var top := maxf(0.06,p.kind.height)
	if p.circular or p.kind.id=="temple_column":
		var ring := PackedVector3Array()
		for i in 16:
			var a := TAU*float(i)/16.0
			var at := p.rect.get_center()+Vector2(cos(a),sin(a))*p.rect.size*0.5
			ring.append(Vector3(at.x,top,at.y))
		_face(_corners(p.rect,0.02),tint.darkened(0.3))
		_face(ring,tint)
	else:
		_prism(p.rect,0.0,top,tint)


func _corners(r: Rect2,h: float) -> PackedVector3Array:
	return PackedVector3Array([Vector3(r.position.x,h,r.position.y),Vector3(r.end.x,h,r.position.y),Vector3(r.end.x,h,r.end.y),Vector3(r.position.x,h,r.end.y)])


func _prism(r: Rect2,bottom: float,top: float,tint: Color) -> void:
	var a := _corners(r,bottom)
	var b := _corners(r,top)
	_face(PackedVector3Array([a[1],a[2],b[2],b[1]]),tint.darkened(0.24))
	_face(PackedVector3Array([a[2],a[3],b[3],b[2]]),tint.darkened(0.39))
	_face(b,tint)


func _slope(r: Rect2,start: float,end: float,along_y: bool,tint: Color) -> void:
	var b := _corners(r,start)
	if along_y:
		b[2]=Vector3(b[2].x,end,b[2].z)
		b[3]=Vector3(b[3].x,end,b[3].z)
	else:
		b[1]=Vector3(b[1].x,end,b[1].z)
		b[2]=Vector3(b[2].x,end,b[2].z)
	_face(b,tint)


func _face(points: PackedVector3Array,tint: Color) -> void:
	var projected := PackedVector2Array()
	for p in points:
		projected.append(_origin+Vector2(p.x-p.z,(p.x+p.z)*0.48-p.y)*_scale)
	draw_colored_polygon(projected,tint)
	projected.append(projected[0])
	draw_polyline(projected,Color("344956"),1.0,true)
