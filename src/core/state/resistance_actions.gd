class_name ResistanceActions
extends RefCounted
## Immediate Will tests. The continuation runs exactly once, after any empowerment.
var c: GameController
var continuation: Callable


func _init(controller: GameController) -> void:
	c = controller


func attempt(t: Figure, tn: int, done: Callable, bonus: int = 0) -> void:
	var raw := c.dice.d20()
	var mod := t.effective_will() + t.roll_penalty() + bonus
	var success := StatRoll.succeeds(raw, mod, tn)
	var caster := t.def.role in ["wizard", "apprentice"]
	var max_health := t.health + PowerPool.available(t) if caster and raw != 1 and raw != 20 and t.in_play() else 0
	var needed := maxi(0, tn - raw - mini(mod, 10))
	var data := {"id": t.id, "raw": raw, "mod": mini(mod, 10), "tn": tn, "max": max_health}
	if not success and max_health > 0 and t.side == c.state.reaction_side:
		c.state.pending_resistance = data
		continuation = done
		c.emit("resistance_offer", data.duplicate())
		return
	var spend := 0
	if not success and needed <= mini(2, max_health) and needed < t.health + PowerPool.available(t):
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


func _resolve(p: Dictionary, spend: int, done: Callable) -> void:
	var t := c.state.figure(p["id"])
	var success := StatRoll.succeeds(p["raw"], p["mod"], p["tn"], spend)
	var power := PowerPool.spend(t, spend)
	if spend > power:
		c._hurt(t, spend - power, t, false)
	c.emit("resistance_result", {"id": t.id, "raw": p["raw"], "mod": p["mod"], "tn": p["tn"], "spent": spend - power, "power": power, "success": success})
	done.call(success)
