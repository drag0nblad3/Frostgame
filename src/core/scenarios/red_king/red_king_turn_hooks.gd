class_name RedKingTurnHooks
extends RefCounted
## Keep the expansion's established lifecycle ordering in one place.


static func prepare(c: GameController) -> void:
	DeathMask.prepare(c)
	CircletDefence.prepare(c)
	ScrollShield.prepare(c)
	RedKingGear.foulhorn_brawl(c)
	RedKingInvestigations.prepare(c)
	RedKingVeil.prepare(c)
	RedKingMind.prepare(c)


static func priority(c: GameController,rolls: Array) -> void:
	RedKingHill.priority(c,rolls)
	if not c.state.scenario_data.has("rk_priority_choice"):
		RealityCracks.on_priority(c,rolls)


static func end_turn(c: GameController) -> void:
	RedKingSquatter.end_turn(c)
	RedKingInvestigations.end_turn(c)
	RedKingVeil.end_turn(c)
	RedKingFire.end_turn(c)
	RedKingMadMan.end_turn(c)
	RedKingMind.end_turn(c)
	RedKingHerded.end_turn(c)
	RedKingSinkhole.end_turn(c)
	RedKingTethers.end_turn(c)
	RedKingBridge.end_turn(c)
	RedKingRingworld.end_turn(c)
	RealityCracks.on_end_turn(c)


static func after_end_turn(c: GameController) -> void:
	HolyLantern.end_turn(c)
	WormRider.end_turn(c)
