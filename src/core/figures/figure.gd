class_name Figure
extends RefCounted
## A figure on the table: its stat line plus live state.

## Standard 25mm round base: 1" across.
const BASE_RADIUS := 0.5

var id := 0
var campaign_id := -1
var injury_types := {}
var familiar := false
var beauty_tests := {}
var last_plane_attempt := -2
var plane_attempts := 0
var campaign_base := ""
var battle_ref: WeakRef
var original_side := 0
var controller_id := -1
var control_spell := ""
var control_roll := 0
var summoned_by := -1
var prepared_demon_caster := -1
var summon_spell := ""
var def: FigureDef
var side := 0
var pos := Vector2.ZERO
var elevation := 0.0
## Ringworld reality: outside (0) or inside (1).
var ring_side := 0
## Stable ID for explicit layered surfaces; empty on legacy maps.
var surface_id := ""
var health := 0
var out_of_action := false
var exited := false
var treasure_id := -1
var second_treasure_id := -1
var shrunk_treasure_id := -1
var disengaged := {}
var spell_effects := {}
var items: Array[Dictionary] = []
var elemental_shield := 0
var poisoned := false
var poison_weapon := ""
var empowerment_used := false
var used_gear := {}
var next_cast_gear := ""
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
var destroyed_weapons: Array[String] = []
var unarmed_weapon: WeaponDef
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
		unarmed_weapon = unarmed
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
	var value := def.fight - (1 if carries_normal_treasure() and treasure_encumbered() else 0) + (2 if spell_effects.has("strength") else 0) + (1 if spell_effects.has("combat_awareness") else 0) - (2 if spell_effects.has("furious_quill") else 0)
	value += 1 if spell_effects.has("potion_strength") else 0
	value += 1 if spell_effects.has("potion_fury") else 0
	value += 2 if spell_effects.has("possess") else 0
	if affected_by_insects():
		value = maxi(0, value - 4)
	if spell_effects.has("petrify"):
		value = maxi(0, value - 3)
	return value


func effective_armour() -> int:
	var total := def.armour + (2 if spell_effects.has("shield") else 0) + (1 if spell_effects.has("combat_awareness") else 0) + (1 if spell_effects.has("enchant_armour") else 0)
	total += (1 if spell_effects.has("potion_toughness") else 0) + MagicEquipment.bonus(self, "armour")
	total += 1 if spell_effects.has("possess") else 0
	return total if def.role == "creature" else mini(total, 15)


func effective_move() -> int:
	if spell_effects.has("blinding_light"):
		return 1
	var speed := def.move + MagicEquipment.bonus(self, "move") + (2 if spell_effects.has("fleet_feet") else 0) - (1 if spell_effects.has("furious_quill") else 0)
	if spell_effects.has("potion_speed"):
		speed = mini(9, speed + 2)
	return maxi(1, speed-int(spell_effects.get("veil_move_penalty",0)))


func effective_will() -> int:
	return def.will + RealityCracks.will_modifier(self) + MagicEquipment.bonus(self, "will") + (2 if spell_effects.has("mind_lock") else 0) + (5 if spell_effects.has("potion_iron_mind") else 0) - (2 if spell_effects.has("possess") else 0)


func action_limit() -> int:
	if petrified_skip or magic_exhausted:
		return 0
	return 1 if poisoned or spell_effects.has("slow") else 2


func roll_penalty() -> int:
	return -2 if spell_effects.has("curse") else 0


func effective_shoot() -> int:
	var value := def.shoot - (2 if RealityCracks.low_gravity(self) else 0) - (4 if spell_effects.has("furious_quill") else 0)
	return maxi(0, value - 4) if affected_by_insects() else value


func immune_to_poison() -> bool:
	return MagicEquipment.bonus(self,"poison_immunity")>0 or def.traits.has("immune_poison") or def.traits.has("undead") or def.traits.has("construct") or def.traits.has("demon")


func treasure_encumbered() -> bool:
	return def.shield or ranged != null or melee.id in ["staff", "two_handed"]


func early_limit() -> int:
	return maxi(1, 3 - int(injury_types.get("smashed_jaw", 0)))


func shooting_defence_penalty() -> int:
	return -int(injury_types.get("lost_eye", 0))+MagicEquipment.bonus(self,"shoot_defence")


func is_demon() -> bool:
	return def.traits.has("demon") or spell_effects.has("possess")


func insects_immune() -> bool:
	return def.traits.has("large") or def.traits.has("undead") or def.traits.has("construct")


func affected_by_insects() -> bool:
	if insects_immune():
		return false
	if spell_effects.has("plague_of_insects"):
		return true
	if battle_ref == null:
		return false
	var s: GameState = battle_ref.get_ref()
	if s == null:
		return false
	for other in s.figures:
		if other.in_play() and other.spell_effects.has("plague_of_insects") and Shooting.distance(self, other) <= 1.0 + BASE_RADIUS:
			return true
	return false


func carries_normal_treasure() -> bool:
	return (treasure_id >= 0 and treasure_id != shrunk_treasure_id) or (second_treasure_id >= 0 and second_treasure_id != shrunk_treasure_id)


func carried_treasures() -> Array[int]:
	var result: Array[int] = []
	if treasure_id >= 0:
		result.append(treasure_id)
	if second_treasure_id >= 0:
		result.append(second_treasure_id)
	return result
