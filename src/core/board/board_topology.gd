class_name BoardTopology
extends RefCounted
## Directed, costed edge connections. Sight is deliberately independent.
## Source ranges are half-open; arriving figures appear at destination centers.
static func mobius(size: Vector2,priority: int) -> Array[Dictionary]:
	var links: Array[Dictionary]=[]
	var width := size.x/3.0
	for strip in 3:
		var next := (strip+1)%3
		var previous := (strip+2)%3
		# The priority side determines which end is numbered odd.
		var odd_y := Figure.BASE_RADIUS if priority==0 else size.y-Figure.BASE_RADIUS
		var even_y := size.y-odd_y
		var direction := 1 if priority==0 else -1
		var next_strip := next if direction==1 else previous
		var previous_strip := previous if direction==1 else next
		links.append({"y":even_y,"min_x":strip*width,"max_x":(strip+1)*width,"to":Vector2((next_strip+0.5)*width,odd_y)})
		links.append({"y":odd_y,"min_x":strip*width,"max_x":(strip+1)*width,"to":Vector2((previous_strip+0.5)*width,even_y)})
	return links


## True when the board has wrapped edges or edge links (most boards don't).
static func linked(board: Board) -> bool:
	return board.wrap_short_edges or board.wrap_long_edges or not board.edge_links.is_empty()


static func destinations(board: Board,node: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i]=[]
	var at := MoveGrid.to_pos(node)
	if board.wrap_short_edges:
		if is_equal_approx(at.y,Figure.BASE_RADIUS):
			out.append(MovePlanner.node_at(Vector2(at.x,board.size.y-Figure.BASE_RADIUS)))
		elif is_equal_approx(at.y,board.size.y-Figure.BASE_RADIUS):
			out.append(MovePlanner.node_at(Vector2(at.x,Figure.BASE_RADIUS)))
	if board.wrap_long_edges:
		if is_equal_approx(at.x,Figure.BASE_RADIUS):
			out.append(MovePlanner.node_at(Vector2(board.size.x-Figure.BASE_RADIUS,at.y)))
		elif is_equal_approx(at.x,board.size.x-Figure.BASE_RADIUS):
			out.append(MovePlanner.node_at(Vector2(Figure.BASE_RADIUS,at.y)))
	if board.edge_links.is_empty():
		return out
	for link in board.edge_links:
		if is_equal_approx(at.y,float(link["y"])) and at.x>=float(link["min_x"]) and at.x<float(link["max_x"]):
			out.append(MovePlanner.node_at(link["to"]))
	return out


static func sources(board: Board,node: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i]=[]
	if board.wrap_short_edges or board.wrap_long_edges:
		# Wrap pairs are bidirectional.
		out.append_array(destinations(board,node))
	if board.edge_links.is_empty():
		return out
	for link in board.edge_links:
		if MovePlanner.node_at(link["to"])!=node:
			continue
		for x in range(ceili(float(link["min_x"])/MoveGrid.STEP),ceili(float(link["max_x"])/MoveGrid.STEP)):
			out.append(Vector2i(x,roundi(float(link["y"])/MoveGrid.STEP)))
	return out


static func is_transfer(board: Board,a: Vector2,b: Vector2) -> bool:
	if (board.edge_links.is_empty() and not board.wrap_short_edges and not board.wrap_long_edges) or a.distance_to(b)<=MoveGrid.STEP*1.5:
		return false
	return destinations(board,MovePlanner.node_at(a)).has(MovePlanner.node_at(b))


## Convert authored edge transfers into floor nodes. Wrapped streets and
## decks preserve physical elevation; a transfer never climbs or drops.
static func floor_destinations(board: Board,layout: FloorLayout,n: Vector3i,reverse: bool=false) -> Array[Vector3i]:
	var out: Array[Vector3i]=[]
	var from:=Vector2i(n.x,n.y)
	if not linked(board) or not layout.standable(n):
		return out
	var options:=sources(board,from) if reverse else destinations(board,from)
	for point in options:
		var at:=MoveGrid.to_pos(point)
		for candidate in layout.nodes_at(at):
			if absf(layout.height(candidate)-layout.height(n))>=0.5 or layout.surface_id(candidate).begins_with("climb:"):
				continue
			out.append(candidate)
	return out
