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


## These sources have an explicit continuation; synchronous callers still use pick().
static func human_bearer(c: GameController) -> Figure:
	for f in c.state.figures:
		if f.in_play() and f.side==c.state.reaction_side and ActiveGear.ready(f,ITEM):
			return f
	return null


static func offer(c: GameController,kind: String,target: Figure,caster: Figure=null,extend: bool=false) -> bool:
	var bearer := human_bearer(c)
	var gem := caster!=null and caster.side==c.state.reaction_side and caster.in_play() and ActiveGear.has(caster,PowerPool.GEM) and not MagicEquipment.suppressed(caster)
	if bearer==null and not gem:
		return false
	var choice := {"kind":kind,"target":target.id,"caster":-1 if caster==null else caster.id,"teetotum":-1 if bearer==null else bearer.id,"gem":gem,"extend":extend,"heading":c.dice.pick(20)}
	c.state.scenario_data["rk_direction_choice"]=choice
	c.emit("direction_offer",{"id":target.id,"heading":choice["heading"],"kind":kind})
	return true


static func vector(heading: int) -> Vector2:
	return Vector2.RIGHT.rotated(TAU*float(heading)/20.0)


static func answer(c: GameController,method: String) -> bool:
	var s := c.state
	var choice: Dictionary=s.scenario_data.get("rk_direction_choice",{})
	if choice.is_empty() or method not in ["keep","teetotum","gem"]:
		return false
	var target := s.figure(int(choice["target"]))
	var caster := s.figure(int(choice["caster"]))
	var heading := int(choice["heading"])
	if target==null or not target.in_play():
		return false
	if method=="teetotum":
		var bearer := s.figure(int(choice["teetotum"]))
		if bearer==null or bearer.side!=s.reaction_side or not ActiveGear.spend(bearer,ITEM):
			return false
		bearer.used_gear.erase(ARMED)
		var second := c.dice.pick(20)
		c.emit("direction_reroll",{"id":bearer.id,"first":heading,"second":second,"count":20})
		heading=second
	elif method=="gem":
		if not choice["gem"] or caster==null:
			return false
		var second := c.dice.pick(20)
		c.emit("direction_reroll",{"id":caster.id,"first":heading,"second":second,"count":20})
		heading=second
	s.scenario_data.erase("rk_direction_choice")
	if choice["kind"]=="blink":
		c._magic.movement.finish_blink(caster,target,vector(heading),bool(choice["extend"]),method=="gem")
		c._magic.advance_shatter()
	elif choice["kind"]=="ryce":
		RedKingMadMan.wander(c,target,vector(heading))
		RedKingMadMan.after_wander(c)
		if not s.scenario_data.has("rk_end_choice"):
			c._flow.resume_end_turn()
	return true
