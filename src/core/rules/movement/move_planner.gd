class_name MovePlanner
extends RefCounted
## Dijkstra over the MoveGrid: everywhere a figure can get to with `allowance`
## inches of movement, and distance fields for the bot.

static func reach(grid: MoveGrid, from: Vector2, allowance: float) -> MoveReach:
	var r := MoveReach.new()
	r.start = from
	var heap := MinHeap.new()
	var linked := BoardTopology.linked(grid.board)
	var base := Vector2i(floori(from.x / MoveGrid.STEP), floori(from.y / MoveGrid.STEP))
	for dx in range(-1, 3):
		for dy in range(-1, 3):
			var n := base + Vector2i(dx, dy)
			if not grid.open(n):
				continue
			var p := MoveGrid.to_pos(n)
			var c := grid.segment_cost(from, p)
			if c <= allowance and c < r.cost.get(n, INF):
				r.cost[n] = c
				r.prev[n] = null
				heap.push(c, n)
	RouteSearch.expand(grid,null,heap,r.cost,r.prev,allowance,true,null,true,1 if linked else 0)
	for node: Vector2i in r.nodes():
		if BattleBoundary.blocks_end(grid.board.boundaries,MoveGrid.to_pos(node)):
			r.cost.erase(node)
	return r


## Movement distance from `target` to every node, ignoring figures. Nodes
## inside blocking terrain next to the target still get seeded so a figure
## standing against a wall has a field.
static func distance_field(board: Board, target: Vector2) -> Dictionary:
	var base := node_at(target)
	if board.field_cache.has(base):
		return board.field_cache[base]
	if board.field_cache.size() > 64:
		board.field_cache.clear()
	var grid := MoveGrid.new(board)
	var field := {}
	board.field_cache[base] = field
	var heap := MinHeap.new()
	var linked := BoardTopology.linked(board)
	# A free target seeds its own tile. Only inaccessible objectives
	# (guardian columns, for example) need nearby edge seeds.
	if grid.open(base):
		field[base] = target.distance_to(MoveGrid.to_pos(base))
		heap.push(field[base], base)
	else:
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var n := base + Vector2i(dx, dy)
				if grid.open(n):
					var c := target.distance_to(MoveGrid.to_pos(n))
					field[n] = c
					heap.push(c, n)
	RouteSearch.expand(grid,null,heap,field,{},INF,false,null,false,2 if linked else 0)
	return field


## Nearest grid node to a point.
static func node_at(p: Vector2) -> Vector2i:
	return Vector2i(roundi(p.x / MoveGrid.STEP), roundi(p.y / MoveGrid.STEP))



## Multi-source exit field avoids getting trapped against a wall near the table edge.
static func exit_field(s: GameState,side: int=-1) -> Dictionary:
	var key := "exit:" + s.scenario_special+":"+str(side)
	if s.board.field_cache.has(key):
		return s.board.field_cache[key]
	var grid := MoveGrid.new(s.board)
	var heap := MinHeap.new()
	var field := {}
	s.board.field_cache[key] = field
	for x in grid.cols:
		for y in grid.rows:
			var node := Vector2i(x, y)
			var at := MoveGrid.to_pos(node)
			if TreasureRules.edge_distance(s.board, at) > Figure.BASE_RADIUS + 0.01 or not ScenarioObjectives.exit_allowed(s, at,side) or not grid.open(node):
				continue
			field[node] = 0.0
			heap.push(0.0, node)
	RouteSearch.expand(grid,null,heap,field,{},INF,false,null,false,0,true)
	return field


## Low gravity allows a single straight route rather than cornering.
static func straight_reach(grid: MoveGrid,from: Vector2,allowance: float) -> MoveReach:
	var r := MoveReach.new()
	r.start=from
	var base := node_at(from)
	var radius := ceili(allowance/MoveGrid.STEP)
	for dx in range(-radius,radius+1):
		for dy in range(-radius,radius+1):
			var n := base+Vector2i(dx,dy)
			var at := MoveGrid.to_pos(n)
			var cost := from.distance_to(at)
			if cost>allowance+0.001 or not grid.open(n):
				continue
			var clear := true
			var steps := maxi(1,ceili(cost/0.25))
			var last := from
			for i in range(1,steps+1):
				var p := from.lerp(at,float(i)/steps)
				if not is_finite(grid.segment_cost(last,p)):
					clear=false
					break
				for other in grid.others:
					if absf(other.elevation-grid.board.height_at(p))>=0.5:
						continue
					var d := other.pos.distance_to(p)
					if d<Contact.OVERLAP or (i<steps and grid.mover!=null and other.side!=grid.mover.side and d<Contact.CONTACT and other.pos.distance_to(at)>Contact.CONTACT):
						clear=false
						break
				if not clear:
					break
				last=p
			if clear:
				r.cost[n]=cost
				r.prev[n]=null
	return r
