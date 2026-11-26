class_name ScenarioNull
extends RefCounted
## The Silent Tower's null field; the exposed terraces replace inaccessible interior floors.

static func field_at(board: Board, at: Vector2, margin: float = Figure.BASE_RADIUS) -> bool:
	if board.id != "silent_tower":
		return false
	for p in board.pieces:
		if p.kind.id.begins_with("null_") and p.rect.grow(margin).has_point(at):
			return true
	return false


static func muted(f: Figure) -> bool:
	if f == null or f.battle_ref == null:
		return false
	var s: GameState = f.battle_ref.get_ref()
	return s != null and field_at(s.board, f.pos)


static func protected_treasure(s: GameState, at: Vector2) -> bool:
	if s.scenario_special != "silent_tower":
		return false
	for p in s.board.pieces:
		if p.kind.id == "null_lower":
			var closest := Vector2(clampf(at.x, p.rect.position.x, p.rect.end.x), clampf(at.y, p.rect.position.y, p.rect.end.y))
			return closest.distance_to(at) <= 6.0
	return false


static func enter(c: GameController, f: Figure) -> void:
	var s := c.state
	if not f.in_play() or not field_at(s.board, f.pos):
		return
	var had_magic := not f.spell_effects.is_empty() or f.elemental_shield > 0 or f.controller_id >= 0 or f.familiar
	if f.shrunk_treasure_id >= 0:
		c._loot.cancel_shrinking(f)
	f.spell_effects.clear()
	f.elemental_shield = 0
	f.petrified_skip = false
	f.walk_phases.clear()
	f.stored_action_turn = -1
	f.next_cast_gear = ""
	for ids: Array in s.fast_acts.values():
		ids.erase(f.id)
	if f.familiar:
		f.familiar = false
		f.def = f.def.with_bonuses({"health": -2})
		f.health = mini(f.health, f.def.health)
	if f.controller_id >= 0:
		c._magic.summons.release(f)
	if f.summon_spell == "illusionary_soldier" or f.summon_spell == "animate_skull":
		c._magic.summons.vanish(f)
		return
	if had_magic:
		c.emit("null_field", {"id": f.id})
	if f.side < 0 or s.tower_visitors.has(f.id) or f.def.role not in ["wizard", "apprentice"]:
		return
	for p in s.board.pieces:
		if p.kind.id == "null_lower" and p.contains(f.pos):
			s.tower_visitors[f.id] = true
			c.emit("tower_entered", {"id": f.id, "side": f.side, "xp": 40 if f.def.role == "wizard" else 20})
			return
