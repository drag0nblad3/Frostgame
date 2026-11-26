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


static func check(board: Board, from: Vector2, to: Vector2) -> Result:
	var r := Result.new()
	for piece in board.pieces:
		if not Geom.crosses(from, to, piece.rect) and not piece.rect.has_point(to):
			continue
		var kind := piece.kind
		if kind.walkable_top or board.height_at(from) > 0.0 or board.height_at(to) > 0.0:
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
		if piece.rect.has_point(from.lerp(to, t)) and lerpf(a, b, t) <= piece.kind.height:
			return true
	return false
