class_name LineOfSight
extends RefCounted
## Line of sight and cover between two points on the table, centre to centre.
## TODO(rules): 2e lets a shot see any part of the target; we trace centre to centre only.
## TODO(rules): figures do not block line of sight yet.

## A cover piece this close to the target (inches from its footprint) gives
## cover; further away it counts as intervening terrain.
const COVER_REACH := 1.0


class Result:
	var clear := true
	## Best cover at the target (TerrainKind.Cover).
	var cover := 0
	## Pieces of terrain crossed away from the target.
	var intervening := 0


## The layered fixture uses physical floor volumes instead of a highest-surface ray.
static func check_figures(board: Board,from: Figure,to: Figure) -> Result:
	if board.floor_layout.is_empty():
		return check(board,from.pos,to.pos,from)
	var result := Result.new()
	var layout := FloorLayout.from_dict(board.floor_layout)
	result.clear = layout.errors.is_empty() and LayeredSight.figures_clear(layout,from,to)
	if board.darkness and Shooting.distance(from,to)>12.0:
		result.clear=false
	return result


static func check(board: Board, from: Vector2, to: Vector2,observer: Figure=null) -> Result:
	var r := Result.new()
	if BattleBoundary.blocks_segment(board.boundaries,from,to,"sight",observer):
		r.clear=false
		return r
	if board.darkness and Vector2(from.distance_to(to), board.height_at(from) - board.height_at(to)).length() > 12.0:
		r.clear = false
		return r
	if board.has_ground_profiles and _ray_hits_ground(board,from,to):
		r.clear = false
		return r
	for piece in board.pieces:
		if piece.kind.ground_surface:
			continue
		if piece.kind.id in ["red_king_portal","red_king_sinkhole_orb"]:
			var center := piece.rect.get_center()
			if center.distance_to(Geometry2D.get_closest_point_to_segment(center,from,to))<=piece.rect.size.x*0.5:
				r.clear=false
				return r
			continue
		if not Geom.crosses(from, to, piece.rect) and not piece.rect.has_point(to):
			continue
		var kind := piece.kind
		if kind.walkable_top or absf(board.height_at(from)) > 0.001 or absf(board.height_at(to)) > 0.001:
			if not _ray_hits_piece(board, from, to, piece):
				continue
		if kind.blocks_los:
			r.clear = false
			return r
		if kind.cover == TerrainKind.Cover.NONE:
			continue
		var near_target := Geom.point_rect_distance(to, piece.rect) <= COVER_REACH
		var near_shooter := Geom.point_rect_distance(from, piece.rect) <= COVER_REACH
		if near_target:
			r.cover = maxi(r.cover, kind.cover)
		elif not near_shooter:
			r.intervening += 1
	return r


## Sample the centre ray from figure eye height to target torso height.
static func _ray_hits_piece(board: Board, from: Vector2, to: Vector2, piece: TerrainPiece) -> bool:
	var a := board.height_at(from) + 1.5
	var b := board.height_at(to) + 1.0
	var steps := maxi(1, ceili(from.distance_to(to) / 0.15))
	for i in range(steps + 1):
		var t := float(i) / steps
		var point := from.lerp(to,t)
		if piece.contains(point) and lerpf(a,b,t) <= piece.surface_height(point):
			return true
	return false


static func _ray_hits_ground(board: Board,from: Vector2,to: Vector2) -> bool:
	var a := board.height_at(from)+1.5
	var b := board.height_at(to)+1.0
	var steps := maxi(1,ceili(from.distance_to(to)/0.10))
	for i in range(1,steps):
		var t := float(i)/steps
		if board.ground_height_at(from.lerp(to,t))>lerpf(a,b,t)+0.001:
			return true
	return false
