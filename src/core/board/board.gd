class_name Board
extends RefCounted
## The table: size in inches plus terrain pieces. Origin is the bottom-left corner.

var id := ""
var name := ""
var darkness := false
var size := Vector2(36, 36)
var pieces: Array[TerrainPiece] = []
## Authored experimental floor data. Legacy maps leave this empty.
var floor_layout := {}
## Serialized rule boundaries; ordinary battlefields have none.
var boundaries: Array[Dictionary]=[]
## Directed links between edge segments and their destination centers.
var edge_links: Array[Dictionary]=[]
var wrap_short_edges := false
var wrap_long_edges := false
var reality_sphere := false
var reality_cross := -1
var ringworld := false
var low_gravity := false
## Regions with no traversable surface at any elevation.
var void_regions: Array[Rect2]=[]


func over_void(at: Vector2,radius: float=0.0) -> bool:
	for region in void_regions:
		if region.has_point(at) or (radius>0.0 and Geom.point_rect_distance(at,region)<radius-0.001):
			return true
	return false


func contains(p: Vector2, margin: float = 0.0) -> bool:
	return p.x >= margin and p.y >= margin and p.x <= size.x - margin and p.y <= size.y - margin


## Pieces whose footprint contains `p`.
func pieces_at(p: Vector2) -> Array[TerrainPiece]:
	var out: Array[TerrainPiece] = []
	for piece in pieces:
		if piece.contains(p):
			out.append(piece)
	return out


## Movement cost multiplier at a point (the worst piece there).
func move_mult_at(p: Vector2) -> float:
	var key: Variant = _key(p)
	if key != null and _mult_cache.has(key):
		return _mult_cache[key]
	var m := 1.0
	for piece in pieces_at(p):
		m = maxf(m, piece.kind.move_mult)
	if key != null:
		_mult_cache[key] = m
	return m


## True if a figure with this base radius can stand at `p`.
func can_stand(p: Vector2, radius: float) -> bool:
	var key: Variant = _key(p) if is_equal_approx(radius, Figure.BASE_RADIUS) else null
	if key != null and _stand_cache.has(key):
		return _stand_cache[key]
	var ok := _can_stand(p, radius)
	if key != null:
		_stand_cache[key] = ok
	return ok


## Terrain never moves, so answers on the quarter-inch lattice (where move
## searches look) are cached. Off-lattice points are computed each time.
var _stand_cache := {}
var _mult_cache := {}
var _height_cache := {}
var static_step_cache := {}
## Bot distance fields by target node (see MovePlanner.distance_field).
var field_cache := {}
var has_ground_profiles := false
var has_ramps := false


func _key(p: Vector2) -> Variant:
	var q := p * 4.0
	if is_equal_approx(q.x, roundf(q.x)) and is_equal_approx(q.y, roundf(q.y)):
		return Vector2i(roundi(q.x), roundi(q.y))
	return null


func _can_stand(p: Vector2, radius: float) -> bool:
	if not contains(p, radius) or over_void(p,radius):
		return false
	for piece in pieces:
		if piece.kind.id in ["red_king_sinkhole_orb","reality_portal","reality_hoof"]:
			if p.distance_to(piece.rect.get_center())<piece.rect.size.x*0.5+radius-0.001:
				return false
			continue
		if piece.kind.id == "temple_column":
			# Contact must be legal on every face; Rect2.has_point includes
			# the minimum boundary but excludes the maximum boundary.
			var nearest := Vector2(clampf(p.x, piece.rect.position.x, piece.rect.end.x), clampf(p.y, piece.rect.position.y, piece.rect.end.y))
			if p.distance_to(nearest) < radius - 0.001:
				return false
			continue
		if piece.kind.blocks_move and not piece.kind.walkable_top and piece.rect.grow(radius).has_point(p):
			var over := false
			for bridge in pieces_at(p):
				if bridge.ramp and bridge.surface_height(p) >= piece.kind.height:
					over = true
					break
			if not over:
				return false
	return true


## Ground profiles replace the zero plane; elevated decks can sit above them.
func ground_piece_at(p: Vector2) -> TerrainPiece:
	for i in range(pieces.size()-1,-1,-1):
		var piece := pieces[i]
		if piece.kind.ground_surface and piece.contains(p):
			return piece
	return null


func ground_height_at(p: Vector2) -> float:
	var piece := ground_piece_at(p)
	return piece.surface_height(p) if piece != null else 0.0


func surface_at(p: Vector2) -> TerrainPiece:
	var top: TerrainPiece
	var height := 0.0
	if has_ground_profiles:
		top = ground_piece_at(p)
		if top != null:
			height = top.surface_height(p)
	for piece in pieces_at(p):
		if piece.kind.walkable_top and not piece.kind.ground_surface and piece.surface_height(p) > height:
			top = piece
			height = piece.surface_height(p)
	return top


func height_at(p: Vector2) -> float:
	var key: Variant=_key(p)
	if key!=null and _height_cache.has(key):
		return _height_cache[key]
	var piece := surface_at(p)
	var height := piece.surface_height(p) if piece!=null else 0.0
	if key!=null:
		_height_cache[key]=height
	return height


func climb_cost(a: Vector2, b: Vector2, climber: Figure = null) -> float:
	var delta := absf(height_at(a) - height_at(b))
	if delta < 0.001:
		return 0.0
	var multiplier := 2.0
	if climber != null and (climber.def.traits.has("expert_climber") or climber.levitates()):
		multiplier = 1.0
	for p in pieces_at(a) + pieces_at(b):
		if p.kind.stairs:
			multiplier = 1.0
	return ceilf(delta) * multiplier


func invalidate_terrain() -> void:
	has_ground_profiles = false
	has_ramps = false
	for piece in pieces:
		has_ground_profiles = has_ground_profiles or piece.kind.ground_surface
		has_ramps = has_ramps or piece.ramp
	_stand_cache.clear()
	_mult_cache.clear()
	_height_cache.clear()
	static_step_cache.clear()
	field_cache.clear()


func set_boundaries(lines: Array[Dictionary]) -> void:
	boundaries.assign(lines.duplicate(true))
	invalidate_terrain()
