class_name RedKingHooks
extends RefCounted
## Plugs Red King rules into the core rule hooks (RuleHooks). Core combat,
## movement, sight and treasure code no longer names Red King classes.


static func install() -> void:
	# Figures that are objectives rather than combatants (tether pylons).
	RuleHooks.add("objective_figure", RedKingTethers.pylon)
	RuleHooks.add("equipment_command",_equipment_command)
	RuleHooks.add("scenario_command",RedKingCommands.execute)
	# Figures that never lend support in a fight (Mad Man hunters).
	RuleHooks.add("no_support", RedKingMadMan.hunter)
	RuleHooks.add("fight_bonus", _secret_hrut_bonus)
	RuleHooks.add("melee_armour", _soul_armour)
	RuleHooks.add("melee_damage_bonus", RedKingGear.fire_damage)
	RuleHooks.add("range", _reality_range)
	RuleHooks.add("shoot_modifier", func(f: Figure) -> int: return -2 if RealityCracks.low_gravity(f) else 0)
	RuleHooks.add("sight", _reality_sight)
	RuleHooks.add("treasure_no_slowdown", RealityCracks.low_gravity)
	RuleHooks.add("treasure_light_slowdown", _treasure_light)
	RuleHooks.add("treasure_guarded", RedKingHill.guarded)
	RuleHooks.add("cannot_carry_treasure", func(s: GameState, f: Figure) -> bool: return RedKingMadMan.hunter(f) or (RedKingVeil.active(s) and f.side == 1))
	RuleHooks.add("group_blocked", RedKingSquatter.failed_this_turn)
	RuleHooks.add("forced_move_void", _forced_void)
	RuleHooks.add("forced_move_blocked", RedKingVeil.touch)
	RuleHooks.add("forced_contact", _forced_contact)
	RuleHooks.add("forced_path_void", func(c: GameController, p: Vector2) -> bool: return RedKingBridge.active(c.state) and c.state.board.over_void(p, Figure.BASE_RADIUS))


static func _equipment_command(c: GameController,key: String,args: Dictionary) -> Variant:
	match key:
		"lantern_toggle": return HolyLantern.toggle(c)
		"death_mask_toggle": return DeathMask.toggle(c)
		"direction_arm": return RedKingDirection.arm(c)
		"direction_answer": return RedKingDirection.answer(c,str(args.get("method","")))
		"absorb_arm": return RedKingElemental.arm(c)
		"gutter_fight": return GearActions.gutter_fight(c,int(args.get("target",-1)))
		"gutter_skip": return GearActions.gutter_skip(c)
		"tiger_eye_move": return TigerEye.move_eye(c,args["at"]) if args.get("at") is Vector2 else false
		"worm_summon": return WormRider.summon(c,args["at"]) if args.has("at") else false
		"worm_relocation": return WormRider.answer_relocation(c,args["at"]) if args.has("at") else false
	return null


## The mindscape reward affects Fight against Hrut for one selected battle.
static func _secret_hrut_bonus(f: Figure, enemy: Figure) -> int:
	var s := RedKingVeil.of(f)
	if s == null or f.side < 0 or not enemy.def.id.begins_with("hrut_"):
		return 0
	return 1 if s.scenario_data.get("secret_hrut_%d" % f.side, false) else 0


static func _soul_armour(attacker: Figure, target: Figure) -> Variant:
	var armour := RedKingGear.armour(attacker, target)
	return armour if armour != target.effective_armour() else null


## Range across reality cracks or on the sphere; null for ordinary tables.
static func _reality_range(a: Figure, b: Figure) -> Variant:
	var s := RedKingVeil.of(a)
	if s == null:
		return null
	var relation := RealityCrackGeometry.cross_relation(s.board, a.pos, b.pos)
	if relation != 0:
		return 12.0 if relation == 1 else INF
	if s.board.reality_sphere:
		return maxf(0.0, Vector2(RealityCrackGeometry.sight_distance(s.board, a.pos, b.pos), a.elevation - b.elevation).length() - 2.0 * Figure.BASE_RADIUS)
	return null


## Sight across reality cracks or on the sphere; null for ordinary tables.
static func _reality_sight(board: Board, from: Vector2, to: Vector2, observer: Figure) -> Variant:
	var relation := RealityCrackGeometry.cross_relation(board, from, to)
	if relation != 0:
		var result := LineOfSight.Result.new()
		result.clear = relation == 1
		return result
	if board.reality_sphere:
		return RealityCrackGeometry.wrapped_sight(board, from, to, observer)
	return null


## Veil, Herded Like Cattle and The Bridge: treasure costs 1" instead of half Move.
static func _treasure_light(f: Figure) -> bool:
	var s := RedKingVeil.of(f)
	return RedKingVeil.active(s) or RedKingHerded.active(s) or RedKingBridge.active(s)


## A push across The Bridge's void. True when the figure fell or was stopped here.
static func _forced_void(c: GameController, moving: Figure, from: Vector2, dest: Vector2) -> bool:
	if not (RedKingBridge.active(c.state) and c.state.board.over_void(dest, Figure.BASE_RADIUS)):
		return false
	var last := from
	for i in range(1, 5):
		var at := from.lerp(dest, float(i) / 4.0)
		if RedKingBridge.forced_void(c, moving, at, last):
			return true
		last = at
	return false


static func _forced_contact(c: GameController, moving: Figure, from: Vector2, dest: Vector2) -> void:
	RedKingFire.portal_contact(c, moving, from, dest, {})
