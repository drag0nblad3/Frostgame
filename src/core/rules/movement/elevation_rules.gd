class_name ElevationRules
extends RefCounted

static func fall_damage(distance: float) -> int:
	return floori(distance * 1.5) if distance >= 3.0 else 0
