class_name ResistanceActions
extends RefCounted
## Immediate Will tests. The continuation runs exactly once, after any empowerment.
var c: GameController
var continuation: Callable


func _init(controller: GameController) -> void:
	c = controller


func attempt(t: Figure, tn: int, done: Callable, bonus: int = 0, anyone: bool = false,spell: String="") -> void:
	var raw := c.dice.d20()
	var mod := t.effective_will() + t.roll_penalty() + bonus + MagicEquipment.bonus(t,"resistance")
	var success := StatRoll.succeeds(raw, mod, tn)
	var caster := t.def.role in ["wizard", "apprentice"]
	var max_health := t.health + PowerPool.available(t,spell) if (caster or anyone) and raw != 1 and raw != 20 and t.in_play() else 0
	var needed := maxi(0, tn - raw - mini(mod, 10))
	var data := {"id": t.id, "raw": raw, "mod": mini(mod, 10), "tn": tn, "max": max_health,"spell":spell}
	data["resources"] = t.health + PowerPool.available(t,spell) if caster or anyone else 0
	var amulet := not success and raw != 1 and ActiveGear.ready(t, "gear_amulet_resistance")
	var fate := not success and ActiveGear.ready(t, "gear_fate_stone")
	if not success and (max_health > 0 or amulet or fate) and t.side == c.state.reaction_side:
		c.state.pending_resistance = data
		continuation = done
		c.emit("resistance_offer", data.duplicate())
		return
	if amulet and needed <= mini(4, 10 - int(data["mod"])):
		ActiveGear.spend(t, "gear_amulet_resistance")
		data["mod"] = int(data["mod"]) + 4
		needed = maxi(0, needed - 4)
		success = true
	var spend := 0
	if not success and needed <= mini(2, max_health) and needed < t.health + PowerPool.available(t,spell):
		spend = needed
	_resolve(data, spend, done)


func answer(spend: int) -> bool:
	var p := c.state.pending_resistance
	if p.is_empty() or spend < 0 or spend > int(p["max"]):
		return false
	var done := continuation
	continuation = Callable()
	c.state.pending_resistance = {}
	_resolve(p, spend, done)
	return true


func use_amulet() -> bool:
	var p := c.state.pending_resistance
	if p.is_empty() or int(p["raw"]) == 1:
		return false
	var t := c.state.figure(p["id"])
	if not ActiveGear.spend(t, "gear_amulet_resistance"):
		return false
	p["mod"] = mini(10, int(p["mod"]) + 4)
	return true


func reroll_fate() -> bool:
	var p := c.state.pending_resistance
	if p.is_empty():
		return false
	var t := c.state.figure(p["id"])
	if not ActiveGear.spend(t, "gear_fate_stone"):
		return false
	var old := int(p["raw"])
	var raw := c.dice.d20()
	p["raw"] = raw
	p["max"] = 0 if raw in [1, 20] else int(p.get("resources", 0))
	c.emit("fate_reroll", {"id": t.id, "first": old, "second": raw})
	return true


func _resolve(p: Dictionary, spend: int, done: Callable) -> void:
	var t := c.state.figure(p["id"])
	var stolen := VampireStaff.amount(c,p,false)
	var success := StatRoll.succeeds(p["raw"],p["mod"],p["tn"],spend+stolen)
	VampireStaff.spend(c,t,p,stolen)
	var power := PowerPool.spend(t,spend,str(p.get("spell","")))
	if spend > power:
		c._hurt(t, spend - power, t, false)
	c.emit("resistance_result", {"id": t.id, "raw": p["raw"], "mod": p["mod"], "tn": p["tn"], "spent": spend - power, "power": power, "success": success})
	done.call(success)
	c._magic.advance_shatter()
