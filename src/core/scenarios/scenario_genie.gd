class_name ScenarioGenie
extends RefCounted
## A unique wandering demon tied to the first discovery of its lamp (p. 149).


static func first_pickup(c: GameController, finder: Figure, token: TreasureToken) -> void:
	var s := c.state
	if s.scenario_special != "genie_in_the_bottle" or s.lamp_token >= 0 or s.creature_db == null:
		return
	var collected := 0
	for t in s.treasures:
		if t.ever_collected:
			collected += 1
	if collected < s.treasures.size() and c.dice.d20() < 15:
		return
	var origin:=Vector3(finder.pos.x,finder.elevation,finder.pos.y)
	if not s.board.floor_layout.is_empty():
		var layout:=s.board.floor_geometry()
		var best: Variant=null
		var score:=INF
		for n in BattlePlacement.nodes(s.board,finder.pos,2.0):
			if not BattlePlacement.floor_open(s,n):
				continue
			var at:=layout.world(n)
			if not legal_spawn(s,finder,at):
				continue
			var value:=absf(origin.distance_to(at)-1.75)
			if value<score:
				score=value
				best=n
		if best!=null:
			_released(c,finder,token,c._encounters._spawn_on_floor("genie",best))
		else:
			c.emit("genie_spawn_blocked",{"treasure":token.id,"id":finder.id})
		return
	var grid := MoveGrid.new(s.board,null,s.figures)
	var center := MovePlanner.node_at(finder.pos)
	var best_at:=Vector2.INF
	var score:=INF
	for dx in range(-4,5):
		for dy in range(-4,5):
			var node:=center+Vector2i(dx,dy)
			if not grid.open(node):
				continue
			var at:=MoveGrid.to_pos(node)
			var point:=Vector3(at.x,s.board.height_at(at),at.y)
			if not legal_spawn(s,finder,point):
				continue
			var value:=absf(origin.distance_to(point)-1.75)
			if value<score:
				best_at=at
				score=value
	if is_finite(best_at.x):
		_released(c,finder,token,c._encounters._spawn_at("genie",best_at))
	else:
		c.emit("genie_spawn_blocked",{"treasure":token.id,"id":finder.id})


static func legal_spawn(s: GameState,finder: Figure,at: Vector3) -> bool:
	var distance:=at.distance_to(Vector3(finder.pos.x,finder.elevation,finder.pos.y))
	if distance>2.0 or distance<Contact.OVERLAP:
		return false
	for other in s.figures:
		if other!=finder and other.in_play() and at.distance_to(Vector3(other.pos.x,other.elevation,other.pos.y))<=distance:
			return false
	return true


static func _released(c: GameController,finder: Figure,token: TreasureToken,creature: Figure) -> void:
	c.state.lamp_token=token.id
	c.state.genie_id=creature.id
	c.emit("genie_released",{"id":creature.id,"side":finder.side,"treasure":token.id,"xp":30})


static func record_kill(c: GameController, victim: Figure, by: Figure) -> void:
	var s := c.state
	if s.scenario_special != "genie_in_the_bottle" or by.id != s.genie_id or victim == by or victim.original_side < 0:
		return
	s.genie_kills += 1
	if s.genie_kills == 3:
		c.emit("genie_flee", {"id": by.id})


static func flee(c: GameController, f: Figure) -> bool:
	var s := c.state
	if f.id != s.genie_id or s.genie_kills < 3 or f.side >= 0:
		return false
	if Contact.in_combat(s.figures, f):
		return false
	if not s.board.floor_layout.is_empty():
		if f.moves_taken==0 and c.can_move():
			LayeredLoot.advance_to_exit(c,f)
		if c.awaiting_reaction() or not f.in_play():
			return true
		if Contact.in_combat(s.figures,f):
			return false
		var layout:=s.board.floor_geometry()
		if LayeredLoot.is_exit(s,layout,layout.node(f.surface_id,f.pos),f.side):
			f.exited=true
			f.actions_left=0
			c.emit("exit",{"id":f.id})
			c.emit("genie_escaped",{"id":f.id})
			return true
		var enemy:=CreatureBot.closest(c,f,true)
		if enemy!=null:
			c.shoot(enemy.id)
		return true
	if f.moves_taken == 0 and c.can_move():
		var r := c.reach()
		var best := Vector2i(-1, -1)
		var field := MovePlanner.exit_field(s)
		var distance: float = field.get(MovePlanner.node_at(f.pos), INF)
		for n in r.nodes():
			var d: float = field.get(n, INF)
			if d < distance:
				distance = d
				best = n
		if best.x >= 0:
			c.move_to(best)
			if c.awaiting_reaction() or not f.in_play():
				return true
	if Contact.in_combat(s.figures, f):
		return false
	if TreasureRules.edge_distance(s.board, f.pos) <= Figure.BASE_RADIUS + 0.01 and f.elevation < 0.5:
		f.exited = true
		f.actions_left = 0
		c.emit("exit", {"id": f.id})
		c.emit("genie_escaped", {"id": f.id})
		return true
	var target: Figure = null
	for t in s.figures:
		if t.side >= 0 and c.can_shoot(t.id) and (target == null or Shooting.distance(f, t) < Shooting.distance(f, target)):
			target = t
	if target != null:
		c.shoot(target.id)
	return true
