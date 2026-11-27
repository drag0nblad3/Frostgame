class_name RedKingVictory
extends RefCounted
## Null defers to the core; an empty dictionary means the scenario continues;
## a winner dictionary requests the one canonical game-over event.


static func before_turn(c: GameController) -> Variant:
	if RedKingMind.active(c.state) and c.state.turn>=8:
		RedKingMind.finish(c)
		return {"winner":0}
	return null


static func turn_limit(s: GameState) -> Variant:
	return 18 if RedKingHerded.active(s) else null


static func at_limit(c: GameController) -> Variant:
	var s := c.state
	if RedKingVeil.active(s):
		RedKingVeil.finish(c)
		return {"winner":0 if RedKingVeil.xp(c,0)>0 else 1}
	if not s.treasures.is_empty() and RedKingInvestigations.active(s):
		RedKingInvestigations.finish_unsearched(c)
	return null


static func check_after_turn(s: GameState) -> bool:
	return RedKingMind.active(s) or RedKingHerded.active(s) or RedKingRingworld.active(s)


static func check(c: GameController,standing: Array[int]) -> Variant:
	var s := c.state
	if RedKingRingworld.active(s):
		if not RedKingRingworld.check_end(c):
			return {}
		return {"winner":TreasureRules.winner(s) if s.scenario_data.get("ring_success",false) else -1}
	if RedKingBridge.active(s):
		if not standing.is_empty():
			return {}
		for token in s.treasures:
			if token.unresolved():
				c._loot.lose(token)
		return {"winner":TreasureRules.winner(s)}
	if RedKingTethers.active(s) and RedKingTethers.remaining(s)>0:
		if not standing.is_empty():
			return {}
		return {"winner":-1}
	if RedKingHerded.active(s):
		if not standing.is_empty() and float(s.scenario_data.get("herd_veil",0.0))<s.board.size.y:
			return {}
		for token in s.treasures:
			if token.unresolved():
				c._loot.lose(token)
		return {"winner":TreasureRules.winner(s)}
	if RedKingMind.active(s):
		var wizard := RedKingMind.wizard(s)
		if wizard!=null and wizard.in_play():
			return {}
		RedKingMind.finish(c)
		return {"winner":0}
	if RedKingMadMan.active(s):
		var living_warband := false
		for f in s.figures:
			if f.side>=0 and f.in_play() and not RedKingMadMan.hunter(f):
				living_warband=true
				break
		if not living_warband:
			for token in s.treasures:
				if token.unresolved():
					c._loot.lose(token)
			return {"winner":TreasureRules.winner(s)}
		if RedKingMadMan.unresolved(s):
			return {}
		for token in s.treasures:
			if token.unresolved():
				return {}
		return {"winner":TreasureRules.winner(s)}
	if RedKingVeil.active(s):
		if not s.side_figures(0).is_empty():
			return {}
		RedKingVeil.finish(c)
		return {"winner":0 if RedKingVeil.xp(c,0)>0 else 1}
	if RedKingInvestigations.active(s):
		if not standing.is_empty():
			return {}
		RedKingInvestigations.finish_unsearched(c)
		return {"winner":TreasureRules.winner(s)}
	return null
