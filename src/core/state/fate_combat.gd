class_name FateCombat
extends RefCounted
## Resolve ordinary opposed rolls before applying damage, allowing each owner
## one binding reroll of their own die if they have an unused Fate Stone.

const ITEM := "gear_fate_stone"
var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func start(a: Figure, b: Figure, kind: String, declared: int = -1,wraith: bool=false,ammo: bool=false) -> void:
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
	c.state.pending_combat = {}
	var a := c.state.figure(p["a"])
	var b := c.state.figure(p["b"])
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
	if p.is_empty() or not p.has("roller"):
		return false
	var f := c.state.figure(p["roller"])
	if f == null or f.side != c.state.reaction_side:
		return false
	if use:
		reroll(p, f)
	p["stage"] = int(p["stage"]) + 1
	advance()
	return true
