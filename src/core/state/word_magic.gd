class_name WordMagic
extends RefCounted


static func options(s: GameState, f: Figure, id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for word in s.words:
		if word["caster"] == f.id and word["spell"] == id:
			return out
	for target: String in s.spell_catalog:
		if s.spell_catalog[target]["kind"] in ["unimplemented", "ritual"]:
			continue
		var already := false
		for word in s.words:
			if word["spell"] == id and word["chosen"] == target:
				already = true
				break
		if not already:
			out.append({"kind": "word_choice", "target": f.id, "chosen": target, "label": str(s.spell_catalog[target]["name"])})
	return out


static func modifier(s: GameState, id: String) -> int:
	var total := 0
	for word in s.words:
		if word["chosen"] == id:
			total += 3 if word["spell"] == "power_word" else -3
	return total


static func apply(s: GameState, f: Figure, id: String, chosen: String) -> void:
	s.words.append({"caster": f.id, "spell": id, "chosen": chosen})
