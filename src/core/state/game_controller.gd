class_name GameController
extends RefCounted
## The only thing that changes GameState. Players and bots call its actions;
## every change is announced as a GameEvent.

signal event_emitted(e: GameEvent)

var state: GameState
var dice: Dice
var history: Array[GameEvent] = []
var command_history: Array[Dictionary] = []
var recording_command := false
var capture_frames := false
var replay_frames: Array[Dictionary]=[]
var _flow: TurnFlow
var _loot: TreasureActions
var _displacement: CombatDisplacement
var _encounters: EncounterActions
var _magic: SpellActions
var _potions: PotionActions
var _fate_combat: FateCombat
var deployment: BattleDeployment


func _init(s: GameState, d: Dice) -> void:
	state = s
	for f in s.figures:
		f.battle_ref = weakref(s)
	dice = d
	_flow = TurnFlow.new(self)
	_loot = TreasureActions.new(self)
	_displacement = CombatDisplacement.new(self)
	_encounters = EncounterActions.new(self)
	_magic = SpellActions.new(self)
	_potions = PotionActions.new(self)
	_fate_combat = FateCombat.new(self)


## Terminal lifecycle operation, only for a battle that is being discarded.
## A pending Will/Beauty continuation can bind the controller back into its
## own helper, so dropping the scene reference alone may not release it.
func abandon_pending_callbacks() -> void:
	_magic.resistance.continuation=Callable()


func emit(type: String, data: Dictionary = {}) -> void:
	var e := GameEvent.new(type, data)
	history.append(e)
	HolyLantern.observe(self,type,data)
	event_emitted.emit(e)
	if RedKingInvestigations.active(state):
		RedKingInvestigations.observe_event(self,type,data)


func begin_deployment(human_side: int=-1,manual_treasure: bool=false) -> BattleDeployment:
	deployment=BattleDeployment.new(self,human_side)
	deployment.begin(manual_treasure)
	return deployment


func start_game() -> void:
	if deployment!=null and not deployment.done:
		return
	RuleHooks.run("battle_prepare",[self])
	_flow.start_turn()
	BattleFrame.record(self)


## Figures the side to play may activate now.
func activatable() -> Array[Figure]:
	if state.over or awaiting_reaction():
		var none: Array[Figure] = []
		return none
	return state.waiting(state.current_side())


func activate(id: int) -> bool:
	return BattleRecord.run(self,"activate",{"id":id},func() -> bool: return ControllerActivation.activate(self, id))


func can_move() -> bool:
	var f := state.active()
	return state.pending_gutter<0 and not awaiting_reaction() and state.pending_cast.is_empty() and f != null and f.in_play() and f.actions_left > 0 and (not RedKingMind.is_wizard(state,f) or f.moves_taken==0) and MoveRules.can_move(f, state.figures)


## Where the active figure could go with its next movement action.
## Explicit experimental API; do not allow legacy two-dimensional moves on layered maps.
func layered_reach() -> LayeredReach:
	return LayeredMovement.reach(self)


func move_on_floor(node: Vector3i) -> bool:
	return BattleRecord.run(self,"move_on_floor",{"node":node},func() -> bool: return LayeredMovement.move(self,node))


func floor_exit_nodes() -> Array[Vector3i]:
	return LayeredLoot.exit_nodes(self)


func exit_on_floor(node: Vector3i) -> bool:
	return BattleRecord.run(self,"exit_on_floor",{"node":node},func() -> bool: return LayeredLoot.exit(self,node))


func teleport_on_floor(node: Vector3i) -> bool:
	return LayeredMagic.start_teleport(self,node)


func jump_on_floor(node: Vector3i) -> bool:
	return LayeredJump.move(self,node)


func leap_on_floor(target_id: int,node: Vector3i) -> bool:
	return LayeredLeap.start(self,state.figure(target_id),node)


func bridge_on_floors(a: Vector3i,b: Vector3i) -> bool:
	return LayeredBridge.start(self,a,b)


func cancel_floor_bridge() -> bool:
	return LayeredBridge.cancel(self)


## Movement action bookkeeping is independent of the geometry implementation.
func spend_move(f: Figure) -> void:
	f.spell_effects.erase("petrify")
	f.actions_left-=1
	f.moves_taken+=1


