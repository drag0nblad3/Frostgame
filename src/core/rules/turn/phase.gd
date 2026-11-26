class_name Phase
extends RefCounted
## Turn phases in order. Each figure activates in the phase matching its role.
## TODO(rules): the wizard's group activation (soldiers within 3") and the
## creature phase are not modelled yet.

enum { WIZARD, APPRENTICE, SOLDIER }

const ORDER := [WIZARD, APPRENTICE, SOLDIER]
const NAMES := ["Wizard", "Apprentice", "Soldier"]
const ROLES := ["wizard", "apprentice", "soldier"]


static func name_of(p: int) -> String:
	return NAMES[p]


static func of_figure(f: Figure) -> int:
	var i := ROLES.find(f.def.role)
	return SOLDIER if i < 0 else i
