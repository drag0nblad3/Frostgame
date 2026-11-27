class_name ExpeditionStage
extends RefCounted
## Derived campaign phase; existing save data remains the source of truth.


static func current(data: Dictionary,in_battle: bool,ready: bool) -> String:
	if data.is_empty():
		return "Create warband"
	if in_battle:
		return "Expedition in progress"
	if not data.get("pending_treasure",[]).is_empty():
		return "After-action reward choices"
	if not ready:
		return "Recovery & preparation"
	return "Ready for expedition"


static func route(data: Dictionary,in_battle: bool,ready: bool) -> String:
	return "Headquarters  ›  Planning  ›  Battle  ›  Recovery\n"+current(data,in_battle,ready)
