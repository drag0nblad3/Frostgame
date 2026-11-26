class_name Phase
extends RefCounted
## Turn phases in order. Each figure activates in the phase matching its role.
## EarlyPhase handles normal wizard/apprentice soldier eligibility.
## TODO(rules): simultaneous group activation and creature phase are pending.

enum { WIZARD, APPRENTICE, SOLDIER }

const ORDER := [WIZARD, APPRENTICE, SOLDIER]
const NAMES := ["Wizard", "Apprentice", "Soldier"]
const ROLES := ["wizard", "apprentice", "soldier"]


static func name_of(p: int) -> String:
	return NAMES[p]


static func of_figure(f: Figure) -> int:
	var i := ROLES.find(f.def.role)
	return SOLDIER if i < 0 else i
