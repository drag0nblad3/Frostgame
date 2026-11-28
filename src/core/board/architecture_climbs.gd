class_name ArchitectureClimbs
extends RefCounted
## Generate climb links from real vertical masonry faces to nearby flat decks.
## IDs are derived from geometry and endpoint names, not transient indices.
## No synthetic roof is added to a solid that has no legal standing deck.
const SPACING := 1.0
const MAX_RISE := 12.0

static func add(layout: FloorLayout) -> void:
	var decks: Array[FloorSurface]=[]
	decks.assign(layout.surfaces.filter(func(s: FloorSurface) -> bool:
		return not s.id.begins_with("climb:") and not s.id.begins_with("bridge:") and not s.id.begins_with("wall:") and is_equal_approx(s.level,s.end_level)))
	var seen: Dictionary={}
	for wall in layout.solids:
		# A slab, low scatter item or beam is not a continuous wall.
		if wall.size.y<1.0 or layout.magic_solids.has(wall):
			continue
		var rect:=Rect2(Vector2(wall.position.x,wall.position.z),Vector2(wall.size.x,wall.size.z))
		for axis in 2:
			var along:=Vector2.RIGHT if axis==0 else Vector2.DOWN
			var normal:=Vector2.DOWN if axis==0 else Vector2.RIGHT
			var length:=rect.size.x if axis==0 else rect.size.y
			var width:=rect.size.y if axis==0 else rect.size.x
			if length<1.0:
				continue
			var count:=maxi(1,ceili(length/SPACING))
			for i in count:
				var mid:=rect.get_center()+along*((float(i)+0.5)*length/count-length*0.5)
				for side: int in [-1,1]:
					var face:=mid+normal*(width*0.5)*side
					var outside:=_snap_outside(face,normal*side)
					for lower in decks:
						var a:=layout.node(lower.id,outside)
						if not layout.standable(a):
							continue
						var low:=layout.height(a)
						if low<wall.position.y-0.5 or low>=wall.end.y-0.5:
							continue
						for upper in decks:
							if upper==lower or upper.level<=low or upper.level-low>MAX_RISE or absf(upper.level-wall.end.y)>0.75:
								continue
							var inside:=face-normal*side*Figure.BASE_RADIUS
							var b:=layout.node(upper.id,inside)
							if not layout.standable(b) or layout.point(a).distance_to(layout.point(b))>1.5:
								continue
							var key:="%s>%s:%d:%d:%d:%d"%[lower.id,upper.id,a.x,a.y,b.x,b.y]
							if seen.has(key) or not _clear(layout,a,b):
								continue
							seen[key]=true
							FloorClimb.add(layout,{"id":"auto:"+key,"from":[lower.id,layout.point(a).x,layout.point(a).y],"to":[upper.id,layout.point(b).x,layout.point(b).y]})

static func _snap_outside(at: Vector2,normal: Vector2) -> Vector2:
	var p:=at+normal*Figure.BASE_RADIUS
	var snapped:=MoveGrid.to_pos(MovePlanner.node_at(p))
	if normal.dot(snapped-p)<-0.001:
		snapped+=normal*MoveGrid.STEP
	return snapped

static func _clear(layout: FloorLayout,a: Vector3i,b: Vector3i) -> bool:
	var start:=layout.world(a)
	var finish:=layout.world(b)
	var crest:=Vector3(start.x,finish.y,start.z)
	var steps:=maxi(1,ceili(start.distance_to(crest)*10.0))
	for i in range(steps+1):
		if not layout.clearance(start.lerp(crest,float(i)/steps),Figure.BASE_RADIUS,1.6):
			return false
	for i in range(11):
		if not layout.clearance(crest.lerp(finish,float(i)/10.0),Figure.BASE_RADIUS,1.6):
			return false
	return true
