class_name MovePlanner
extends RefCounted
## Dijkstra over the MoveGrid: everywhere a figure can get to with `allowance`
## inches of movement, and distance fields for the bot.


static func reach(grid: MoveGrid, from: Vector2, allowance: float) -> MoveReach:
	var r := MoveReach.new()
	r.start = from
	var heap := MinHeap.new()
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
	while not heap.is_empty():
		var top := heap.pop()
		var c: float = top[0]
		var n: Vector2i = top[1]
		if c > r.cost.get(n, INF) or grid.stops(n):
			continue
		for d: Vector2i in MoveGrid.NEIGHBORS:
			var m := n + d
			if not grid.open(m):
				continue
			var nc := c + grid.step_cost(n, m)
			if nc <= allowance + 0.001 and nc < r.cost.get(m, INF):
				r.cost[m] = nc
				r.prev[m] = n
				heap.push(nc, m)
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
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var n := base + Vector2i(dx, dy)
			if grid.open(n):
				var c := target.distance_to(MoveGrid.to_pos(n))
				field[n] = c
				heap.push(c, n)
	while not heap.is_empty():
		var top := heap.pop()
		var c: float = top[0]
		var n: Vector2i = top[1]
		if c > field.get(n, INF):
			continue
		for d: Vector2i in MoveGrid.NEIGHBORS:
			var m := n + d
			if not grid.open(m):
				continue
			var nc := c + grid.step_cost(n, m)
			if nc < field.get(m, INF):
				field[m] = nc
				heap.push(nc, m)
	return field


## Nearest grid node to a point.
static func node_at(p: Vector2) -> Vector2i:
	return Vector2i(roundi(p.x / MoveGrid.STEP), roundi(p.y / MoveGrid.STEP))
