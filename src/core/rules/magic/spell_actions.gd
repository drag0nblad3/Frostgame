class_name SpellActions
extends RefCounted
## Two-stage spellcasting: announce target, roll, choose Health, then resolve.

var c: GameController
var shatter := Shatterstar.new()
var summons: SummonActions
var terrain: TerrainMagic
var movement: MagicMovement
var counter: CounterMagic
var illusions: IllusionActions
var resistance: ResistanceActions
var weapons: WeaponActions
var treasure_magic: TreasureMagic
var crumble: CrumbleActions
var beauty: BeautyActions
var eye: WizardEye


func _init(controller: GameController) -> void:
	c = controller
	summons = SummonActions.new(c)
	terrain = TerrainMagic.new(c)
	movement = MagicMovement.new(c)
	counter = CounterMagic.new(c)
	illusions = IllusionActions.new(c)
	resistance = ResistanceActions.new(c)
	weapons = WeaponActions.new(c)
	treasure_magic = TreasureMagic.new(c)
	crumble = CrumbleActions.new(c)
	beauty = BeautyActions.new(c)
	eye = WizardEye.new(c)


func can_cast(id: String, target_id: int,ammo: bool=false) -> bool:
	return SpellAvailability.can_cast(self, id, target_id, ammo)


func start(id: String, target_id: int,ammo: bool=false) -> bool:
	if not can_cast(id, target_id,ammo) or id in ["leap", "transpose", "suggestion"]:
		return false
	return _roll(id,target_id,null,false,-1,{"magic_ammo":true} if ammo else {})


func counter_options(id: String) -> Array[Dictionary]:
	return SpellAvailability.counter_options(self, id)


func start_counter(id: String, index: int) -> bool:
	var options := counter_options(id)
	if index < 0 or index >= options.size():
		return false
	var option := options[index]
	return _roll(id, option["target"], null, false, -1, option)


func treasure_options(id: String) -> Array[TreasureToken]:
	return SpellAvailability.treasure_options(self, id)


func start_treasure(id: String, token_id: int, at: Vector2) -> bool:
	var token := c.state.treasure(token_id)
	if token == null or not treasure_options(id).has(token) or not treasure_magic.can_place(c.state.active(), id, token, at):
		return false
	return _roll(id, c.state.active_id, at, false, -1, {"token": token_id})


func start_floor_treasure(id: String,token_id: int,n: Vector3i) -> bool:
	var token:=c.state.treasure(token_id)
	var f:=c.state.active()
	if c.state.board.floor_layout.is_empty() or token==null or not treasure_options(id).has(token) or not treasure_magic.can_place_floor(f,id,token,n):
		return false
	var layout:=c.state.board.floor_geometry()
	return _roll(id,f.id,layout.point(n),false,-1,{"token":token_id,"surface_id":layout.surface_id(n)})


func start_floor_suggestion(target_id: int,n: Vector3i) -> bool:
	if c.state.board.floor_layout.is_empty() or not can_cast("suggestion",target_id):
		return false
	var t:=c.state.figure(target_id)
	if not SpellAvailability.floor_suggestion_points(self,t).has(n):
		return false
	var layout:=c.state.board.floor_geometry()
	return _roll("suggestion",target_id,layout.point(n),false,-1,{"surface_id":layout.surface_id(n)})


func _floor_suggestion_result(success: bool,t: Figure,at: Vector2,surface: String) -> void:
	if success or not t.in_play():
		return
	c._loot.drop_on_death(t)
	var layout:=c.state.board.floor_geometry()
	var n:=layout.node(surface,at)
	if SpellAvailability.floor_suggestion_points(self,t).has(n) and (at!=t.pos or surface!=t.surface_id):
		movement.move_floor(t,n)


func start_move(id: String, target_id: int, at: Vector2) -> bool:
	if not c.state.board.floor_layout.is_empty() or not can_cast(id,target_id):
		return false
	var f := c.state.active()
	var t := c.state.figure(target_id)
	if id == "leap":
		if not movement.can_land(f, t, id, at):
			return false
	elif id == "suggestion":
		if not suggestion_points(t).has(at):
			return false
	else:
		return false
	return _roll(id, target_id, at)


func suggestion_points(t: Figure) -> Array[Vector2]:
	return SpellAvailability.suggestion_points(self, t)


func start_swap(first: int, second: int) -> bool:
	if not can_cast("transpose", first) or not can_cast("transpose", second) or not movement.can_swap(c.state.active(), c.state.figure(first), c.state.figure(second)):
		return false
	return _roll("transpose", first, null, false, second)


func placement_points(id: String, first_only: bool = false, rotated: bool = false,extended: bool=false) -> Array[Vector2]:
	return SpellAvailability.placement_points(self, id, first_only, rotated, extended)


