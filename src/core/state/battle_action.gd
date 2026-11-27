class_name BattleAction
extends RefCounted
## Shared typed command entry point. Legality remains owned by the controller.
const TARGETED := ["fight","shoot","ammo_shot","wraith_shot","cast","collect","fight_hand"]


static func legal(c: GameController,key: String,target: int=-1,spell: String="",ammo: bool=false) -> bool:
	match key:
		"fight": return c.can_fight(target)
		"shoot","ammo_shot","wraith_shot": return c.can_shoot(target,key=="wraith_shot",key=="ammo_shot")
		"cast": return c.can_cast(spell,target,ammo)
		"reload": return c.can_reload()
		"end": return c.can_end_activation()
		"collect": return c.can_pick_up(target)
		"fight_hand": return c.can_fight_hand(target)
		"pass_phase": return c.can_finish_early_phase()
		"drink_well": return c.can_drink_well()
		"break_ice": return c.can_break_ice()
		"use_stored_action": return c.can_use_stored_action()
	return false


static func execute(c: GameController,key: String,target: int=-1,spell: String="",ammo: bool=false) -> bool:
	if not legal(c,key,target,spell,ammo):
		return false
	match key:
		"fight": return c.fight(target)
		"shoot","ammo_shot","wraith_shot": return c.shoot(target,key=="wraith_shot",key=="ammo_shot")
		"cast": return c.start_cast(spell,target,ammo)
		"reload": return c.reload()
		"collect": return c.pick_up(target)
		"fight_hand": return c.fight_hand(target)
		"pass_phase": return c.finish_early_phase()
		"drink_well": return c.drink_well()
		"break_ice": return c.break_ice()
		"use_stored_action": return c.use_stored_action()
		"end":
			c.end_activation()
			return true
	return false


## No rolls are generated here; legality and geometry are the same as execution.
static func attack_preview(c: GameController,key: String,target: int) -> Dictionary:
	if key not in ["fight","shoot","ammo_shot","wraith_shot"] or not legal(c,key,target):
		return {}
	var actor := c.state.active()
	var defender := c.state.figure(target)
	var out := {"target":target,"health":defender.health,"max_health":defender.def.health,"fight":defender.effective_fight(),"armour":defender.effective_armour(),"cost":1}
	if key=="fight":
		out["weapon"]=actor.melee.name if actor.melee!=null else "Unarmed"
	else:
		out["weapon"]=actor.ranged.name
		out["range"]=BattleSpace.edge_distance(actor,defender)
		out["maximum_range"]=actor.ranged.range_in
		out["defence_modifier"]=Shooting.defence_modifier(c.state.board,actor,defender,key=="wraith_shot")
		out["random_target"]=ShotTarget.participants(c.state.figures,defender).size()>1
	return out
