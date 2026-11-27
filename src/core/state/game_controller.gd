class_name GameController
extends RefCounted
## The only thing that changes GameState. Players and bots call its actions;
## every change is announced as a GameEvent.

signal event_emitted(e: GameEvent)

var state: GameState
var dice: Dice
var history: Array[GameEvent] = []
var _flow: TurnFlow
var _loot: TreasureActions
var _displacement: CombatDisplacement
var _encounters: EncounterActions
var _magic: SpellActions
var _potions: PotionActions
var _fate_combat: FateCombat


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


func emit(type: String, data: Dictionary = {}) -> void:
	var e := GameEvent.new(type, data)
	history.append(e)
	HolyLantern.observe(self,type,data)
	event_emitted.emit(e)
	if RedKingInvestigations.active(state):
		RedKingInvestigations.observe_event(self,type,data)


func start_game() -> void:
	DeathMask.prepare(self)
	CircletDefence.prepare(self)
	ScrollShield.prepare(self)
	RedKingGear.foulhorn_brawl(self)
	RedKingInvestigations.prepare(self)
	RedKingVeil.prepare(self)
	RedKingMind.prepare(self)
	_flow.start_turn()


## Figures the side to play may activate now.
func activatable() -> Array[Figure]:
	if state.over or state.pending_initiative or state.scenario_data.has("rk_end_choice") or state.scenario_data.has("rk_priority_choice"):
		var none: Array[Figure] = []
		return none
	return state.waiting(state.current_side())


func activate(id: int) -> bool:
	var f := state.figure(id)
	if state.active_id != -1 or f == null or not activatable().has(f):
		return false
	f = PackRules.select(self, f)
	id = f.id
	state.active_id = id
	var time_walk := f.spell_effects.has("time_walk") and f.walk_phases.has(state.phase)
	var fast := state.is_fast(f)
	if not state.group.in_progress() or state.group.movement_pass():
		RedKingInvestigations.before_activation(self,f)
	if not state.group.in_progress() or state.group.movement_pass():
		_magic.on_activate(f)
	if state.group.in_progress():
		state.group.start_member(state, f)
	else:
		if not fast and not time_walk:
			state.early.record_activation(state, f)
		f.actions_left = mini(f.action_limit(), 1) if time_walk else f.action_limit()
		if time_walk:
			f.walk_phases.erase(state.phase)
		else:
			f.moves_taken = 0
		f.acted = false
		f.non_moves = 0
		f.used_stored_action = false
	emit("activate", {"id": id})
	RedKingInvestigations.activation(self,f)
	RedKingVeil.activation(self,f)
	RedKingMind.activation(self,f)
	RealityCracks.activation(self,f)
	RedKingSquatter.record_contact(self)
	if not state.group.in_progress() or state.group.movement_pass():
		CreatureEffects.activation(self,f)
		RedKingSinkhole.activation(self,f)
	HolyLantern.flee(self,f)
	if not f.in_play():
		f.actions_left=0
	return true


func can_move() -> bool:
	var f := state.active()
	return state.pending_gutter<0 and not awaiting_reaction() and state.pending_cast.is_empty() and f != null and f.in_play() and f.actions_left > 0 and (not RedKingMind.is_wizard(state,f) or f.moves_taken==0) and MoveRules.can_move(f, state.figures)


## Where the active figure could go with its next movement action.
## Explicit experimental API; do not allow legacy two-dimensional moves on layered maps.
func layered_reach() -> LayeredReach:
	return LayeredMovement.reach(self)


func move_on_floor(node: Vector3i) -> bool:
	return LayeredMovement.move(self,node)


func floor_exit_nodes() -> Array[Vector3i]:
	return LayeredLoot.exit_nodes(self)


func exit_on_floor(node: Vector3i) -> bool:
	return LayeredLoot.exit(self,node)


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


func reach() -> MoveReach:
	if not state.board.floor_layout.is_empty():
		return MoveReach.new()
	var f := state.active()
	if f.spell_effects.has("plane_walk"):
		return PlaneWalk.reach(state, f)
	if f.spell_effects.has("potion_burrowing") or f.def.traits.has("ethereal") or f.def.traits.has("burrowing"):
		return PlaneWalk.reach(state, f, false)
	var grid := MoveGrid.new(state.board, f, state.figures)
	var r := MovePlanner.straight_reach(grid,f.pos,MoveRules.allowance(f)) if state.board.low_gravity else MovePlanner.reach(grid, f.pos, MoveRules.allowance(f))
	return FuryRules.restrict(state, f, r)