func is_placement(id: String) -> bool:
	return id == "teleport" or SummonActions.PLACEMENT.has(id) or TerrainMagic.SPELLS.has(id)


func start_at(id: String, at: Vector2, rotated: bool = false,extended: bool=false) -> bool:
	if placement_points(id,true,rotated,extended).is_empty():
		return false
	var f := c.state.active()
	if id == "teleport":
		if not movement.can_land(f, f, id, at):
			return false
	elif TerrainMagic.SPELLS.has(id):
		if not terrain.can_place(f,id,at,rotated,extended):
			return false
	elif not summons.can_place(f, id, at):
		return false
	return _roll(id,c.state.active_id,at,rotated,-1,{"extended_bridge":true} if extended else {})


func start_floor_at(id: String,n: Vector3i,rotated: bool=false) -> bool:
	if not SpellAvailability.floor_placement_ready(self,id):
		return false
	var f:=c.state.active()
	var layout:=c.state.board.floor_geometry()
	if id=="teleport":
		return LayeredMagic.start_teleport(c,n)
	if TerrainMagic.FLOOR_SPELLS.has(id):
		if not terrain.can_place_floor(f,id,n,rotated):
			return false
		return _roll(id,f.id,layout.point(n),rotated,-1,{"surface_id":layout.surface_id(n)})
	if not SummonActions.PLACEMENT.has(id) or not summons.can_place_floor(f,id,n):
		return false
	return _roll(id,f.id,layout.point(n),false,-1,{"floor_destination":n,"surface_id":layout.surface_id(n)})


func _roll(id: String, target_id: int, at: Variant = null, rotated: bool = false, second: int = -1, effect: Dictionary = {}) -> bool:
	var f := c.state.active()
	if shatter.eligible(f, c.state, id):
		var declared := shatter.declare(f, id, target_id, at, rotated, second, effect)
		if declared.is_empty():
			return false
		_dispatch_shatter(declared)
		advance_shatter()
		return true
	return _authorize_roll(id, target_id, at, rotated, second, effect)


func _authorize_roll(id: String, target_id: int, at: Variant, rotated: bool, second: int, effect: Dictionary) -> bool:
	var f := c.state.active()
	var targets: Array[Figure] = [c.state.figure(target_id)]
	if second >= 0:
		targets.append(c.state.figure(second))
	if id in ["elemental_bolt", "bone_dart", "poison_dart"]:
		targets.assign(ShotTarget.participants(c.state.figures, targets[0]))
	beauty.authorize(f, targets, _roll_authorized.bind(id, target_id, at, rotated, second, effect))
	return true


func _roll_authorized(id: String, target_id: int, at: Variant, rotated: bool, second: int, effect: Dictionary) -> void:
	var f := c.state.active()
	if f == null or not f.in_play():
		return
	illusions.reveal(f)
	var t := c.state.figure(target_id)
	var spec: Dictionary=c.state.spell_catalog[id]
	var limit := float(spec.get("range",24.0))
	var tiger_used: bool= c.state.board.floor_layout.is_empty() and t!=null and t!=f and spec.get("kind","")!="touch" and not WizardEye.visible(c.state.board,f,t.pos,limit) and TigerEye.witness(c.state.board,f,t.pos,limit)!=null
	var known: bool = c.state.spellbooks.get(f.side, {}).has(id)
	var scroll_roll := 0 if known else ScrollActions.consume_roll(f,id)
	var scroll := scroll_roll>0
	var raw := scroll_roll if scroll else c.dice.d20()
	var gear_bonus := ActiveGear.casting_bonus(f, id)
	var puppet_miscast := not scroll and raw==1 and id in ["mind_control","suggestion"] and RedKingGear.puppet(f)
	if not scroll and f.next_cast_gear == "gear_gloves_casting" and ActiveGear.spend(f, f.next_cast_gear):
		gear_bonus += 5
	elif not scroll and f.next_cast_gear == "gear_wand_light" and ActiveGear.spend(f, f.next_cast_gear):
		var alternate := c.dice.d20()
		c.emit("wand_roll", {"id": f.id, "first": raw, "second": alternate})
		raw = maxi(raw, alternate)
	f.next_cast_gear = ""
	var plane_penalty := PlaneWalk.penalty(f, c.state.turn) if id == "plane_walk" else 0
	if id == "plane_walk":
		PlaneWalk.record(f, c.state.turn)
	var empowered := not scroll and f.spell_effects.erase("potion_empowerment")
	var total := scroll_roll if scroll else CastingRoll.modified(raw, gear_bonus + (4 if empowered else 0) + plane_penalty + RealityCracks.casting_modifier(c.state,id) + RedKingSinkhole.casting_modifier(c.state,f) + f.roll_penalty() + WordMagic.modifier(c.state, id) + BaseRules.casting_bonus(f.campaign_base, id) - (2 if f.spell_effects.has("furious_quill") else 0) - (2 if f.affected_by_insects() else 0), f.def.role == "apprentice")
	var tn := int(c.state.spellbooks.get(f.side, {}).get(id, c.state.spell_catalog[id]["number"]))
	if not shatter.spent:
		c._spend(f)
		if not shatter.next.is_empty() or shatter.resolving:
			shatter.spent = true
	c.state.pending_cast = {"id": id, "caster": f.id, "target": target_id, "raw": raw, "total": total, "tn": tn, "scroll": scroll, "cordial": empowered}
	if at != null:
		c.state.pending_cast["at"] = at
		c.state.pending_cast["rotated"] = rotated
	c.state.pending_cast["second"] = second
	if not effect.is_empty():
		c.state.pending_cast["effect"] = effect
	c.emit("cast_roll", c.state.pending_cast.duplicate())
	if tiger_used:
		TigerEye.test_use(c,f)
	if id in ["spell_eater", "strike_dead"]:
		c._hurt(f, 1, f, false)
	if puppet_miscast:
		c._hurt(f,1,f,false)
	if RealityCracks.id(c.state)==7 and RealityCracks.casting_modifier(c.state,id)==5:
		c._hurt(f,2,f,false)


