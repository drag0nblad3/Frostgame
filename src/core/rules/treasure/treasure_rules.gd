class_name TreasureRules
extends RefCounted
## Treasure contact, enemy interference and scoring (pp. 68, 71).

const TOKEN_RADIUS := 0.3


static func can_pick_up(s: GameState, f: Figure, token: TreasureToken) -> bool:
	if f == null or token == null or not f.in_play() or not token.on_ground() or token.frozen or token.investigation or f.surface_id.begins_with("climb:"):
		return false
	if f.ring_side!=token.ring_side:
		return false
	if RuleHooks.any("treasure_guarded", [s, token]):
		return false
	if RuleHooks.any("cannot_carry_treasure", [s, f]):
		return false
	if (f.treasure_id >= 0 and (f.shrunk_treasure_id < 0 or f.second_treasure_id >= 0)) or f.def.traits.has("animal") or IllusionRules.phantom(f) or f.spell_effects.has("plane_walk"):
		return false
	if not in_reach(s,f,token,Figure.BASE_RADIUS+TOKEN_RADIUS+0.01):
		return false
	return not enemy_interferes(s,f,token)


## Resolve the actual support, not the exposed heightfield underneath a deck.
static func token_height(s: GameState,token: TreasureToken) -> float:
	if token.surface_id.is_empty():
		return s.board.height_at(token.pos) if s.board.floor_layout.is_empty() else NAN
	var layout:=s.board.floor_geometry()
	var index:=layout.index_of(token.surface_id)
	return layout.surfaces[index].height_at(token.pos) if index>=0 else NAN


static func in_reach(s: GameState,f: Figure,token: TreasureToken,radius: float) -> bool:
	var height:=token_height(s,token)
	if is_nan(height) or f.ring_side!=token.ring_side or absf(f.elevation-height)>=0.5 or f.pos.distance_to(token.pos)>radius:
		return false
	if not token.surface_id.is_empty() and f.surface_id!=token.surface_id:
		return LineOfSight.floor_ray(s.board,s.board.floor_geometry(),Vector3(f.pos.x,f.elevation+0.25,f.pos.y),Vector3(token.pos.x,height+0.25,token.pos.y),f,false)
	return true


static func enemy_interferes(s: GameState,f: Figure,token: TreasureToken) -> bool:
	var height:=token_height(s,token)
	if is_nan(height):
		return true
	for enemy in s.figures:
		if enemy.ring_side!=f.ring_side or enemy.side==f.side or not enemy.in_play() or enemy.spell_effects.has("plane_walk"):
			continue
		var near_figure:=Shooting.distance(enemy,f)<=1.0
		var near_token:=Vector3(enemy.pos.x,enemy.elevation,enemy.pos.y).distance_to(Vector3(token.pos.x,height,token.pos.y))<=Figure.BASE_RADIUS+TOKEN_RADIUS+1.0
		if not token.surface_id.is_empty():
			var layout:=s.board.floor_geometry()
			var from:=Vector3(enemy.pos.x,enemy.elevation+0.5,enemy.pos.y)
			if near_figure:
				near_figure=LineOfSight.floor_ray(s.board,layout,from,Vector3(f.pos.x,f.elevation+0.5,f.pos.y),enemy,false)
			if near_token:
				near_token=LineOfSight.floor_ray(s.board,layout,from,Vector3(token.pos.x,height+0.25,token.pos.y),enemy,false)
		if near_figure or near_token:
			return true
	return false


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
