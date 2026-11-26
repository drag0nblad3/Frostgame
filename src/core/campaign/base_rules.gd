class_name BaseRules
extends RefCounted

const BENEFITS := {
	"brewery": "Soldiers +1 Will; +20 gc after battle",
	"laboratory": "+20 XP after battle",
	"treasury": "Chance of extra gold or treasure after battle",
	"temple": "+3 Miraculous Cure; chance of healing potion",
	"crypt": "+2 Raise Zombie and Animate Skull",
	"tower": "+2 Awareness and Reveal Secret",
	"library": "Chance of a scroll or grimoire after battle",
	"inn": "One reserve soldier; choose who stays behind"
}


static func casting_bonus(base: String, spell: String) -> int:
	match base:
		"temple":
			return 3 if spell == "miraculous_cure" else 0
		"crypt":
			return 2 if spell in ["raise_zombie", "animate_skull"] else 0
		"tower":
			return 2 if spell in ["awareness", "reveal_secret"] else 0
	return 0
