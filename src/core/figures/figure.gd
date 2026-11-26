class_name Figure
extends RefCounted
## A figure on the table: its stat line plus live state.

## Standard 25mm round base: 1" across.
const BASE_RADIUS := 0.5

var id := 0
var campaign_id := -1
var original_side := 0
var controller_id := -1
var control_spell := ""
var control_roll := 0
var summoned_by := -1
var summon_spell := ""
var def: FigureDef
var side := 0
var pos := Vector2.ZERO
var elevation := 0.0
var health := 0
var out_of_action := false
var exited := false
var treasure_id := -1
var disengaged := {}
var spell_effects := {}
var items: Array[Dictionary] = []
var elemental_shield := 0
var poisoned := false
var petrified_skip := false
var magic_exhausted := false
var last_time_walk := -2
var walk_phases: Array[int] = []
var stored_action_turn := -1
var used_stored_action := false
var non_moves := 0
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
	original_side = fig_side
	pos = at
	if d != null:
		health = d.health
		if d.id == "apothecary":
			items.append({"potion": "healing", "campaign_item": false})
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
	if spell_effects.has("blinding_light"):
		return 0
	var value := def.fight - (1 if treasure_id >= 0 and def.treasure_encumbered() else 0) + (2 if spell_effects.has("strength") else 0) + (1 if spell_effects.has("combat_awareness") else 0) - (2 if spell_effects.has("furious_quill") else 0)
	value += 1 if spell_effects.has("potion_strength") else 0
	if spell_effects.has("petrify"):
		value = maxi(0, value - 3)
	return value


func effective_armour() -> int:
	var total := def.armour + (2 if spell_effects.has("shield") else 0) + (1 if spell_effects.has("combat_awareness") else 0) + (1 if spell_effects.has("enchant_armour") else 0)
	total += (1 if spell_effects.has("potion_toughness") else 0) + MagicEquipment.bonus(self, "armour")
	return total if def.role == "creature" else mini(total, 15)


func effective_move() -> int:
	if spell_effects.has("blinding_light"):
		return 1
	var speed := def.move + MagicEquipment.bonus(self, "move") + (2 if spell_effects.has("fleet_feet") else 0) - (1 if spell_effects.has("furious_quill") else 0)
	if spell_effects.has("potion_speed"):
		speed = mini(9, speed + 2)
	return maxi(1, speed)


func effective_will() -> int:
	return def.will + MagicEquipment.bonus(self, "will") + (2 if spell_effects.has("mind_lock") else 0) + (5 if spell_effects.has("potion_iron_mind") else 0)


func action_limit() -> int:
	if petrified_skip or magic_exhausted:
		return 0
	return 1 if poisoned or spell_effects.has("slow") else 2


func roll_penalty() -> int:
	return -2 if spell_effects.has("curse") else 0


func effective_shoot() -> int:
	return def.shoot - (4 if spell_effects.has("furious_quill") else 0)


func immune_to_poison() -> bool:
	return def.traits.has("undead") or def.traits.has("construct") or def.traits.has("demon")
