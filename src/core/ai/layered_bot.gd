class_name LayeredBot
extends RefCounted
## Goal-directed navigation for the isolated gatehouse demonstration.


static func best_step(layout: FloorLayout,reachable: LayeredReach,target: Vector3i,grid: LayeredGrid) -> Variant:
	# Reverse distance search. Authored directed links are respected.
	if not grid.open(target):
		return null
	var distance := {target:0.0}
	var heap := MinHeap.new()
	heap.push(0.0,target)
	var reverse := {}
	for from: Vector3i in layout.links:
		for edge: Dictionary in layout.links[from]:
			var to: Vector3i = edge["to"]
			if not reverse.has(to):
				reverse[to]=[]
			reverse[to].append({"to":from,"cost":edge["cost"]})
	while not heap.is_empty():
		var item := heap.pop()
		var n: Vector3i = item[1]
		var cost: float = item[0]
		if cost>distance.get(n,INF):
			continue
		var previous: Array[Dictionary] = []
		for d: Vector2i in MoveGrid.NEIGHBORS:
			var p := n+Vector3i(d.x,d.y,0)
			if not grid.open(p):
				continue
			for edge: Dictionary in grid.neighbors(p):
				if edge["to"]==n:
					previous.append({"to":p,"cost":edge["cost"]})
					break
		for edge: Dictionary in reverse.get(n,[]):
			if grid.open(edge["to"]):
				previous.append(edge)
		for edge: Dictionary in previous:
			var p: Vector3i = edge["to"]
			var total: float = cost+edge["cost"]
			if total<distance.get(p,INF):
				distance[p]=total
				heap.push(total,p)
	var best: Variant = null
	var score: float = distance.get(reachable.start,INF)
	for n: Vector3i in reachable.cost:
		if n==reachable.start:
			continue
		var candidate: float = distance.get(n,INF)
		if candidate<score-0.001:
			best=n
			score=candidate
	return best
