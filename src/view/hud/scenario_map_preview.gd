class_name ScenarioMapPreview
extends Control
## Overhead terrain schematic generated directly from the playable board definition.
var _board: Board
var _treasures: Array[Vector2]=[]


func setup(id: String) -> void:
	_treasures.clear()
	_board=BoardLoader.load_id(id,TerrainDb.load_file())
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func setup_scenario(data: Dictionary) -> void:
	setup(str(data["board"]))
	for token: Variant in data.get("treasures",[]):
		var at: Array=token.get("at",[]) if token is Dictionary else (token if token is Array else [])
		if at.size()>=2:
			_treasures.append(Vector2(float(at[0]),float(at[1])))
	queue_redraw()


func _draw() -> void:
	if _board==null:
		return
	var scale_factor := minf((size.x-8)/_board.size.x,(size.y-8)/_board.size.y)
	var origin := (size-_board.size*scale_factor)*0.5
	draw_rect(Rect2(origin,_board.size*scale_factor),Color("b1c6cf"))
	for piece in _board.pieces:
		var tint := Color("61747e")
		if piece.kind.ground_surface:
			tint=Color("90a7b5")
		elif piece.kind.walkable_top:
			tint=Color("829aa4")
		elif piece.kind.id=="rubble":
			tint=Color("998a79")
		elif piece.kind.id=="arcane_disc":
			tint=Color("7e8eaa")
		draw_rect(Rect2(origin+piece.rect.position*scale_factor,piece.rect.size*scale_factor),tint)
	var layout := _board.floor_layout
	if not layout.is_empty():
		for surface: Dictionary in layout.get("surfaces",[]):
			var height := maxf(float(surface.get("level",0)),float(surface.get("end_level",0)))
			if height<=0:
				continue
			var rect: Array=surface["rect"]
			var area := Rect2(origin+Vector2(rect[0],rect[1])*scale_factor,Vector2(rect[2],rect[3])*scale_factor)
			var tint := Color("a48956").lightened(clampf(height/30.0,0.0,0.4))
			draw_rect(area,tint)
			draw_rect(area,Color("655537"),false,1.0)
	for at in _treasures:
		var point := origin+at*scale_factor
		draw_circle(point,5.0,Color("60482a"))
		draw_circle(point,3.5,Color("f1ca7c"))
	draw_rect(Rect2(origin,_board.size*scale_factor),Color("52646b"),false,2)
