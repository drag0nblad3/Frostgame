class_name LayeredReach
extends RefCounted
## Dijkstra over (x, y, surface index), never implicit vertical switching.
var start: Vector3i
var cost := {}
var prev := {}


static func search(grid: LayeredGrid,from: Vector3i,allowance: float) -> LayeredReach:
	var r := LayeredReach.new()
	r.start=from
	if not grid.open(from):
		return r
	r.cost[from]=0.0
	var heap := MinHeap.new()
	heap.push(0.0,from)
	while not heap.is_empty():
		var item := heap.pop()
		var n: Vector3i = item[1]
		var distance: float = item[0]
		if distance>r.cost.get(n,INF) or grid.stops(n):
			continue
		for edge in grid.neighbors(n):
			var next: Vector3i = edge["to"]
			var total: float = distance+edge["cost"]
			if total<=allowance+0.001 and total<r.cost.get(next,INF):
				r.cost[next]=total
				r.prev[next]=n
				heap.push(total,next)
	return r


func can_reach(n: Vector3i) -> bool:
	return cost.has(n)


func path_to(n: Vector3i) -> Array[Vector3i]:
	var path: Array[Vector3i] = []
	if not can_reach(n):
		return path
	var current := n
	while current!=start:
		path.append(current)
		current=prev[current]
	path.append(start)
	path.reverse()
	return path