## Canonical interface for player-facing movement. A route retains its
## surface identity, even if two endpoints share the same table coordinates.
func finish_movement(f: Figure,engaged: bool,arrived: bool=true) -> void:
	if arrived:
		ScenarioSites.end_move(self,f)
		RedKingSquatter.record_contact(self)
		RedKingSinkhole.record_xp(self,f)
	elif not f.in_play():
		return
	CreatureSenses.reveal_contacts(self,f)
	_magic.illusions.after_move(f)
	GearActions.gutter_after_move(self,f,engaged)


func movement_options(mode: String="move") -> BattleMovementOptions:
	return BattleMovementOptions.query(self,mode)


func commit_movement(mode: String,node: Variant) -> bool:
	return BattleRecord.run(self,"movement",{"mode":mode,"node":node},func() -> bool: return BattleMovementOptions.commit(self,mode,node))


func reach() -> MoveReach:
	return ControllerMovement.reach(self)


func move_to(node: Vector2i,cape: bool=false) -> bool:
	return BattleRecord.run(self,"move_to",{"node":node,"cape":cape},func() -> bool: return ControllerMovement.move_to(self, node, cape))


func _commit_move(f: Figure, path: PackedVector2Array, cost: float, ignored: Array[int],cape: bool=false) -> bool:
	return ControllerMovement._commit_move(self, f, path, cost, ignored, cape)


func _move_authorized(f: Figure, path: PackedVector2Array, cost: float, ignored: Array[int],cape: bool=false) -> void:
	ControllerMovement._move_authorized(self, f, path, cost, ignored, cape)


func _apply_move(f: Figure, path: PackedVector2Array, cost: float, intercept: Dictionary) -> bool:
	return ControllerMovement._apply_move(self, f, path, cost, intercept)


## One non-move action (fight, shoot, reload) per activation.
func can_act(for_fight: bool = false) -> bool:
	var f := state.active()
	if not for_fight and FuryRules.target(state, f) != null:
		return false
	return state.pending_gutter<0 and not awaiting_reaction() and state.pending_cast.is_empty() and f != null and f.in_play() and f.actions_left > 0 and not f.spell_effects.has("plane_walk") and (f.non_moves<2 if RedKingMind.is_wizard(state,f) else (not f.acted or (f.used_stored_action and f.non_moves == 1 and (f.moves_taken > 0 or f.actions_left >= 2)))) and not state.group.movement_pass()


func can_fight(target_id: int) -> bool:
	var t := state.figure(target_id)
	return can_act(true) and not state.active().spell_effects.has("blinding_light") and t != null and not (RedKingMadMan.hunter(state.active()) and RedKingMadMan.is_ryce(t)) and not WormRider.ignored(state.active(),t) and Contact.enemies_of(state.figures,state.active()).has(t)


func fight(target_id: int) -> bool:
	return BattleRecord.run(self,"fight",{"target":target_id},func() -> bool: return ControllerCombat.fight(self, target_id))


func finish_fate_fight(f: Figure, t: Figure, res: Dictionary) -> void:
	ControllerCombat.finish_fate_fight(self, f, t, res)


func _auto_tie_withdraw() -> void:
	ControllerCombat._auto_tie_withdraw(self)


func can_shoot(target_id: int,wraith: bool=false,ammo: bool=false) -> bool:
	var t := state.figure(target_id)
	return can_act() and t != null and not RedKingMadMan.is_ryce(t) and not BeautyActions.blocked(state, state.active(), t) and Shooting.blocked_reason(state.board,state.figures,state.active(),t,wraith,ammo)==""


func shoot(target_id: int,wraith: bool=false,ammo: bool=false) -> bool:
	return BattleRecord.run(self,"shoot",{"target":target_id,"wraith":wraith,"ammo":ammo},func() -> bool: return ControllerCombat.shoot(self, target_id, wraith, ammo))


func _shoot_authorized(f: Figure,t: Figure,wraith: bool=false,ammo: bool=false) -> void:
	ControllerCombat._shoot_authorized(self, f, t, wraith, ammo)


func finish_fate_shot(f: Figure, t: Figure, res: Dictionary, declared: int) -> void:
	ControllerCombat.finish_fate_shot(self, f, t, res, declared)


