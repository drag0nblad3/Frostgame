class_name RedKingBridge
extends RefCounted
## Red King scenario eleven (printed pp.53–54).
const ID := "red_king_bridge"
const HRUT := ["hrut_warrior","hrut_stinger","hrut_longhammer","hrut_darter"]


static func active(s: GameState) -> bool:
	return s!=null and s.scenario_special==ID


static func deployment(s: GameState,side: int,index: int) -> Vector2:
	var p := Vector2(0.5+float(index%3),0.5+float(floori(float(index)/3.0)))
	if index==9:
		p=Vector2(3.5,0.5)
	if side==1:
		p.x=s.board.size.x-p.x
	return p


static func exit_allowed(s: GameState,at: Vector2) -> bool:
	return at.y>=s.board.size.y-Figure.BASE_RADIUS-0.01 and absf(at.x-s.board.size.x*0.5)<=2.0-Figure.BASE_RADIUS+0.001


static func end_turn(c: GameController) -> void:
	if not active(c.state):
		return
	replace_veil(c,c.dice.pick(6)+1,c.dice.pick(6)+1)


static func replace_veil(c: GameController,left: int,right: int) -> void:
	var s := c.state
	if not active(s):
		return
	var a := Vector2(0,6.0*(clampi(left,1,6)-1))
	var b := Vector2(s.board.size.x,6.0*(clampi(right,1,6)-1))
	var lines: Array[Dictionary]=[{"a":a,"b":b,"movement":true,"sight":true,"allow_figures":HRUT.duplicate(),"allow_movement_spells":["plane_walk"]}]
	s.scenario_data["bridge_veil_rolls"]=[left,right]
	s.board.set_boundaries(lines)
	c.emit("boundary_changed",{})
	c.emit("bridge_veil",{"left":left,"right":right})
	for f in s.figures.duplicate():
		if f.in_play() and Geometry2D.get_closest_point_to_segment(f.pos,a,b).distance_to(f.pos)<Figure.BASE_RADIUS:
			_shift(c,f,a,b)
	if left>=5:
		_spawn(c,a+Vector2.RIGHT*Figure.BASE_RADIUS)
	if right>=5:
		_spawn(c,b+Vector2.LEFT*Figure.BASE_RADIUS)


static func _shift(c: GameController,f: Figure,a: Vector2,b: Vector2) -> void:
	var s := c.state
	var normal := (b-a).orthogonal().normalized()
	if c.dice.pick(2)==0:
		normal=-normal
	var center := MovePlanner.node_at(f.pos)
	var grid := MoveGrid.new(s.board,f,s.figures)
	var best: Variant=null
	var score := INF
	for x in range(-8,9):
		for y in range(-8,9):
			var node := center+Vector2i(x,y)
			var at := MoveGrid.to_pos(node)
			var offset := at-Geometry2D.get_closest_point_to_segment(at,a,b)
			var d := at.distance_squared_to(f.pos)
			if offset.dot(normal)>=Figure.BASE_RADIUS-0.001 and d<score and grid.open(node):
				best=node
				score=d
	if best==null:
		return
	var old := f.pos
	f.pos=MoveGrid.to_pos(best)
	f.elevation=s.board.height_at(f.pos)
	f.disengaged.clear()
	for other in s.figures:
		other.disengaged.erase(f.id)
	c.emit("forced_relocation",{"id":f.id,"from":old,"at":f.pos,"height":f.elevation})


static func _spawn(c: GameController,origin: Vector2) -> void:
	var s := c.state
	if s.creature_db==null or not s.creature_db.available("hrut_warrior"):
		return
	var best: Variant=null
	var score := INF
	var grid := MoveGrid.new(s.board,null,s.figures)
	var node := MovePlanner.node_at(origin)
	for x in range(-8,9):
		for y in range(-8,9):
			var n := node+Vector2i(x,y)
			var d := MoveGrid.to_pos(n).distance_squared_to(origin)
			if d<score and grid.open(n):
				best=n
				score=d
	if best!=null:
		c._encounters._spawn_at("hrut_warrior",MoveGrid.to_pos(best))


## Called by forced movement, not by voluntary route planning.
static func forced_void(c: GameController,f: Figure,dest: Vector2,last_safe: Vector2) -> bool:
	var s := c.state
	if not active(s) or not f.in_play() or not s.board.over_void(dest,Figure.BASE_RADIUS):
		return false
	var raw := c.dice.d20()
	var success := StatRoll.succeeds(raw,f.effective_move()+MagicEquipment.bonus(f,"move_test")+f.roll_penalty(),16)
	c.emit("bridge_void",{"id":f.id,"roll":raw,"success":success})
	if not success:
		c._hurt(f,f.health,f,false)
	elif not last_safe.is_equal_approx(f.pos):
		var old := f.pos
		f.pos=last_safe
		f.elevation=s.board.height_at(last_safe)
		c.emit("forced_relocation",{"id":f.id,"from":old,"at":f.pos,"height":f.elevation})
	return true


static func exit_xp(s: GameState,side: int) -> int:
	var xp := 0
	for f in s.figures:
		if f.original_side==side and f.exited:
			xp+=50 if f.def.role=="wizard" else (30 if f.def.role=="apprentice" else 20)
	return xp


static func crosses_void(board: Board,a: Vector2,b: Vector2) -> bool:
	if board.void_regions.is_empty():
		return false
	var steps := maxi(1,ceili(a.distance_to(b)/0.2))
	for i in range(steps+1):
		if board.over_void(a.lerp(b,float(i)/steps),Figure.BASE_RADIUS):
			return true
	return false