func move_to(node: Vector2i,cape: bool=false) -> bool:
	if not (GearActions.cape_ready(self) if cape else can_move()):
		return false
	var r := reach()
	if not r.can_reach(node) or (cape and float(r.cost[node])<=0.001):
		return false
	var f := state.active()
	var path := r.path_to(node)
	if not RedKingHill.before_move(self,f):
		return true
	if f.spell_effects.has("plane_walk"):
		if state.scenario_special == "silent_tower":
			for i in range(1, path.size()):
				if ScenarioNull.field_at(state.board, path[i]):
					return false
		if RedKingMind.active(state):
			for i in range(1,path.size()):
				RedKingMind.collect(self,f,path[i-1],path[i])
		if RedKingHerded.active(state):
			for i in range(1,path.size()):
				if RedKingHerded.contact(self,f,path[i]):
					f.actions_left=0
					return true
		f.pos = MoveGrid.to_pos(node)
		f.elevation = state.board.height_at(f.pos)
		f.actions_left -= 1
		f.moves_taken += 1
		emit("move", {"id": f.id, "path": path, "cost": float(r.cost[node])})
		ScenarioSites.end_move(self, f)
		return true
	var ignored: Array[int]=[]
	if cape:
		for enemy in Contact.enemies_of(state.figures,f):
			ignored.append(enemy.id)
	return _commit_move(f,path,float(r.cost[node]),ignored,cape)


func _commit_move(f: Figure, path: PackedVector2Array, cost: float, ignored: Array[int],cape: bool=false) -> bool:
	var targets: Array[Figure] = []
	var at := path[path.size() - 1]
	for t in state.figures:
		if t.in_play() and t.ring_side==f.ring_side and t.side != f.side and absf(t.elevation - state.board.height_at(at)) < 0.5 and Contact.touching(t.pos, at):
			targets.append(t)
	_magic.beauty.authorize(f, targets, _move_authorized.bind(f,path,cost,ignored,cape))
	return true


func _move_authorized(f: Figure, path: PackedVector2Array, cost: float, ignored: Array[int],cape: bool=false) -> void:
	if not f.in_play() or (cape and not GearActions.use_cape(self,f)):
		return
	var intercept := _displacement.intercept(f, path, ignored) if state.forced_combat else {}
	if not intercept.is_empty() and int(intercept["guard"].side) == state.reaction_side:
		state.pending_intercept = {"mover": f.id, "path": path, "cost": cost, "ignored": ignored, "choice": intercept}
		emit("intercept_offer", {"id": intercept["guard"].id, "target": f.id})
		return
	_apply_move(f, path, cost, intercept)


func _apply_move(f: Figure, path: PackedVector2Array, cost: float, intercept: Dictionary) -> bool:
	var engaged := Contact.in_combat(state.figures,f)
	if not intercept.is_empty():
		path.resize(int(intercept["index"]) + 1)
	f.spell_effects.erase("petrify")
	f.actions_left -= 1
	f.moves_taken += 1
	if not _magic.terrain.travel(f, path, cost):
		if f.in_play():
			CreatureSenses.reveal_contacts(self,f)
			_magic.illusions.after_move(f)
			GearActions.gutter_after_move(self,f,engaged)
		return true
	if not intercept.is_empty():
		_displacement.force_contact(intercept)
	ScenarioSites.end_move(self, f)
	RedKingSquatter.record_contact(self)
	RedKingSinkhole.record_xp(self,f)
	CreatureSenses.reveal_contacts(self,f)
	_magic.illusions.after_move(f)
	GearActions.gutter_after_move(self,f,engaged)
	return true


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
	if not can_fight(target_id):
		return false
	var f := state.active()
	var t := state.figure(target_id)
	CreatureBot.apply_mask_cost(state,f,t)
	_spend(f)
	_fate_combat.start(f, t, "fight")
	return true


