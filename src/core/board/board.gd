class_name Board
extends RefCounted
## The table: size in inches plus terrain pieces. Origin is the bottom-left corner.

var id := ""
var name := ""
var darkness := false
var size := Vector2(36, 36)
var pieces: Array[TerrainPiece] = []
## Authored overlapping surfaces. Exposed terrain uses the heightfield provider.
var floor_layout := {}
var _floor_geometry: FloorLayout
var _floor_geometry_hash := 0
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


## Read-only derived geometry; dynamic bridges invalidate it by changing
## the authored dictionary. Never modify this layout in place.
func floor_geometry() -> FloorLayout:
	var revision:=floor_layout.hash()
	if _floor_geometry==null or revision!=_floor_geometry_hash:
		_floor_geometry=FloorLayout.from_dict(floor_layout)
		_floor_geometry_hash=revision
	return _floor_geometry


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
	var i := _lattice(p)
	if i >= 0 and _mult_cache[i] >= 0.0:
		return _mult_cache[i]
	var m := 1.0
	for piece in pieces:
		if piece.contains(p):
			m = maxf(m, piece.kind.move_mult)
	if i >= 0:
		_mult_cache[i] = m
	return m


## True if a figure with this base radius can stand at `p`.
func can_stand(p: Vector2, radius: float) -> bool:
	var i := _lattice(p) if is_equal_approx(radius, Figure.BASE_RADIUS) else -1
	if i >= 0 and _stand_cache[i] != 0:
		return _stand_cache[i] == 2
	var ok := _can_stand(p, radius)
	if i >= 0:
		_stand_cache[i] = 2 if ok else 1
	return ok


## Answers on the quarter-inch lattice (where move searches look) are kept in
## flat arrays until invalidate_terrain(). Off-lattice points are computed each time.
## Stand: 0 unknown, 1 blocked, 2 open. Mult and height: negative/NaN = unknown.
var _stand_cache := PackedByteArray()
var _mult_cache := PackedFloat64Array()
var _height_cache := PackedFloat64Array()
var _lattice_cols := 0
var _lattice_size := Vector2.ZERO
## Distance-field step costs (no mover) by node index * 8 + direction.
var static_step_cache := PackedFloat64Array()
## Bot distance fields by target node (see MovePlanner.distance_field).
var field_cache := {}
var has_ground_profiles := false
var has_ramps := false
var _ground_profiles: Array[TerrainPiece]=[]
var ground_max := 0.0


## Index of `p` in the quarter-inch lattice arrays, or -1 off the lattice or table.
func _lattice(p: Vector2) -> int:
	if _lattice_size != size:
		_reset_caches()
	var q := p * 4.0
	var x := roundi(q.x)
	var y := roundi(q.y)
	if x < 0 or y < 0 or x >= _lattice_cols or absf(q.x - x) > 0.0001 or absf(q.y - y) > 0.0001:
		return -1
	var i := x * (int(size.y * 4.0) + 1) + y
	return i if i < _stand_cache.size() else -1


func _reset_caches() -> void:
	_lattice_size = size
	_lattice_cols = int(size.x * 4.0) + 1
	var n := _lattice_cols * (int(size.y * 4.0) + 1)
	_stand_cache = PackedByteArray()
	_stand_cache.resize(n)
	_mult_cache = PackedFloat64Array()
	_mult_cache.resize(n)
	_mult_cache.fill(-1.0)
	_height_cache = PackedFloat64Array()
	_height_cache.resize(n)
	_height_cache.fill(NAN)
	static_step_cache = PackedFloat64Array()
	static_step_cache.resize((int(size.x / 0.5) + 1) * (int(size.y / 0.5) + 1) * 8)
	static_step_cache.fill(-1.0)


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
	for i in range(_ground_profiles.size()-1,-1,-1):
		var piece := _ground_profiles[i]
		if piece.contains(p):
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
	var i := _lattice(p)
	if i >= 0 and not is_nan(_height_cache[i]):
		return _height_cache[i]
	var piece := surface_at(p)
	var height := piece.surface_height(p) if piece!=null else 0.0
	if i >= 0:
		_height_cache[i]=height
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
	_ground_profiles.clear()
	ground_max=0.0
	for piece in pieces:
		has_ground_profiles = has_ground_profiles or piece.kind.ground_surface
		has_ramps = has_ramps or piece.ramp
		if piece.kind.ground_surface:
			_ground_profiles.append(piece)
			ground_max=maxf(ground_max,maxf(piece.surface_height(piece.rect.position),piece.surface_height(piece.rect.end)))
	_reset_caches()
	field_cache.clear()


func set_boundaries(lines: Array[Dictionary]) -> void:
	boundaries.assign(lines.duplicate(true))
	invalidate_terrain()
