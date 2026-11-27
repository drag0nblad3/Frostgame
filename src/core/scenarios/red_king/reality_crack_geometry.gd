class_name RealityCrackGeometry
extends RefCounted
## Persistent alternative battlefield topology (17, 18, 20).


static func apply(c: GameController,effect: int) -> void:
	var s := c.state
	var b := s.board
	s.scenario_data["reality_prior_wrap"]=[b.wrap_short_edges,b.wrap_long_edges]
	if effect in [17,20]:
		b.wrap_short_edges=true
		b.wrap_long_edges=true
		b.reality_sphere=effect==17
	if effect==18:
		b.reality_cross=c.dice.pick(4)
		for f in s.figures:
			if f.in_play() and not f.is_demon() and not f.def.traits.has("undead") and not f.def.traits.has("construct"):
				if not StatRoll.succeeds(c.dice.d20(),f.effective_will()+f.roll_penalty(),18):
					f.spell_effects["reality_skip_next"]=true
	var lines: Array[Dictionary]=[]
	lines.assign(s.scenario_data.get("reality_prior_boundaries",[]))
	if effect==18:
		lines.append({"a":Vector2(b.size.x/2.0,0),"b":Vector2(b.size.x/2.0,b.size.y),"movement":true,"sight":true,"allow_movement_spells":["plane_walk"]})
		lines.append({"a":Vector2(0,b.size.y/2.0),"b":Vector2(b.size.x,b.size.y/2.0),"movement":true,"sight":true,"allow_movement_spells":["plane_walk"]})
	elif effect==20:
		for i in [1,2]:
			lines.append({"a":Vector2(b.size.x*float(i)/3.0,0),"b":Vector2(b.size.x*float(i)/3.0,b.size.y),"sight":true,"stop":true})
			lines.append({"a":Vector2(0,b.size.y*float(i)/3.0),"b":Vector2(b.size.x,b.size.y*float(i)/3.0),"sight":true,"stop":true})
	b.set_boundaries(lines)
	for f in s.figures:
		if f.in_play() and (BattleBoundary.blocks_position(lines,f.pos,f) or BattleBoundary.blocks_end(lines,f.pos)):
			ForcedRelocation.relocate(c,f,f.pos)
	c.emit("boundary_changed",{})


static func clear(c: GameController) -> void:
	var b := c.state.board
	var old: Array=c.state.scenario_data.get("reality_prior_wrap",[])
	if old.size()==2:
		b.wrap_short_edges=old[0]
		b.wrap_long_edges=old[1]
	b.reality_sphere=false
	b.reality_cross=-1
	b.invalidate_terrain()


static func quadrant(b: Board,at: Vector2) -> int:
	return (1 if at.x>=b.size.x*0.5 else 0)+(2 if at.y>=b.size.y*0.5 else 0)


static func cross_relation(b: Board,a: Vector2,z: Vector2) -> int:
	# 0 same plane, 1 connected perpendicular planes, -1 isolated.
	if b.reality_cross<0:
		return 0
	var first := quadrant(b,a)
	var last := quadrant(b,z)
	if first==last:
		return 0
	var isolated := b.reality_cross
	return -1 if first in [isolated,isolated^3] or last in [isolated,isolated^3] else 1


static func sight_distance(b: Board,a: Vector2,z: Vector2) -> float:
	var relation := cross_relation(b,a,z)
	if relation!=0:
		return 12.0 if relation==1 else INF
	var delta := z-a
	if b.reality_sphere:
		delta.x=minf(absf(delta.x),b.size.x-absf(delta.x))
		delta.y=minf(absf(delta.y),b.size.y-absf(delta.y))
	return delta.length()


static func wrapped_sight(b: Board,a: Vector2,z: Vector2,observer: Figure) -> LineOfSight.Result:
	var result := LineOfSight.Result.new()
	result.clear=false
	var limit := 6.0+(observer.elevation if observer!=null else b.height_at(a))
	for dx in range(-1,2):
		for dy in range(-1,2):
			var target := z+Vector2(dx*b.size.x,dy*b.size.y)
			var delta := target-a
			if delta.length()>limit+0.001:
				continue
			var stops: Array[float]=[0.0,1.0]
			if absf(delta.x)>0.0001:
				for edge in [0.0,b.size.x]:
					var t: float=(edge-a.x)/delta.x
					if t>0.0 and t<1.0:
						stops.append(t)
			if absf(delta.y)>0.0001:
				for edge in [0.0,b.size.y]:
					var t: float=(edge-a.y)/delta.y
					if t>0.0 and t<1.0:
						stops.append(t)
			stops.sort()
			var clear_ray := true
			var cover := 0
			var intervening := 0
			for i in range(stops.size()-1):
				if is_equal_approx(stops[i],stops[i+1]):
					continue
				var mid := a+delta*(stops[i]+stops[i+1])*0.5
				var offset := Vector2(floorf(mid.x/b.size.x)*b.size.x,floorf(mid.y/b.size.y)*b.size.y)
				var ray := LineOfSight.plain_check(b,a+delta*stops[i]-offset,a+delta*stops[i+1]-offset,observer)
				if not ray.clear:
					clear_ray=false
					break
				cover=maxi(cover,ray.cover)
				intervening+=ray.intervening
			if clear_ray:
				result.clear=true
				result.cover=cover
				result.intervening=intervening
				return result
	return result