func finish_fate_fight(f: Figure, t: Figure, res: Dictionary) -> void:
	res["id"] = f.id
	res["target"] = t.id
	emit("fight", res)
	_magic.illusions.reveal(f)
	_magic.illusions.reveal(t)
	var a_weapon := f.melee
	var b_weapon := t.melee
	if RedKingMadMan.is_ryce(t):
		if int(res["b_dmg"])>0:
			RedKingMadMan.knock_out(self,t,f)
		return
	var a_gear := RedKingGear.before_fight(state.figures,f,t)
	var b_gear := RedKingGear.before_fight(state.figures,t,f)
	var before_a := f.health
	var before_b := t.health
	_weapon_damage(t,RedKingElemental.weapon_damage(self,f,t,int(res["b_dmg"]),int(res["a_roll"]),false,int(res.get("elemental_choices",{}).get(t.id,-1))),f,a_weapon)
	_weapon_damage(f,RedKingElemental.weapon_damage(self,t,f,int(res["a_dmg"]),int(res["b_roll"]),false,int(res.get("elemental_choices",{}).get(f.id,-1))),t,b_weapon)
	var actual := res.duplicate()
	actual["a_dmg"]=maxi(0,before_a-f.health)
	actual["b_dmg"]=maxi(0,before_b-t.health)
	RedKingGear.after_fight(self,f,t,a_gear,int(res["a_roll"]),int(res["b_dmg"]),int(actual["b_dmg"]),int(res["winner"]))
	RedKingGear.after_fight(self,t,f,b_gear,int(res["b_roll"]),int(res["a_dmg"]),int(actual["a_dmg"]),int(res["winner"]))
	CreatureEffects.after_fight(self,f,t,actual,a_weapon,b_weapon)
	if int(res["b_dmg"]) > 0:
		f.spell_effects.erase("elemental_hammer")
	if int(res["a_dmg"]) > 0:
		t.spell_effects.erase("elemental_hammer")
	if f.in_play() and t.in_play() and Contact.figures_touch(f,t) and int(res["winner"]) >= 0:
		var winner := state.figure(res["winner"])
		if not RedKingTethers.pylon(f) and not RedKingTethers.pylon(t) and (winner.side >= 0 or RedKingHill.is_herald(state,winner) or (RedKingRingworld.active(state) and RedKingRingworld.key_master(winner))):
			state.push_winner = winner.id
			state.push_loser = t.id if winner == f else f.id
			if RedKingHill.is_herald(state,winner) or RedKingRingworld.key_master(winner):
				_displacement.push(false)
	elif f.in_play() and t.in_play() and Contact.figures_touch(f,t) and int(res["winner"])<0 and not RedKingTethers.pylon(f) and not RedKingTethers.pylon(t):
		var first: Figure=null
		var other: Figure=null
		if CombatDisplacement.boots(f) and f.side>=0:
			first=f
			other=t
		if CombatDisplacement.boots(t) and t.side>=0 and (first==null or t.side==state.reaction_side):
			first=t
			other=f
		if first!=null:
			state.push_winner=first.id
			state.push_loser=other.id
			state.push_tie=true
			state.push_tie_second=CombatDisplacement.boots(other) and other.side>=0
			if first.side!=state.reaction_side and first!=state.active():
				_auto_tie_withdraw()


func _auto_tie_withdraw() -> void:
	var f := state.figure(state.push_winner)
	if f!=null and f.treasure_id>=0:
		for distance in [3.0,2.0,1.0,0.5]:
			if resolve_push(true,distance):
				return
	stay_in_combat()


func can_shoot(target_id: int,wraith: bool=false,ammo: bool=false) -> bool:
	var t := state.figure(target_id)
	return can_act() and t != null and not RedKingMadMan.is_ryce(t) and not BeautyActions.blocked(state, state.active(), t) and Shooting.blocked_reason(state.board,state.figures,state.active(),t,wraith,ammo)==""


func shoot(target_id: int,wraith: bool=false,ammo: bool=false) -> bool:
	if not can_shoot(target_id,wraith,ammo):
		return false
	var f := state.active()
	var t := state.figure(target_id)
	_magic.beauty.authorize(f, ShotTarget.participants(state.figures, t), _shoot_authorized.bind(f,t,wraith,ammo))
	return true


