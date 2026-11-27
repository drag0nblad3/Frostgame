class_name TigerEye
extends RefCounted
const ITEM := "gear_rk_tiger_eye_ring"


static func active(f: Figure) -> bool:
	return f!=null and f.def.role=="wizard" and ActiveGear.has(f,ITEM) and not MagicEquipment.suppressed(f)


static func witness(b: Board,f: Figure,at: Vector2,limit: float=24.0) -> Variant:
	if not active(f) or not b.floor_layout.is_empty() or b.reality_sphere or RealityCrackGeometry.cross_relation(b,f.pos,at)!=0 or Vector2(f.pos.distance_to(at),f.elevation-b.height_at(at)).length()>limit or BattleBoundary.blocks_segment(b.boundaries,f.pos,at,"sight",f):
		return null
	for x in range(-4,5):
		for y in range(-4,5):
			var point := at+Vector2(x,y)*0.5
			if not b.contains(point) or Vector2(point.distance_to(at),b.height_at(point)-b.height_at(at)).length()>2.001:
				continue
			if BattleBoundary.blocks_segment(b.boundaries,point,at,"sight",f):
				continue
			if LineOfSight.check(b,f.pos,point,f).clear:
				return point
	return null


static func floor_witness(b: Board,f: Figure,at: Vector3,limit: float=24.0) -> Variant:
	if not active(f) or Vector3(f.pos.x,f.elevation,f.pos.y).distance_to(at)>limit or BattleBoundary.blocks_segment(b.boundaries,f.pos,Vector2(at.x,at.z),"sight",f):
		return null
	var layout:=b.floor_geometry()
	var start:=Vector3(f.pos.x,f.elevation+1.5,f.pos.y)
	for n in BattlePlacement.nodes(b,Vector2(at.x,at.z),2.0):
		if not layout.standable(n):
			continue
		var point:=layout.world(n)
		if point.distance_to(at)>2.001 or BattleBoundary.blocks_segment(b.boundaries,Vector2(point.x,point.z),Vector2(at.x,at.z),"sight",f):
			continue
		if LineOfSight.floor_ray(b,layout,start,point+Vector3.UP,f):
			return point+Vector3.UP
	return null


static func test_use(c: GameController,f: Figure) -> void:
	var roll := c.dice.d20()
	var ok := StatRoll.succeeds(roll,f.effective_will()+f.roll_penalty(),20)
	c.emit("gear_used",{"id":f.id,"gear":ITEM,"roll":roll,"success":ok})
	if not ok:
		c._hurt(f,3,f,false)


static func perimeter(rect: Rect2,at: Vector2,normal: Vector2) -> float:
	if normal==Vector2.UP:
		return at.x-rect.position.x
	if normal==Vector2.RIGHT:
		return rect.size.x+at.y-rect.position.y
	if normal==Vector2.DOWN:
		return rect.size.x+rect.size.y+rect.end.x-at.x
	return rect.size.x*2+rect.size.y+rect.end.y-at.y


static func eye_options(c: GameController) -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	var f := c.state.active()
	if not active(f) or not c.can_act() or Contact.in_combat(c.state.figures,f) or int(f.used_gear.get("rk_tiger_eye_turn",-1))==c.state.turn:
		return out
	var eye := WizardEye.marker(c.state.board,f)
	if eye==null:
		return out
	var rect:=Rect2()
	if eye.eye_host!=null:
		rect=eye.eye_host.rect.grow(0.15)
	elif eye.eye_solid.size()==6:
		var v:=eye.eye_solid
		rect=Rect2(v[0],v[2],v[3],v[5]).grow(0.15)
	else:
		return out
	var start := perimeter(rect,eye.rect.get_center(),eye.eye_direction)
	var length := (rect.size.x+rect.size.y)*2
	for step in range(-8,9):
		if step==0:
			continue
		var pos := fposmod(start+float(step)*0.5,length)
		var at: Vector2
		var normal: Vector2
		if pos<rect.size.x:
			at=rect.position+Vector2(pos,0)
			normal=Vector2.UP
		elif pos<rect.size.x+rect.size.y:
			at=Vector2(rect.end.x,rect.position.y+pos-rect.size.x)
			normal=Vector2.RIGHT
		elif pos<rect.size.x*2+rect.size.y:
			at=Vector2(rect.end.x-(pos-rect.size.x-rect.size.y),rect.end.y)
			normal=Vector2.DOWN
		else:
			at=Vector2(rect.position.x,rect.end.y-(pos-rect.size.x*2-rect.size.y))
			normal=Vector2.LEFT
		if c.state.board.contains(at) and not ScenarioNull.field_at(c.state.board,at,0.0) and at.distance_to(eye.rect.get_center())>0.1:
			out.append({"at":at,"direction":normal,"world":Vector3(at.x,eye.base_height,at.y)})
	return out


static func move_eye(c: GameController,at: Vector2) -> bool:
	for option in eye_options(c):
		if at.distance_to(option["at"])>0.35:
			continue
		var f := c.state.active()
		var eye := WizardEye.marker(c.state.board,f)
		eye.rect.position=option["at"]-eye.rect.size*0.5
		eye.eye_direction=option["direction"]
		f.used_gear["rk_tiger_eye_turn"]=c.state.turn
		c._spend(f)
		c.state.board.invalidate_terrain()
		c.emit("terrain_changed",{"spell":"wizard_eye","created":true})
		test_use(c,f)
		return true
	return false
