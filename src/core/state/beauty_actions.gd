class_name BeautyActions
extends RefCounted

var c: GameController


func _init(controller: GameController) -> void:
	c = controller


static func protected_from(s: GameState, actor: Figure, target: Figure) -> bool:
	if actor.spell_effects.has("potion_clearsight") or actor == target or actor.side == target.side or actor.side < 0 or actor.def.role == "creature" or actor.def.traits.has("animal") or not target.spell_effects.has("beauty"):
		return false
	for f in s.figures:
		if f.in_play() and f.side == actor.side and f.spell_effects.has("true_sight") and Shooting.distance(f, actor) <= 6.0:
			return false
	return true


static func blocked(s: GameState, actor: Figure, target: Figure) -> bool:
	return protected_from(s, actor, target) and actor.beauty_tests.get(target.id, {}).get("turn", -1) == s.turn and not actor.beauty_tests[target.id]["success"]


func authorize(actor: Figure, targets: Array[Figure], done: Callable, index: int = 0) -> void:
	if not actor.in_play():
		return
	for i in range(index, targets.size()):
		var t := targets[i]
		if not protected_from(c.state, actor, t):
			continue
		var previous: Dictionary = actor.beauty_tests.get(t.id, {})
		if int(previous.get("turn", -1)) == c.state.turn:
			if not previous["success"]:
				return
			continue
		c._magic.resistance.attempt(actor, int(t.spell_effects["beauty"]), _result.bind(actor, t, targets, done, i + 1))
		return
	done.call()


func _result(success: bool, actor: Figure, target: Figure, targets: Array[Figure], done: Callable, index: int) -> void:
	actor.beauty_tests[target.id] = {"turn": c.state.turn, "success": success}
	c.emit("beauty_test", {"id": actor.id, "target": target.id, "success": success})
	if success:
		authorize(actor, targets, done, index)
