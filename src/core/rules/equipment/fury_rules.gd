class_name FuryRules
extends RefCounted


static func target(s: GameState, f: Figure) -> Figure:
	if f == null or not f.in_play() or not f.spell_effects.has("potion_fury"):
		return null
	var enemies := Contact.enemies_of(s.figures, f)
	if not enemies.is_empty():
		return enemies[0]
	var best: Figure = null
	for t in s.figures:
		if t.side == f.side or not t.in_play() or Contact.in_combat(s.figures, t) or BeautyActions.blocked(s, f, t) or not IllusionRules.visible_to(s.figures, f, t) or not LineOfSight.check_figures(s.board,f,t).clear:
			continue
		if best == null or Shooting.distance(f, t) < Shooting.distance(f, best):
			best = t
	return best


static func restrict(s: GameState, f: Figure, r: MoveReach) -> MoveReach:
	var enemy := target(s, f)
	if enemy == null:
		return r
	var contact: Array[Vector2i] = []
	var advance: Array[Vector2i] = []
	var field := MovePlanner.distance_field(s.board, enemy.pos)
	var start: float = field.get(MovePlanner.node_at(f.pos), INF)
	for n: Vector2i in r.nodes():
		var at := MoveGrid.to_pos(n)
		if float(r.cost[n]) < 0.001:
			continue
		if absf(s.board.height_at(at) - enemy.elevation) < 0.5 and Contact.touching(at, enemy.pos):
			contact.append(n)
		elif float(field.get(n, INF)) < start - 0.01:
			advance.append(n)
	var legal := contact if not contact.is_empty() else advance
	# Keep predecessor links, since a legal route may cross unselectable nodes.
	for n: Vector2i in r.nodes():
		if not legal.has(n):
			r.cost.erase(n)
	return r


## Distance to a legal enemy contact through actual connected floors.
## Ignore occupants in the long-range field as on exposed terrain, but
## choose only endpoints from the actual occupied-figure reach.
static func floor_field(s: GameState,f: Figure,enemy: Figure) -> Dictionary:
	var layout:=s.board.floor_geometry()
	var grid:=LayeredGrid.new(layout,f)
	grid.board=s.board
	grid.reverse_connections()
	var cost: Dictionary={}
	var heap:=MinHeap.new()
	for n in BattlePlacement.nodes(s.board,enemy.pos,1.5):
		if not grid.open(n) or not Contact.touches_position(enemy,layout.point(n),layout.height(n),layout.surface_id(n)) or layout.point(n).distance_to(enemy.pos)<Contact.OVERLAP:
			continue
		cost[n]=0.0
		heap.push(0.0,n)
	RouteSearch.expand(null,grid,heap,cost,{},s.board.size.length()*4.0,false,null,false)
	return cost


static func restrict_floor(s: GameState,f: Figure,r: LayeredReach) -> LayeredReach:
	var enemy:=target(s,f)
	if enemy==null or r.cost.is_empty():
		return r
	var layout:=s.board.floor_geometry()
	var contact: Array[Vector3i]=[]
	for n: Vector3i in r.cost:
		if n!=r.start and Contact.touches_position(enemy,layout.point(n),layout.height(n),layout.surface_id(n)):
			contact.append(n)
	var legal:=contact
	if legal.is_empty():
		var field:=floor_field(s,f,enemy)
		var start: float=field.get(r.start,INF)
		for n: Vector3i in r.cost:
			if n!=r.start and float(field.get(n,INF))<start-0.01:
				legal.append(n)
	for n in r.cost.keys():
		if not legal.has(n):
			r.cost.erase(n)
	return r


static func play(c: GameController, f: Figure) -> void:
	for i in 3:
		if c.awaiting_reaction() or not f.in_play() or f.actions_left <= 0:
			return
		for t in Contact.enemies_of(c.state.figures, f):
			if c.can_fight(t.id):
				c.fight(t.id)
				break
		if c.awaiting_reaction() or not f.in_play() or f.actions_left <= 0:
			return
		if not c.can_move():
			return
		var enemy := target(c.state, f)
		if enemy == null:
			return
		if not c.state.board.floor_layout.is_empty():
			var reach:=c.layered_reach()
			var field:=floor_field(c.state,f,enemy)
			var node: Variant=null
			var score:=INF
			for n: Vector3i in reach.cost:
				var distance: float=field.get(n,INF)
				if distance<score:
					score=distance
					node=n
			if node==null or not c.move_on_floor(node):
				return
			continue
		var r := c.reach()
		var best: Variant = null
		var score := INF
		for n: Vector2i in r.nodes():
			var distance := MoveGrid.to_pos(n).distance_to(enemy.pos)
			if distance < score:
				best = n
				score = distance
		if best == null or not c.move_to(best):
			return
