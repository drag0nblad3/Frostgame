class_name ReplayMap
extends Control
## Draw-only tactical reconstruction from plain data, independent of live 3D.
signal figure_selected(text: String)
var frame: Dictionary={}
var _markers: Array[Dictionary]=[]
var floor_id:=""
var _font: Font


func _ready() -> void:
	custom_minimum_size=Vector2(140,140)
	mouse_filter=Control.MOUSE_FILTER_STOP
	gui_input.connect(_pick)
	_font=ThemeDB.fallback_font
	resized.connect(queue_redraw)


func show_frame(value: Dictionary,surface: String="") -> void:
	frame=value
	floor_id=surface
	_markers.clear()
	figure_selected.emit("")
	queue_redraw()


func _draw() -> void:
	_markers.clear()
	if frame.is_empty() or _font==null:
		return
	var board: Vector2=frame["size"]
	var scale_factor:=minf((size.x-20)/maxf(board.x,1),(size.y-20)/maxf(board.y,1))
	if scale_factor<=0:
		return
	var origin:=(size-board*scale_factor)*0.5
	var point:=func(p: Vector2) -> Vector2: return origin+Vector2(p.x,board.y-p.y)*scale_factor
	var rect_at:=func(r: Rect2) -> Rect2: return Rect2(point.call(Vector2(r.position.x,r.end.y)),r.size*scale_factor)
	var area:=Rect2(origin,board*scale_factor)
	draw_rect(area,Color("263744"))
	for x in range(0,ceili(board.x)+1,6):
		draw_line(point.call(Vector2(x,0)),point.call(Vector2(x,board.y)),Color("394c59"))
	for y in range(0,ceili(board.y)+1,6):
		draw_line(point.call(Vector2(0,y)),point.call(Vector2(board.x,y)),Color("394c59"))
	for r: Rect2 in frame["voids"]:
		draw_rect(rect_at.call(r),Color("0e1822"))
	for p: Dictionary in frame["terrain"]:
		if not floor_id.is_empty() and str(p["surface"]) not in ["",floor_id]:
			continue
		var r: Rect2=rect_at.call(p["rect"])
		var color:=Color("697986") if p["solid"] else Color("445e6a")
		if p["circular"]:
			draw_circle(r.get_center(),r.size.x*0.5,color)
		else:
			draw_rect(r,color)
	for f: Dictionary in frame["floors"]:
		if f["id"]=="street" or (not floor_id.is_empty() and f["id"]!=floor_id):
			continue
		var r: Rect2=rect_at.call(f["rect"])
		draw_rect(r,Color(0.46,0.70,0.80,0.15))
		draw_rect(r,Color("87b7c8"),false,1.0)
	for t: Dictionary in frame["tokens"]:
		if not floor_id.is_empty() and t["surface"]!=floor_id:
			continue
		var p: Vector2=point.call(t["pos"])
		var d:=maxf(3,scale_factor*0.45)
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-d),p+Vector2(d,0),p+Vector2(0,d),p+Vector2(-d,0)]),Color("f3cf73"))
	for f: Dictionary in frame["figures"]:
		if not f["in_play"] or (not floor_id.is_empty() and f["surface"]!=floor_id):
			continue
		var p: Vector2=point.call(f["pos"])
		var radius:=maxf(4,scale_factor*0.5)
		var side:=int(f["side"])
		var color:=Color("b79be9") if side<0 else (Color("6ba9f8") if side==0 else Color("ef8a7a"))
		draw_circle(p,radius+1.5,Color("101923"))
		draw_circle(p,radius,color)
		_markers.append({"at":p,"figure":f,"radius":radius})
		if int(f["id"])==int(frame["active"]):
			draw_arc(p,radius+3,0,TAU,24,Color("ffe39b"),2)
		var text:="%d"%int(f["id"])
		if absf(float(f["height"]))>0.01:
			text+=" · %.1f"%float(f["height"])
		draw_string(_font,p+Vector2(radius+2,4),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
	draw_rect(area,Color("8b9ba6"),false,1.5)


func _pick(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT:
		return
	var best: Dictionary={}
	var distance:=INF
	for marker: Dictionary in _markers:
		var d: float=event.position.distance_to(marker["at"])
		if d<=maxf(18.0,float(marker["radius"])+5.0) and d<distance:
			distance=d
			best=marker["figure"]
	if best.is_empty():
		figure_selected.emit("")
	else:
		figure_selected.emit("#%d %s · Health %d/%d · %.1f in high · %s"%[best["id"],best["name"],best["health"],best["max_health"],best["height"],str(best["surface"]).replace("_"," ") if not str(best["surface"]).is_empty() else "Ground"])
	accept_event()