## Reload may replace the movement action (p. 34); never while engaged.
func can_reload() -> bool:
	var f := state.active()
	return not awaiting_reaction() and state.pending_cast.is_empty() and not state.group.movement_pass() and f != null and f.in_play() and f.actions_left > 0 and not f.spell_effects.has("plane_walk") and f.ranged != null and f.ranged.needs_reload and not f.loaded and not Contact.in_combat(state.figures, f) and FuryRules.target(state, f) == null and (f.moves_taken == 0 or can_act())


func reload() -> bool:
	return BattleRecord.run(self,"reload",{},func() -> bool: return ControllerCombat.reload_weapon(self))


func can_end_activation() -> bool:
	return ControllerActivation.can_end_activation(self)


func end_activation() -> void:
	BattleRecord.run(self,"end_activation",{},func() -> bool:
		if not can_end_activation():
			return false
		ControllerActivation.end_activation(self)
		return true)


func _spend(f: Figure) -> void:
	ControllerActivation._spend(self, f)


func _hurt(f: Figure, dmg: int, by: Figure, combat: bool = true) -> void:
	ControllerCombat._hurt(self, f, dmg, by, combat)


func can_pick_up(id: int) -> bool:
	return _loot.can_pick_up(id)


func pick_up(id: int) -> bool:
	return BattleRecord.run(self,"pick_up",{"id":id},func() -> bool: return _loot.pick_up(id))


func drop_treasure(at: Vector2,token_id: int=-1) -> bool:
	return BattleRecord.run(self,"drop_treasure",{"at":at,"token":token_id},func() -> bool: return _loot.drop(at,token_id))


func exit_table(node: Vector2i) -> bool:
	return BattleRecord.run(self,"exit_table",{"node":node},func() -> bool: return _loot.exit_table(node))


func can_drop_treasure(at: Vector2) -> bool:
	return _loot.can_drop(at)


func can_exit_table(node: Vector2i, r: MoveReach = null) -> bool:
	return _loot.can_exit(node, r)


func can_finish_early_phase() -> bool:
	return not state.over and state.active_id == -1 and not state.group.in_progress() and state.early.can_finish(state, state.current_side())


func finish_early_phase() -> bool:
	return BattleRecord.run(self,"finish_early_phase",{},func() -> bool:
		if not can_finish_early_phase():
			return false
		var side := state.current_side()
		state.early.closed[side] = true
		emit("early_phase_finished", {"side": side})
		_flow.after_activation()
		return true)


func can_begin_group() -> bool:
	return not state.over and not state.pending_initiative and state.active_id == -1 and state.group.can_begin(state, state.current_side())


func begin_group(ids: Array[int]) -> bool:
	return BattleRecord.run(self,"begin_group",{"ids":ids.duplicate()},func() -> bool:
		if not can_begin_group() or not state.group.begin(state, state.current_side(), ids):
			return false
		emit("group_begin", {"side": state.current_side(), "ids": ids.duplicate()})
		return true)


func can_push(own_figure: bool,distance: float=1.0) -> bool:
	if not state.board.floor_layout.is_empty():
		return LayeredPush.destination(self,own_figure,distance)!=null
	return _displacement.destination(own_figure,distance)!=null


func resolve_push(own_figure: bool,distance: float=1.0) -> bool:
	return BattleRecord.run(self,"resolve_push",{"own":own_figure,"distance":distance},func() -> bool:
		if not state.board.floor_layout.is_empty():
			return LayeredPush.apply(self,own_figure,distance)
		return _displacement.push(own_figure,distance))


func stay_in_combat() -> bool:
	return BattleRecord.run(self,"stay_in_combat",{},func() -> bool: return ControllerMovement.stay_in_combat(self))


func can_cast(spell: String, target: int,ammo: bool=false) -> bool:
	return _magic.can_cast(spell, target,ammo)


func start_cast(spell: String, target: int,ammo: bool=false) -> bool:
	return BattleRecord.run(self,"start_cast",{"spell":spell,"target":target,"ammo":ammo},func() -> bool: return _magic.start(spell, target,ammo))


func finish_cast(health: int) -> bool:
	return BattleRecord.run(self,"finish_cast",{"health":health},func() -> bool: return _magic.finish(health))


func cast_max_empowerment() -> int:
	return _magic.max_empowerment()


func answer_initiative(use: bool) -> bool:
	return BattleRecord.run(self,"answer_initiative",{"use":use},func() -> bool: return _flow.answer_initiative(use))


