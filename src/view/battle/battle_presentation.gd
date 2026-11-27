class_name BattlePresentation
extends RefCounted
## Presentation-only grouping and pacing policy. No rule or RNG access.
const ACTIONS := ["fight","shoot","spell_shot","cast_result"]
const CONSEQUENCES := ["damage","heal","out_of_action","spell_effect","shield_absorb","poison","magic_impact"]


static func beat(event: GameEvent) -> String:
	if event.type in ACTIONS:
		return "action"
	if event.type in CONSEQUENCES:
		return "consequence"
	if event.type in ["move","layered_move","push_back","force_combat"]:
		return "movement"
	return "context"


static func hold(event: GameEvent,next: GameEvent,notice: bool) -> float:
	if notice:
		return 1.3
	# Related aftermath stays readable without adding a full pause to every log line.
	if next!=null and beat(event)=="consequence" and beat(next)=="consequence":
		return 0.45
	return 0.8