func _shoot_authorized(f: Figure,t: Figure,wraith: bool=false,ammo: bool=false) -> void:
	if not f.in_play() or not t.in_play() or (wraith and not ActiveGear.spend(f,Shooting.WRAITH)):
		return
	if ammo and not MagicAmmo.spend(f):
		return
	_magic.illusions.reveal(f)
	var declared := t.id
	t = ShotTarget.randomize(dice, state.figures, t)
	_spend(f)
	if f.ranged.needs_reload:
		f.loaded = false
	_fate_combat.start(f,t,"shoot",declared,wraith,ammo)


func finish_fate_shot(f: Figure, t: Figure, res: Dictionary, declared: int) -> void:
	res["declared"] = declared
	res["id"] = f.id
	res["target"] = t.id
	emit("shoot", res)
	_weapon_damage(t,RedKingElemental.weapon_damage(self,f,t,int(res["dmg"]),int(res["s_roll"]),true,int(res.get("elemental_choices",{}).get(t.id,-1))),f,f.ranged)
	if f.spell_effects.get("potion_fairy_dust", "") == f.ranged.id:
		f.spell_effects.erase("potion_fairy_dust")
	if f.ranged != null:
		f.spell_effects.erase("elemental_hammer")
	if res.get("wraith",false) and f.in_play():
		var raw := dice.d20()
		var success := StatRoll.succeeds(raw,f.effective_will()+f.roll_penalty(),8)
		if not success:
			f.spell_effects["curse"]=14
		emit("creature_test",{"id":f.id,"trait":"wraith_bow","roll":raw,"success":success})


## Reload may replace the movement action (p. 34); never while engaged.
func can_reload() -> bool:
	var f := state.active()
	return not awaiting_reaction() and state.pending_cast.is_empty() and not state.group.movement_pass() and f != null and f.in_play() and f.actions_left > 0 and not f.spell_effects.has("plane_walk") and f.ranged != null and f.ranged.needs_reload and not f.loaded and not Contact.in_combat(state.figures, f) and FuryRules.target(state, f) == null and (f.moves_taken == 0 or can_act())


func reload() -> bool:
	if not can_reload():
		return false
	var f := state.active()
	if f.moves_taken > 0:
		_spend(f)
	else:
		f.actions_left -= 1
	f.loaded = true
	emit("reload", {"id": f.id})
	return true


func can_end_activation() -> bool:
	var f := state.active()
	if f == null or state.pending_gutter>=0 or awaiting_reaction() or not state.pending_cast.is_empty():
		return false
	if FuryRules.target(state, f) == null or f.actions_left <= 0:
		return true
	for t in Contact.enemies_of(state.figures, f):
		if can_fight(t.id):
			return false
	if can_move() and not reach().nodes().is_empty():
		return false
	return true


func end_activation() -> void:
	if not can_end_activation():
		return
	_displacement.clear()
	var f := state.active()
	if f == null:
		return
	state.active_id = -1
	f.actions_left = 0
	emit("end_activation", {"id": f.id})
	if state.group.in_progress():
		var before := state.group.stage
		if before == GroupActivation.SECOND:
			_magic.on_end_activation(f)
		var complete := state.group.finish_member(state, f)
		if complete:
			emit("group_complete", {"side": f.side})
			_flow.after_activation()
		elif before != state.group.stage:
			emit("group_second", {"side": f.side})
		return
	f.activated = true
	_magic.on_end_activation(f)
	PackRules.finish(state, f)
	_flow.after_activation()


func _spend(f: Figure) -> void:
	_displacement.clear()
	f.actions_left -= 1
	f.acted = true
	f.non_moves += 1


