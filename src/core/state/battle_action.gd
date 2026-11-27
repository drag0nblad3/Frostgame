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
	match key:
		"fight": return c.fight(target)
		"shoot","ammo_shot","wraith_shot": return c.shoot(target,key=="wraith_shot",key=="ammo_shot")
		"cast": return c.start_cast(spell,target)
		"reload": return c.reload()
	return false
