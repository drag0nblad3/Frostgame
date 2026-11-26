class_name LayeredGrid
extends RefCounted
## Experimental floor-aware graph. Legacy MoveGrid remains unchanged.
var layout: FloorLayout
var mover: Figure
var others: Array[Figure] = []


func _init(floors: FloorLayout,f: Figure = null,figures: Array[Figure] = []) -> void:
	layout=floors
	mover=f
	for other in figures:
		if other!=f and other.in_play():
			others.append(other)


func open(n: Vector3i) -> bool:
	if not layout.standable(n):
		return false
	var at := layout.world(n)
	for other in others:
		if absf(other.elevation-at.y)<0.5 and other.pos.distance_to(layout.point(n))<Contact.OVERLAP:
			return false
	return true


func stops(n: Vector3i) -> bool:
	if mover==null:
		return false
	for other in others:
		if other.side!=mover.side and absf(other.elevation-layout.height(n))<0.5 and Contact.touching(other.pos,layout.point(n)):
			return true
	return false


func neighbors(n: Vector3i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not open(n):
		return out
	var start := layout.world(n)
	for d: Vector2i in MoveGrid.NEIGHBORS:
		var next := n+Vector3i(d.x,d.y,0)
		if not open(next):
			continue
		var finish := layout.world(next)
		if not layout.clearance(start.lerp(finish,0.5),Figure.BASE_RADIUS,1.6):
			continue
		var mult := layout.surfaces[n.z].rough
		if mover!=null and mover.def.traits.has("levitate"):
			mult=1.0
		out.append({"to":next,"cost":start.distance_to(finish)*mult})
	for edge: Dictionary in layout.links.get(n,[]):
		var next: Vector3i = edge["to"]
		if not open(next):
			continue
		var cost: float = edge["cost"]
		if edge["kind"]=="climb" and mover!=null and (mover.def.traits.has("expert_climber") or mover.def.traits.has("levitate")):
			cost=layout.point(n).distance_to(layout.point(next))+ceilf(absf(layout.height(n)-layout.height(next)))
		out.append({"to":next,"cost":cost})
	return out
