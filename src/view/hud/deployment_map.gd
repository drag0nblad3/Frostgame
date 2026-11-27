class_name DeploymentMap
extends Control
## Schematic deployment board. Only the controller's draft changes.
signal placed(at: Vector2)
var plan: DeploymentPlan
var selected := -1


func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	custom_minimum_size=Vector2(160,160)


func _scale() -> float:
	return minf((size.x-16)/plan.state.board.size.x,(size.y-16)/plan.state.board.size.y)


func _origin() -> Vector2:
	return (size-plan.state.board.size*_scale())*0.5


func _gui_input(event: InputEvent) -> void:
	if plan==null or _scale()<=0:
		return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var point: Vector2=(event.position-_origin())/_scale()
		placed.emit((point*2.0).round()*0.5)
		accept_event()


func _draw() -> void:
	if plan==null or size.x<20 or size.y<20:
		return
	var b:=plan.state.board
	var k:=_scale()
	var origin:=_origin()
	draw_rect(Rect2(origin,b.size*k),Color("a5b8c2"))
	var points: Array=plan.candidates.get(plan.edge[plan.human],[])
	var chosen:=plan.state.figure(selected)
	for at: Vector2 in points:
		if chosen!=null and not plan._formation_ok(chosen,at):
			continue
		draw_rect(Rect2(origin+(at-Vector2.ONE*0.25)*k,Vector2.ONE*0.5*k),Color("438da0"))
	for region in b.void_regions:
		draw_rect(Rect2(origin+region.position*k,region.size*k),Color("243345"))
	for p in b.pieces:
		draw_rect(Rect2(origin+p.rect.position*k,p.rect.size*k),Color("50606a") if p.kind.blocks_move else Color("8c9a97"))
	if not b.floor_layout.is_empty():
		for solid in b.floor_geometry().solids:
			if solid.position.y<=0.1 and solid.size.y>0.5:
				draw_rect(Rect2(origin+Vector2(solid.position.x,solid.position.z)*k,Vector2(solid.size.x,solid.size.z)*k),Color("50606a"))
	for token in plan.state.treasures:
		if token.on_ground():
			draw_circle(origin+token.pos*k,4.0,Color("efc566"))
	for f in plan.state.figures:
		if f.side>=0 and not plan.placements.has(f.id):
			continue
		if f.side>=0 and f.side!=plan.human and plan.winner==plan.human:
			continue
		var at:=f.pos
		if plan.placements.has(f.id):
			at=plan.placements[f.id]["at"]
		var p:=origin+at*k
		var tint:=Color("155d9c") if f.side==plan.human else (Color("a64343") if f.side>=0 else Color("674987"))
		draw_circle(p,maxf(5.0,k*0.48),tint)
		if f.id==selected:
			draw_arc(p,maxf(7.0,k*0.65),0,TAU,24,Color("ffffff"),2.0)
		draw_string(ThemeDB.fallback_font,p+Vector2(5,-5),str(f.id),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ffffff"))
	draw_rect(Rect2(origin,b.size*k),Color("d9e4e7"),false,2)
