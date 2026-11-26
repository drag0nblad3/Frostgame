class_name MagicEquipment
extends RefCounted

const ARM_TABLE := ["gear_hand_weapon_damage","gear_hand_weapon_fight","gear_hand_weapon_will","gear_two_handed_damage","gear_two_handed_fight","gear_two_handed_will","gear_bow_damage","gear_bow_shoot","gear_crossbow_damage","gear_crossbow_shoot","gear_dagger_fight","gear_dagger_damage","gear_dagger_damage2","gear_light_armour","gear_heavy_armour_absorb","gear_ring_protection","gear_cloak_protection","gear_cloak_night","gear_staff_fight","gear_shield_armour"]
const ITEM_TABLE := ["gear_staff_power1","gear_staff_power2","gear_ring_transference","gear_ring_power1","gear_orb_power6","gear_staff_casting","gear_boots_speed","gear_ring_slow_fall","gear_ring_will","gear_ring_teleportation","gear_gloves_strength","gear_robes_arrows","gear_amulet_resistance","gear_construct_hammer","gear_gloves_casting","gear_wand_light","gear_horn_destruction","gear_fate_stone","gear_wand_power1","gear_staff_power3"]
const WEAPONS := ["hand_weapon", "two_handed", "bow", "crossbow", "dagger", "staff"]


static func compatible(def: FigureDef, info: Dictionary) -> bool:
	var type: String = info["type"]
	if type in WEAPONS:
		for w in def.weapons:
			if w.id == type:
				return true
		return false
	if type == "shield":
		return def.shield
	if type in ["light_armour", "heavy_armour"]:
		if def.role != "soldier":
			return false
		if type == "heavy_armour":
			return def.id in ["knight", "templar", "marksman"]
		return def.id in ["infantryman", "man_at_arms", "archer", "crossbowman", "treasure_hunter", "ranger", "tracker"]
	if type == "construct_hammer":
		return false
	return true


static func bonus(f: Figure, stat: String, weapon: String = "") -> int:
	var total := 0
	for item: Dictionary in f.items:
		var info: Dictionary = item.get("gear_info", {})
		if info.is_empty():
			continue
		var type: String = info["type"]
		if type in WEAPONS:
			if f.destroyed_weapons.has(type):
				continue
			if weapon != "" and type != weapon:
				continue
			if weapon == "" and type != f.melee.id and (f.ranged == null or type != f.ranged.id):
				continue
		total += int(info["bonus"].get(stat, 0))
	return total
