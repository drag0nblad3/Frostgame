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


## Canonical figure-to-figure sight. A geometry provider supplies the physical obstruction test.
static func check_figures(board: Board,from: Figure,to: Figure) -> Result:
	if from.ring_side!=to.ring_side:
		var blocked := Result.new()
		blocked.clear=false
		return blocked
	if board.floor_layout.is_empty():
		return check(board,from.pos,to.pos,from)
	var result := Result.new()
	var layout := board.floor_geometry()
	result.clear = not from.surface_id.is_empty() and not to.surface_id.is_empty() and floor_ray(board,layout,Vector3(from.pos.x,from.elevation+1.5,from.pos.y),Vector3(to.pos.x,to.elevation+1.0,to.pos.y),from,false)
	if board.darkness and Shooting.distance(from,to)>12.0:
		result.clear=false
	return result


## Floor geometry ray, shared by attacks and all explicit floor-targeted
## magic. It includes authored boundaries and magical darkness.
static func floor_ray(board: Board,layout: FloorLayout,a: Vector3,b: Vector3,observer: Figure=null,apply_darkness: bool=true) -> bool:
	if not layout.errors.is_empty() or BattleBoundary.blocks_segment(board.boundaries,Vector2(a.x,a.z),Vector2(b.x,b.z),"sight",observer):
		return false
	if apply_darkness and board.darkness and a.distance_to(b)>12.0:
		return false
	return LayeredSight.clear(layout,a,b)


static func floor_point_visible(board: Board,layout: FloorLayout,f: Figure,at: Vector3,limit: float=24.0) -> bool:
	var start:=Vector3(f.pos.x,f.elevation,f.pos.y)
	return start.distance_to(at)<=limit+0.001 and floor_ray(board,layout,start+Vector3.UP*1.5,at+Vector3.UP*0.02,f)


## Spells that use centre range (not weapon base-edge range) use actual
## figure elevations even when two figures share the same horizontal point.
static func within_centres(board: Board,from: Figure,to: Figure,limit: float=24.0) -> bool:
	return Vector2(from.pos.distance_to(to.pos),from.elevation-to.elevation).length()<=limit+0.001 and check_figures(board,from,to).clear


static func spell_visible(board: Board,from: Figure,to: Figure,limit: float=24.0) -> bool:
	if from.ring_side!=to.ring_side:
		return false
	if board.floor_layout.is_empty():
		return WizardEye.visible(board,from,to.pos,limit)
	return within_centres(board,from,to,limit)


static func check(board: Board, from: Vector2, to: Vector2,observer: Figure=null) -> Result:
	var special: Variant = RuleHooks.first("sight", [board, from, to, observer])
	if special != null:
		return special
	return plain_check(board,from,to,observer)


static func plain_check(board: Board,from: Vector2,to: Vector2,observer: Figure=null,ignore: TerrainPiece=null) -> Result:
	var r := Result.new()
	if board.ringworld and (observer==null or observer.ring_side==0) and from.distance_to(to)>18.0:
		r.clear=false
		return r
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
		if piece==ignore:
			r.intervening+=1
			continue
		if piece.kind.ground_surface:
			continue
		if piece.kind.id in ["red_king_portal","red_king_sinkhole_orb","reality_portal","reality_hoof"]:
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
	if board.ground_max<=minf(a,b)+0.001:
		return false
	var steps := maxi(1,ceili(from.distance_to(to)/0.10))
	for i in range(1,steps):
		var t := float(i)/steps
		if board.ground_height_at(from.lerp(to,t))>lerpf(a,b,t)+0.001:
			return true
	return false