func answer_fate_combat(use: bool) -> bool:
	return BattleRecord.run(self,"answer_fate_combat",{"use":use},func() -> bool: return _fate_combat.answer(use))


func answer_elemental_combat(use: bool) -> bool:
	return BattleRecord.run(self,"answer_elemental_combat",{"use":use},func() -> bool:
		if state.scenario_data.has("rk_lightning_absorb"):
			return RealityLightning.answer(self,use)
		if state.scenario_data.has("rk_spell_absorption"):
			return _magic.answer_absorption(use)
		return _fate_combat.answer_absorption(use))


func awaiting_reaction() -> bool:
	if not CoreScenarioChoice.pending(self).is_empty() or not MeleeWeaponChoice.pending(self).is_empty():
		return true
	if state.scenario_data.has("rk_end_choice") or state.scenario_data.has("rk_priority_choice") or state.scenario_data.has("rk_spell_absorption") or state.scenario_data.has("rk_direction_choice") or state.scenario_data.has("rk_lightning_absorb") or state.scenario_data.has("rk_worm_relocation"):
		return true
	if not state.pending_combat.is_empty() or state.pending_initiative or not state.pending_intercept.is_empty() or not state.pending_resistance.is_empty():
		return true
	if state.push_winner < 0:
		return false
	var winner := state.figure(state.push_winner)
	return winner != null and winner.side == state.reaction_side and state.current_side() != state.reaction_side


func answer_intercept(accept: bool) -> bool:
	return BattleRecord.run(self,"answer_intercept",{"accept":accept},func() -> bool: return ControllerMovement.answer_intercept(self, accept))


func poison(f: Figure) -> void:
	ControllerCombat.poison(self, f)


func can_use_stored_action() -> bool:
	var f := state.active()
	return not awaiting_reaction() and state.pending_cast.is_empty() and f != null and f.in_play() and not state.group.in_progress() and f.spell_effects.has("time_store") and f.stored_action_turn < state.turn and not f.used_stored_action and f.action_limit() == 2 and f.actions_left == 2 and not f.acted and f.moves_taken == 0


func use_stored_action() -> bool:
	return BattleRecord.run(self,"use_stored_action",{},func() -> bool:
		if not can_use_stored_action():
			return false
		var f := state.active()
		f.spell_effects.erase("time_store")
		f.used_stored_action = true
		f.actions_left += 1
		emit("stored_action", {"id": f.id})
		return true)


func can_fight_hand(id: int) -> bool:
	var f := state.active()
	var t := state.figure(id)
	return can_act(true) and not f.spell_effects.has("blinding_light") and t != null and t.in_play() and t.spell_effects.has("bones_of_the_earth") and (f == t or Contact.figures_touch(f, t))


func fight_hand(id: int) -> bool:
	return BattleRecord.run(self,"fight_hand",{"id":id},func() -> bool:
		return ControllerCombat.fight_hand(self, id))


func _weapon_damage(t: Figure, dmg: int, f: Figure, w: WeaponDef) -> void:
	ControllerCombat._weapon_damage(self, t, dmg, f, w)


func selectable_melee() -> Array[WeaponDef]:
	var out: Array[WeaponDef] = []
	var f := state.active()
	if f == null or not f.in_play() or f.acted or awaiting_reaction() or not state.pending_cast.is_empty() or state.push_winner >= 0 or not _magic.shatter.first.is_empty():
		return out
	for w in f.def.weapons:
		if w.melee and w != f.melee and not f.destroyed_weapons.has(w.id):
			out.append(w)
	return out


func select_melee(id: String) -> bool:
	return BattleRecord.run(self,"select_melee",{"id":id},func() -> bool:
		for w in selectable_melee():
			if w.id == id:
				var f := state.active()
				WeaponEnchantment.migrate(f)
				f.melee = w
				emit("weapon_selected", {"id": f.id, "weapon": id})
				return true
		return false)


func can_drink_well() -> bool:
	return ScenarioObjectives.can_drink(self)


func drink_well() -> bool:
	return BattleRecord.run(self,"drink_well",{},func() -> bool:
		return ScenarioObjectives.drink(self))


func can_break_ice() -> bool:
	return ScenarioObjectives.can_break_ice(self)


func break_ice() -> bool:
	return BattleRecord.run(self,"break_ice",{},func() -> bool: return ScenarioObjectives.break_ice(self))
