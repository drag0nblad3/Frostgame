class_name LayeredReach
extends RefCounted
## Dijkstra over (x, y, surface index), never implicit vertical switching.
var start: Vector3i
var cost := {}
var prev := {}
var air_paths: Dictionary={}
var truncated:=false


static func search(grid: LayeredGrid,from: Vector3i,allowance: float,leave_contact: bool=false,max_expansions: int=0) -> LayeredReach:
	var r := LayeredReach.new()
	r.start=from
	if not grid.open(from):
		return r
	r.cost[from]=0.0
	var heap := MinHeap.new()
	heap.push(0.0,from)
	r.truncated=RouteSearch.expand(null,grid,heap,r.cost,r.prev,allowance,true,from if leave_contact else null,true,0,false,max_expansions)
	if grid.board!=null and not grid.board.boundaries.is_empty():
		for n: Vector3i in r.cost.keys():
			if n!=from and BattleBoundary.blocks_end(grid.board.boundaries,grid.layout.point(n)):
				r.cost.erase(n)
	return r


func can_reach(n: Vector3i) -> bool:
	return cost.has(n)


func path_to(n: Vector3i) -> Array[Vector3i]:
	var path: Array[Vector3i] = []
	if not can_reach(n):
		return path
	if air_paths.has(n):
		return [start,n]
	var current := n
	while current!=start:
		path.append(current)
		current=prev[current]
	path.append(start)
	path.reverse()
	return path
