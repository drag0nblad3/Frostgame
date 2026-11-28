class_name FateCombat
extends RefCounted
## Resolve ordinary opposed rolls before applying damage, allowing each owner
## one binding reroll of their own die if they have an unused Fate Stone.

const ITEM := "gear_fate_stone"
## The controller owns this helper; avoid a RefCounted ownership cycle.
var _controller_ref: WeakRef
var c: GameController:
	get:
		return _controller_ref.get_ref() as GameController


func _init(controller: GameController) -> void:
	_controller_ref=weakref(controller)


func start(a: Figure, b: Figure, kind: String, declared: int = -1,wraith: bool=false,ammo: bool=false) -> void:
	if kind=="fight":
		if MeleeWeaponChoice.offer(c,a,b):
			return
		if a.side!=c.state.reaction_side:
			MeleeWeaponChoice.auto_select(c,a,b)
		if b.side!=c.state.reaction_side:
			MeleeWeaponChoice.auto_select(c,b,a)
	roll(a,b,kind,declared,wraith,ammo)


func roll(a: Figure,b: Figure,kind: String,declared: int=-1,wraith: bool=false,ammo: bool=false) -> void:
	c.state.pending_combat = {"a": a.id, "b": b.id, "kind": kind, "declared": declared,"wraith":wraith,"ammo":ammo, "rolls": [c.dice.d20(), c.dice.d20()], "stage": 0}
	advance()


func result(p: Dictionary) -> Dictionary:
	var a := c.state.figure(p["a"])
	var b := c.state.figure(p["b"])
	var rolls: Array = p["rolls"]
	if p["kind"] == "fight":
		return Melee.resolve_rolls(c.state.figures, a, b, rolls[0], rolls[1], c.state.critical_hits)
	var res := Shooting.resolve_rolls(c.state.board,a,b,rolls[0],rolls[1],c.state.critical_hits,c.state.storm_penalty,bool(p.get("wraith",false)),bool(p.get("ammo",false)))
	res["wraith"]=p.get("wraith",false)
	res["ammo"]=p.get("ammo",false)
	return res


func advance() -> void:
	var p := c.state.pending_combat
	while int(p["stage"]) < 2:
		var i := int(p["stage"])
		var f := c.state.figure(p["a"] if i == 0 else p["b"])
		if ActiveGear.ready(f, ITEM):
			var r := result(p)
			var melee: bool = p["kind"] == "fight"
			var totals: Array = [r["a_total"], r["b_total"]] if melee else [r["s_total"], r["t_total"]]
			p["roller"] = f.id
			p["roll"] = p["rolls"][i]
			p["own_total"] = totals[i]
			p["opposing_total"] = totals[1 - i]
			if f.side == c.state.reaction_side:
				return
			var losing: bool = r["a_dmg"] > 0 if melee and i == 0 else (r["b_dmg"] > 0 if melee else (r["dmg"] == 0 if i == 0 else r["dmg"] > 0))
			if losing and int(p["roll"]) <= 8:
				reroll(p, f)
		p["stage"] = i + 1
	var res := result(p)
	var a := c.state.figure(p["a"])
	var b := c.state.figure(p["b"])
	var options: Dictionary=p.get("elemental_choices",{})
	if p["kind"]=="fight":
		if not RedKingMadMan.is_ryce(b):
			if _offer_absorption(p,options,a,b,int(res["b_dmg"]),int(res["a_roll"]),false,int(res.get("b_hammer",0))) or _offer_absorption(p,options,b,a,int(res["a_dmg"]),int(res["b_roll"]),false,int(res.get("a_hammer",0))):
				return
	else:
		if _offer_absorption(p,options,a,b,int(res["dmg"]),int(res["s_roll"]),true,int(res.get("hammer",0))):
			return
	res["elemental_choices"]=options
	c.state.pending_combat = {}
	if p["kind"] == "fight":
		c.finish_fate_fight(a, b, res)
	else:
		c.finish_fate_shot(a, b, res, p["declared"])


func reroll(p: Dictionary, f: Figure) -> void:
	if not ActiveGear.spend(f, ITEM):
		return
	var old := int(p["rolls"][p["stage"]])
	var fresh := c.dice.d20()
	p["rolls"][p["stage"]] = fresh
	c.emit("fate_reroll", {"id": f.id, "first": old, "second": fresh})


func answer(use: bool) -> bool:
	var p := c.state.pending_combat
	if p.is_empty() or p.has("absorb_target") or not p.has("roller"):
		return false
	var f := c.state.figure(p["roller"])
	if f == null or f.side != c.state.reaction_side:
		return false
	if use:
		reroll(p, f)
	p["stage"] = int(p["stage"]) + 1
	advance()
	return true


## Only after both Fate Stone opportunities have resolved is damage known.
## Store choices in the pending opposed roll, without changing either figure.
func _offer_absorption(p: Dictionary,options: Dictionary,attacker: Figure,target: Figure,damage: int,raw: int,ranged: bool,hammer: int=0) -> bool:
	if options.has(target.id) or target.side!=c.state.reaction_side or not ActiveGear.ready(target,RedKingElemental.AMULET):
		return false
	var parts := RedKingElemental.weapon_parts(attacker,target,damage,raw,ranged,hammer)
	if parts.y<=0:
		return false
	p["absorb_target"]=target.id
	p["absorb_normal"]=parts.x
	p["absorb_elemental"]=parts.y
	p["elemental_choices"]=options
	return true


func answer_absorption(use: bool) -> bool:
	var p := c.state.pending_combat
	if p.is_empty() or not p.has("absorb_target"):
		return false
	var target := c.state.figure(int(p["absorb_target"]))
	if target==null or target.side!=c.state.reaction_side:
		return false
	p["elemental_choices"][target.id]=int(use)
	p.erase("absorb_target")
	advance()
	return true