func _hurt(f: Figure, dmg: int, by: Figure, combat: bool = true) -> void:
	if RedKingMadMan.is_ryce(f):
		return
	if dmg <= 0 or not f.in_play() or (f.spell_effects.has("plane_walk") and by != f) or (combat and by != f and IllusionRules.phantom(by)):
		return
	if IllusionRules.phantom(f):
		_magic.summons.vanish(f)
		return
	if combat and f.elemental_shield > 0:
		var absorbed := mini(dmg, f.elemental_shield)
		f.elemental_shield -= absorbed
		dmg -= absorbed
		emit("shield_absorb", {"id": f.id, "amount": absorbed})
		if dmg == 0:
			return
	var was_wounded := f.wounded()
	var out := Damage.apply(f, dmg)
	if not was_wounded and f.wounded() and state.active()==f:
		f.actions_left=mini(f.actions_left,0 if f.acted or f.moves_taken>0 else 1)
	if f.familiar and f.health <= 1:
		f.familiar = false
		f.def = f.def.with_bonuses({"health": -2})
		emit("familiar_lost", {"id": f.id})
	if combat and not out and by != f and by.def.traits.has("poison"):
		poison(f)
	emit("damage", {"id": f.id, "by": by.id, "amount": dmg, "health": f.health})
	if out:
		_loot.drop_on_death(f)
		emit("out_of_action", {"id": f.id, "by": by.id})
		ScenarioGenie.record_kill(self, f, by)
		RedKingSquatter.record_kill(self,f,by)
		RedKingTethers.destroyed(self,f,by)
		_magic.summons.enforce_illusion_limit(f)
	else:
		CreatureEffects.after_damage(self,f)


func can_pick_up(id: int) -> bool:
	return _loot.can_pick_up(id)


func pick_up(id: int) -> bool:
	return _loot.pick_up(id)


func drop_treasure(at: Vector2) -> bool:
	return _loot.drop(at)


func exit_table(node: Vector2i) -> bool:
	return _loot.exit_table(node)


func can_drop_treasure(at: Vector2) -> bool:
	return _loot.can_drop(at)


func can_exit_table(node: Vector2i, r: MoveReach = null) -> bool:
	return _loot.can_exit(node, r)


func can_finish_early_phase() -> bool:
	return not state.over and state.active_id == -1 and not state.group.in_progress() and state.early.can_finish(state, state.current_side())


func finish_early_phase() -> bool:
	if not can_finish_early_phase():
		return false
	var side := state.current_side()
	state.early.closed[side] = true
	emit("early_phase_finished", {"side": side})
	_flow.after_activation()
	return true


func can_begin_group() -> bool:
	return not state.over and not state.pending_initiative and state.active_id == -1 and state.group.can_begin(state, state.current_side())


func begin_group(ids: Array[int]) -> bool:
	if not can_begin_group() or not state.group.begin(state, state.current_side(), ids):
		return false
	emit("group_begin", {"side": state.current_side(), "ids": ids.duplicate()})
	return true


func can_push(own_figure: bool,distance: float=1.0) -> bool:
	if not state.board.floor_layout.is_empty():
		return LayeredPush.destination(self,own_figure,distance)!=null
	return _displacement.destination(own_figure,distance)!=null


func resolve_push(own_figure: bool,distance: float=1.0) -> bool:
	if not state.board.floor_layout.is_empty():
		return LayeredPush.apply(self,own_figure,distance)
	return _displacement.push(own_figure,distance)


func stay_in_combat() -> bool:
	if state.push_winner < 0:
		return false
	if state.push_tie and state.push_tie_second:
		var old := state.push_winner
		state.push_winner=state.push_loser
		state.push_loser=old
		state.push_tie_second=false
		var other := state.figure(state.push_winner)
		if other!=null and other.side!=state.reaction_side:
			_auto_tie_withdraw()
		return true
	_displacement.clear()
	emit("stay_in_combat")
	return true


func can_cast(spell: String, target: int,ammo: bool=false) -> bool:
	return _magic.can_cast(spell, target,ammo)


func start_cast(spell: String, target: int,ammo: bool=false) -> bool:
	return _magic.start(spell, target,ammo)


func finish_cast(health: int) -> bool:
	return _magic.finish(health)


func cast_max_empowerment() -> int:
	return _magic.max_empowerment()


func answer_initiative(use: bool) -> bool:
	return _flow.answer_initiative(use)


func answer_fate_combat(use: bool) -> bool:
	return _fate_combat.answer(use)


func answer_elemental_combat(use: bool) -> bool:
	if state.scenario_data.has("rk_lightning_absorb"):
		return RealityLightning.answer(self,use)
	if state.scenario_data.has("rk_spell_absorption"):
		return _magic.answer_absorption(use)
	return _fate_combat.answer_absorption(use)