func max_empowerment() -> int:
	return SpellAvailability.max_empowerment(self)


func finish(health: int) -> bool:
	shatter.resolving = true
	var ok := _finish_one(health)
	shatter.resolving = false
	if ok:
		advance_shatter()
	return ok


func _finish_one(health: int) -> bool:
	return SpellResolution._finish_one(self, health)


func _heal(t: Figure, amount: int) -> void:
	SpellResolution._heal(self, t, amount)


func _shot(f: Figure, t: Figure, power: int, origin: Variant = null, elemental: bool = false, magical: bool = true, spell: String = "") -> void:
	SpellResolution._shot(self, f, t, power, origin, elemental, magical, spell)


func _apply_shot(f: Figure,t: Figure,dmg: int,event: Dictionary) -> void:
	SpellResolution._apply_shot(self, f, t, dmg, event)


func _continue_ball() -> void:
	SpellResolution._continue_ball(self)


func answer_absorption(use: bool) -> bool:
	return SpellUpkeep.answer_absorption(self, use)


func _resist_effect(f: Figure, id: String) -> void:
	SpellUpkeep._resist_effect(self, f, id)


func on_activate(f: Figure) -> void:
	SpellUpkeep.on_activate(self, f)


func on_end_activation(f: Figure) -> void:
	SpellUpkeep.on_end_activation(self, f)


func on_end_turn() -> void:
	SpellUpkeep.on_end_turn(self)


func _banish(f: Figure, t: Figure, roll: int, threshold: int) -> void:
	SpellResolution._banish(self, f, t, roll, threshold)


func _direct_attack(f: Figure,t: Figure,power: int,spell: String="") -> void:
	SpellResolution._direct_attack(self, f, t, power, spell)


func can_cancel(target: int) -> bool:
	return SpellUpkeep.can_cancel(self, target)


func cancel(target: int) -> bool:
	return SpellUpkeep.cancel(self, target)


func _resisted_status(success: bool, t: Figure, id: String, roll: int) -> void:
	SpellResolution._resisted_status(self, success, t, id, roll)


func _resisted_steal(success: bool, f: Figure, t: Figure) -> void:
	SpellResolution._resisted_steal(self, success, f, t)


func available_spell(f: Figure, id: String) -> bool:
	return SpellAvailability.available_spell(self, f, id)


func available_spells(f: Figure) -> Array[String]:
	return SpellAvailability.available_spells(self, f)


func can_insure() -> bool:
	return SpellUpkeep.can_insure(self)


func insure() -> bool:
	return SpellUpkeep.insure(self)


func _resisted_death(success: bool, f: Figure, t: Figure) -> void:
	SpellResolution._resisted_death(self, success, f, t)


func _suggestion_result(success: bool, t: Figure, at: Vector2) -> void:
	SpellResolution._suggestion_result(self, success, t, at)


func reroll_fate() -> bool:
	return SpellUpkeep.reroll_fate(self)


func _dispatch_shatter(entry: Dictionary) -> void:
	SpellUpkeep._dispatch_shatter(self, entry)


func advance_shatter() -> void:
	SpellUpkeep.advance_shatter(self)


func single_shatter() -> bool:
	return SpellUpkeep.single_shatter(self)


func toggle_golden_fang() -> bool:
	return SpellUpkeep.toggle_golden_fang(self)


func toggle_gem(option: String) -> bool:
	return SpellUpkeep.toggle_gem(self, option)
