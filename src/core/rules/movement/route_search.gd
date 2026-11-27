class_name RouteSearch
extends RefCounted
## One shortest-route search for every battlefield and bot distance field.
## Geometry providers supply legal edges. Keep the typed flat inner loop to
## avoid allocating thousands of small edge dictionaries on mobile devices.
const NO_LINKS: Array[Vector2i]=[]


static func expand(flat: MoveGrid,floors: LayeredGrid,heap: MinHeap,cost: Dictionary,prev: Dictionary,allowance: float,stop_on_contact: bool,leave_start: Variant,record_path: bool,topology: int=0,reverse_cost: bool=false) -> void:
	while not heap.is_empty():
		var item:=heap.pop()
		var distance: float=item[0]
		var node: Variant=item[1]
		if distance>cost.get(node,INF):
			continue
		if floors!=null:
			var n: Vector3i=node
			if stop_on_contact and n!=leave_start and floors.stops(n):
				continue
			for edge in floors.neighbors(n):
				var next: Vector3i=edge["to"]
				var total: float=distance+edge["cost"]
				if total<=allowance+0.001 and total<cost.get(next,INF):
					cost[next]=total
					if record_path:
						prev[next]=n
					heap.push(total,next)
			continue
		var n: Vector2i=node
		if stop_on_contact and n!=leave_start and flat.stops(n):
			continue
		for direction: Vector2i in MoveGrid.NEIGHBORS:
			var next:=n+direction
			if not flat.open(next):
				continue
			var total:=distance+(flat.step_cost(next,n) if reverse_cost else flat.step_cost(n,next))
			if total<=allowance+0.001 and total<cost.get(next,INF):
				cost[next]=total
				if record_path:
					prev[next]=n
				heap.push(total,next)
		var links:=NO_LINKS
		if topology==1:
			links=BoardTopology.destinations(flat.board,n)
		elif topology==2:
			links=BoardTopology.sources(flat.board,n)
		for next in links:
			var total:=distance+Figure.BASE_RADIUS
			if flat.open(next) and total<=allowance+0.001 and total<cost.get(next,INF):
				cost[next]=total
				if record_path:
					prev[next]=n
				heap.push(total,next)
