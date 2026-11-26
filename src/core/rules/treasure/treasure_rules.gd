class_name TreasureRules
extends RefCounted
## Treasure contact, enemy interference and scoring (pp. 68, 71).

const TOKEN_RADIUS := 0.3


static func can_pick_up(s: GameState, f: Figure, token: TreasureToken) -> bool:
	if f == null or token == null or not f.in_play() or not token.on_ground() or token.frozen:
		return false
	if (f.treasure_id >= 0 and (f.shrunk_treasure_id < 0 or f.second_treasure_id >= 0)) or f.def.traits.has("animal") or IllusionRules.phantom(f) or f.spell_effects.has("plane_walk"):
		return false
	var height := s.board.height_at(token.pos)
	if not token.surface_id.is_empty():
		if token.surface_id!=f.surface_id:
			return false
		var layout := FloorLayout.from_dict(s.board.floor_layout)
		var index := layout.index_of(token.surface_id)
		if index<0:
			return false
		height=layout.surfaces[index].height_at(token.pos)
	if absf(f.elevation - height) >= 0.5 or f.pos.distance_to(token.pos) > Figure.BASE_RADIUS + TOKEN_RADIUS + 0.01:
		return false
	for enemy in s.figures:
		if enemy.side == f.side or not enemy.in_play() or enemy.spell_effects.has("plane_walk"):
			continue
		if not token.surface_id.is_empty() and enemy.surface_id!=token.surface_id and not LineOfSight.check_figures(s.board,enemy,f).clear:
			continue
		if Shooting.distance(enemy, f) <= 1.0 or Vector3(enemy.pos.x, enemy.elevation, enemy.pos.y).distance_to(Vector3(token.pos.x, height, token.pos.y)) <= Figure.BASE_RADIUS + TOKEN_RADIUS + 1.0:
			return false
	return true


static func edge_distance(board: Board, at: Vector2) -> float:
	return minf(minf(at.x, board.size.x - at.x), minf(at.y, board.size.y - at.y))


static func winner(s: GameState) -> int:
	var best := -1
	var count := -1
	for side in s.side_count():
		var secured := s.secured_count(side)
		if secured > count:
			best = side
			count = secured
		elif secured == count:
			best = -1
	return best
