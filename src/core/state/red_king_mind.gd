class_name RedKingMind
extends RefCounted
## Solo mindscape, Red King pp.38–40. All deck state is checkpoint-safe.
const ID := "red_king_mind"
const CARDS := ["A","K","Q","J","10","9","8","7","6","5"]


static func active(s: GameState) -> bool:
	return s!=null and s.scenario_special==ID


static func wizard(s: GameState) -> Figure:
	for f in s.figures:
		if f.original_side==0 and f.def.role=="wizard":
			return f
	return null


static func is_wizard(s: GameState,f: Figure) -> bool:
	return active(s) and f!=null and f==wizard(s)


static func prepare(c: GameController) -> void:
	if active(c.state) and not c.state.scenario_data.has("mind_deck"):
		c.state.scenario_data["mind_deck"]=EventDeck.create(CARDS,c.dice)


static func activation(c: GameController,f: Figure) -> void:
	if is_wizard(c.state,f) and f.in_play() and f.actions_left>0:
		f.actions_left=3


static func collect(c: GameController,f: Figure,from: Vector2,to: Vector2) -> void:
	if not is_wizard(c.state,f) or not f.in_play():
		return
	for token in c.state.treasures:
		if token.on_ground() and token.pos.distance_to(Geometry2D.get_closest_point_to_segment(token.pos,from,to))<=Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS+0.01:
			c._loot.secure(token,0)
			c.emit("mind_memory",{"id":f.id,"treasure":token.id})


static func _corners(s: GameState) -> Array[Vector2]:
	return [Vector2(0.5,0.5),Vector2(s.board.size.x-0.5,0.5),Vector2(0.5,s.board.size.y-0.5),s.board.size-Vector2.ONE*0.5]


static func _spawn(c: GameController,corner: Vector2) -> void:
	var s := c.state
	if not s.creature_db.available("mindshrike"):
		return
	var grid := MoveGrid.new(s.board,null,s.figures)
	var best: Variant=null
	var distance := INF
	var center := MovePlanner.node_at(corner)
	for x in range(-6,7):
		for y in range(-6,7):
			var n := center+Vector2i(x,y)
			var d := MoveGrid.to_pos(n).distance_squared_to(corner)
			if d<distance and grid.open(n):
				best=n
				distance=d
	if best!=null:
		c._encounters._spawn_at("mindshrike",MoveGrid.to_pos(best))


static func _move_token(c: GameController,t: TreasureToken,at: Vector2) -> void:
	var margin := Vector2.ONE*TreasureRules.TOKEN_RADIUS
	t.pos=at.clamp(margin,c.state.board.size-margin)
	c.emit("treasure_moved",{"treasure":t.id,"at":t.pos})


static func end_turn(c: GameController) -> void:
	if not active(c.state):
		return
	var f := wizard(c.state)
	if f==null or not f.in_play():
		return
	prepare(c)
	var card: Variant=EventDeck.draw(c.state.scenario_data["mind_deck"])
	if card==null:
		return
	apply_card(c,str(card))


static func apply_card(c: GameController,card: String) -> void:
	var s := c.state
	var f := wizard(s)
	if f==null:
		return
	var corners := _corners(s)
	var tokens: Array[TreasureToken]=[]
	for t in s.treasures:
		if t.on_ground():
			tokens.append(t)
	tokens.sort_custom(func(a: TreasureToken,b: TreasureToken) -> bool:return a.pos.distance_squared_to(f.pos)<b.pos.distance_squared_to(f.pos))
	c.emit("mind_event",{"card":card})
	if card in ["A","K","Q","J"]:
		_spawn(c,corners[c.dice.pick(4)])
		if not tokens.is_empty():
			var t: TreasureToken=tokens[0] if card in ["A","K"] else tokens.back()
			_move_token(c,t,t.pos+RedKingDirection.direction(c)*6.0)
	elif card in ["10","9"]:
		var corner := corners[c.dice.pick(4)]
		_spawn(c,corner)
		_spawn(c,corner)
		for t in tokens:
			_move_token(c,t,t.pos+(t.pos-corners[0]).normalized()*3.0)
	elif card in ["8","7"]:
		var first := c.dice.pick(4)
		_spawn(c,corners[first])
		_spawn(c,corners[(first+1+c.dice.pick(3))%4])
		# Automated selection until the event-choice UI is implemented.
		if not tokens.is_empty():
			var t := tokens[0]
			_move_token(c,t,t.pos+(f.pos-t.pos).normalized()*minf(4.0,f.pos.distance_to(t.pos)))
	elif card in ["6","5"]:
		for i in range(1,4):
			_spawn(c,corners[i])
		for t in tokens:
			_move_token(c,t,t.pos+(t.pos-s.board.size*0.5).normalized()*(2.0 if card=="6" else -2.0))


static func finish(c: GameController) -> void:
	var s := c.state
	if s.scenario_data.has("mind_rewards"):
		return
	var deck := EventDeck.create(CARDS,c.dice)
	var rewards: Array[String]=[]
	for i in s.secured_count(0):
		var card: Variant=EventDeck.draw(deck)
		if card!=null:
			rewards.append(str(card))
	s.scenario_data["mind_rewards"]=rewards
	c.emit("mind_rewards",{"cards":rewards.duplicate()})
