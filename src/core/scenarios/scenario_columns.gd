class_name ScenarioColumns
extends RefCounted
## Guardian columns in the Complex Temple (p. 151).

static func contact(board: Board,at: Vector2,height: float=NAN) -> TerrainPiece:
	if board==null or board.id!="complex_temple":
		return null
	var h:=board.height_at(at) if is_nan(height) else height
	for p in board.pieces:
		if p.kind.id!="temple_column" or absf(h-p.base_height)>=0.5:
			continue
		var nearest := Vector2(clampf(at.x, p.rect.position.x, p.rect.end.x), clampf(at.y, p.rect.position.y, p.rect.end.y))
		if at.distance_to(nearest) <= Figure.BASE_RADIUS + 0.25:
			return p
	return null


static func challenge(c: GameController, f: Figure) -> bool:
	if not f.in_play() or f.side < 0 or IllusionRules.phantom(f) or f.spell_effects.has("plane_walk"):
		return false
	var s := c.state
	var p := contact(s.board,f.pos,f.elevation)
	if p == null:
		return false
	var token: TreasureToken = null
	for t in s.treasures:
		if t.frozen and t.pos.distance_to(p.rect.get_center())<0.01 and (s.board.floor_layout.is_empty() or t.surface_id==p.surface_id):
			token = t
			break
	if token == null:
		return false
	var raw := c.dice.d20()
	var defence := c.dice.d20()
	var total := raw + mini(f.effective_fight() + f.melee.fight_mod + MagicEquipment.bonus(f, "fight", f.melee.id) + (1 if WeaponEnchantment.active(f,f.melee) else 0), 10) + f.roll_penalty()
	var win := total > defence
	var lose := total < defence
	if s.critical_hits:
		if raw == 20 or defence == 20:
			win = raw == 20 and defence != 20
			lose = defence == 20 and raw != 20
	var xp := 0
	if not s.column_fighters.has(f.id):
		s.column_fighters[f.id] = true
		xp = 30 if f.def.role == "wizard" else (20 if f.def.role == "apprentice" else 0)
	c.emit("column_fight", {"id": f.id, "side": f.side, "xp": xp, "treasure": token.id, "total": total, "column": defence, "won": win, "lost": lose})
	if lose:
		c._hurt(f, Damage.amount(defence, f.melee.enemy_damage_mod, f.effective_armour(), defence, s.critical_hits), f, true)
	elif win:
		if s.board.floor_layout.is_empty():
			s.board.pieces.erase(p)
			s.board.invalidate_terrain()
			c.emit("terrain_changed",{"spell":"temple_column","created":false})
		else:
			c._magic.terrain.remove(p)
		token.frozen=false
		c.emit("column_opened", {"id": f.id, "treasure": token.id})
		# Eligible winners may collect without spending another action.
		if f.pos.distance_to(token.pos) <= Figure.BASE_RADIUS + 1.0 and f.in_play():
			if f.side==s.reaction_side and c._loot.can_claim_free(f,token):
				var options: Array[Dictionary]=[{"collect":true},{"collect":false}]
				if CoreScenarioChoice.offer(c,"column",f.side,f.id,token.id,0,options):
					return true
			c._loot.claim_free(f, token)
	return true
