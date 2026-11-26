class_name RedKingDirection
extends RefCounted

const ITEM := "gear_rk_enchanted_teetotum"
const ARMED := "rk_teetotum_armed"


static func arm(c: GameController) -> bool:
	var f := c.state.active()
	if not ActiveGear.ready(f,ITEM) or not f.in_play():
		return false
	f.used_gear[ARMED]=not f.used_gear.get(ARMED,false)
	return true


static func pick(c: GameController,count: int=20) -> int:
	var first := c.dice.pick(count)
	for f in c.state.figures:
		if not f.in_play() or not f.used_gear.get(ARMED,false) or not ActiveGear.spend(f,ITEM):
			continue
		f.used_gear.erase(ARMED)
		var second := c.dice.pick(count)
		c.emit("direction_reroll",{"id":f.id,"first":first,"second":second,"count":count})
		return second
	return first


static func direction(c: GameController) -> Vector2:
	return Vector2.RIGHT.rotated(TAU*float(pick(c))/20.0)
