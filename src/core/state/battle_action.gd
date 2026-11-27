class_name BattleAction
extends RefCounted
## Shared typed command entry point. Legality remains owned by the controller.
const TARGETED := ["fight","shoot","ammo_shot","wraith_shot","cast"]


static func legal(c: GameController,key: String,target: int=-1,spell: String="") -> bool:
	match key:
		"fight": return c.can_fight(target)
		"shoot","ammo_shot","wraith_shot": return c.can_shoot(target,key=="wraith_shot",key=="ammo_shot")
		"cast": return c.can_cast(spell,target)
		"reload": return c.can_reload()
	return false


static func execute(c: GameController,key: String,target: int=-1,spell: String="") -> bool:
	if not legal(c,key,target,spell):
		return false
	var rng_before := c.dice._rng.state
	var first := c.history.size()
	var accepted := false
	match key:
		"fight": accepted=c.fight(target)
		"shoot","ammo_shot","wraith_shot": accepted=c.shoot(target,key=="wraith_shot",key=="ammo_shot")
		"cast": accepted=c.start_cast(spell,target)
		"reload": accepted=c.reload()
	if accepted:
		c.command_history.append({"key":key,"target":target,"spell":spell,"rng_before":rng_before,"rng_after":c.dice._rng.state,"event_start":first,"event_end":c.history.size()})
	return accepted
