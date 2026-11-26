class_name Figure
extends RefCounted
## A figure on the table: its stat line plus live state.

## Standard 25mm round base: 1" across.
const BASE_RADIUS := 0.5

var id := 0
var def: FigureDef
var side := 0
var pos := Vector2.ZERO
var health := 0
var out_of_action := false
var exited := false
var treasure_id := -1
var disengaged := {}
## Turn bookkeeping, reset by the controller each turn.
var activated := false
var actions_left := 0
var moves_taken := 0
var acted := false
## Crossbows start loaded and need an action to reload after shooting.
var loaded := true
var melee: WeaponDef
var ranged: WeaponDef


func _init(fig_id: int = 0, d: FigureDef = null, fig_side: int = 0, at: Vector2 = Vector2.ZERO, unarmed: WeaponDef = null) -> void:
	id = fig_id
	def = d
	side = fig_side
	pos = at
	if d != null:
		health = d.health
		melee = unarmed
		for w in d.weapons:
			if w.melee:
				melee = w
				break
		ranged = d.ranged_weapon()


func label() -> String:
	return def.name


func in_play() -> bool:
	return not out_of_action and not exited


func effective_fight() -> int:
	return def.fight - (1 if treasure_id >= 0 and def.treasure_encumbered() else 0)