func awaiting_reaction() -> bool:
	if state.scenario_data.has("rk_end_choice") or state.scenario_data.has("rk_priority_choice") or state.scenario_data.has("rk_spell_absorption") or state.scenario_data.has("rk_direction_choice") or state.scenario_data.has("rk_lightning_absorb"):
		return true
	if not state.pending_combat.is_empty() or state.pending_initiative or not state.pending_intercept.is_empty() or not state.pending_resistance.is_empty():
		return true
	if state.push_winner < 0:
		return false
	var winner := state.figure(state.push_winner)
	return winner != null and winner.side == state.reaction_side and state.current_side() != state.reaction_side


func answer_intercept(accept: bool) -> bool:
	var p := state.pending_intercept
	if p.is_empty():
		return false
	state.pending_intercept = {}
	var mover := state.figure(p["mover"])
	var choice: Dictionary = p["choice"]
	var path: PackedVector2Array = p["path"]
	if accept:
		return _apply_move(mover, path, float(p["cost"]), choice)
	var ignored: Array[int] = []
	ignored.assign(p["ignored"])
	ignored.append(choice["guard"].id)
	return _commit_move(mover, path, float(p["cost"]), ignored)


func poison(f: Figure) -> void:
	if not f.in_play() or f.immune_to_poison() or f.poisoned:
		return
	f.poisoned = true
	if state.active() == f:
		f.actions_left = mini(f.actions_left, 0 if f.acted or f.moves_taken > 0 else 1)
	emit("poison", {"id": f.id})


func can_use_stored_action() -> bool:
	var f := state.active()
	return not awaiting_reaction() and state.pending_cast.is_empty() and f != null and f.in_play() and not state.group.in_progress() and f.spell_effects.has("time_store") and f.stored_action_turn < state.turn and not f.used_stored_action and f.action_limit() == 2 and f.actions_left == 2 and not f.acted and f.moves_taken == 0


func use_stored_action() -> bool:
	if not can_use_stored_action():
		return false
	var f := state.active()
	f.spell_effects.erase("time_store")
	f.used_stored_action = true
	f.actions_left += 1
	emit("stored_action", {"id": f.id})
	return true


func can_fight_hand(id: int) -> bool:
	var f := state.active()
	var t := state.figure(id)
	return can_act(true) and not f.spell_effects.has("blinding_light") and t != null and t.in_play() and t.spell_effects.has("bones_of_the_earth") and (f == t or Contact.figures_touch(f, t))


func fight_hand(id: int) -> bool:
	if not can_fight_hand(id):
		return false
	var f := state.active()
	var t := state.figure(id)
	var support := 0
	for ally in state.figures:
		if ally != f and ally.in_play() and ally.side == f.side and (ally == t or Contact.figures_touch(ally, t)):
			support += 2
	var attack := dice.d20() + mini(f.effective_fight() + f.melee.fight_mod + MagicEquipment.bonus(f, "fight", f.melee.id) + mini(6, support), 10) + f.roll_penalty()
	var defend := dice.d20()
	_spend(f)
	var freed := attack >= defend and attack + f.melee.damage_mod + MagicEquipment.bonus(f, "damage", f.melee.id) > 10
	if freed:
		t.spell_effects.erase("bones_of_the_earth")
		emit("spell_expired", {"id": t.id, "spell": "bones_of_the_earth"})
	if defend >= attack:
		_hurt(f, maxi(0, defend - f.effective_armour() + f.melee.enemy_damage_mod), t)
	emit("fight_hand", {"id": f.id, "target": id, "attack": attack, "defence": defend, "freed": freed})
	return true


func _weapon_damage(t: Figure, dmg: int, f: Figure, w: WeaponDef) -> void:
	var old := t.health
	_hurt(t, dmg, f)
	if t.health<old:
		RedKingHill.balance(self,t)
	if t.health < old and f.poison_weapon == w.id:
		f.poison_weapon = ""
		poison(t)



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
	for w in selectable_melee():
		if w.id == id:
			var f := state.active()
			f.melee = w
			emit("weapon_selected", {"id": f.id, "weapon": id})
			return true
	return false



func can_drink_well() -> bool:
	return ScenarioObjectives.can_drink(self)


func drink_well() -> bool:
	return ScenarioObjectives.drink(self)



func can_break_ice() -> bool:
	return ScenarioObjectives.can_break_ice(self)


func break_ice() -> bool:
	return ScenarioObjectives.break_ice(self)
