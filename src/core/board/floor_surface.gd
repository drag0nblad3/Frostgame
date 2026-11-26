class_name FloorSurface
extends RefCounted
## A named, independently walkable surface. Inclines use an optional end height.
var id := ""
var rect := Rect2()
var level := 0.0
var end_level := 0.0
var axis_y := false
var rough := 1.0


static func from_dict(d: Dictionary) -> FloorSurface:
	var s := FloorSurface.new()
	s.id = str(d["id"])
	var r: Array = d["rect"]
	s.rect = Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3]))
	s.level = float(d.get("level",0.0))
	s.end_level = float(d.get("end_level",s.level))
	s.axis_y = d.get("axis","x") == "y"
	s.rough = maxf(1.0,float(d.get("move_mult",1.0)))
	return s


func height_at(p: Vector2) -> float:
	var run := rect.size.y if axis_y else rect.size.x
	var offset := p.y-rect.position.y if axis_y else p.x-rect.position.x
	return lerpf(level,end_level,clampf(offset/maxf(run,0.001),0.0,1.0))


func contains(p: Vector2, radius: float = 0.0) -> bool:
	return p.x >= rect.position.x+radius-0.001 and p.y >= rect.position.y+radius-0.001 and p.x <= rect.end.x-radius+0.001 and p.y <= rect.end.y-radius+0.001
