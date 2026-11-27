class_name ActionArt
extends RefCounted
## Original vector glyphs shared across the game. No rules or external assets.
const ICONS := {
	"chronomancer": preload("res://assets/glyphs/chronomancer.svg"),
	"elementalist": preload("res://assets/glyphs/elementalist.svg"),
	"enchanter": preload("res://assets/glyphs/enchanter.svg"),
	"illusionist": preload("res://assets/glyphs/illusionist.svg"),
	"necromancer": preload("res://assets/glyphs/necromancer.svg"),
	"sigilist": preload("res://assets/glyphs/sigilist.svg"),
	"soothsayer": preload("res://assets/glyphs/soothsayer.svg"),
	"summoner": preload("res://assets/glyphs/summoner.svg"),
	"thaumaturge": preload("res://assets/glyphs/thaumaturge.svg"),
	"witch": preload("res://assets/glyphs/witch.svg"),
	"move": preload("res://assets/glyphs/move.svg"),
	"fight": preload("res://assets/glyphs/fight.svg"),
	"shoot": preload("res://assets/glyphs/shoot.svg"),
	"cast": preload("res://assets/glyphs/cast.svg"),
	"collect": preload("res://assets/glyphs/collect.svg"),
	"drop": preload("res://assets/glyphs/drop.svg"),
	"exit": preload("res://assets/glyphs/exit.svg"),
	"reload": preload("res://assets/glyphs/reload.svg"),
	"end": preload("res://assets/glyphs/end.svg"),
	"items": preload("res://assets/glyphs/items.svg"),
	"group": preload("res://assets/glyphs/group.svg"),
	"inspect": preload("res://assets/glyphs/inspect.svg"),
	"shield": preload("res://assets/glyphs/shield.svg"),
	"cancel": preload("res://assets/glyphs/cancel.svg")
}


static func school(school_id: String) -> Texture2D:
	return ICONS.get(school_id,ICONS["cast"])


static func command(key: String, catalog: Dictionary) -> Texture2D:
	if key.ends_with("_confirm") or key=="group_begin":
		return MenuSymbols.ICONS["save"]
	if key=="move_undo" or key.ends_with("_back") or key=="counter_previous":
		return MenuSymbols.ICONS["back"]
	if key.begins_with("cancel_") or key.ends_with("_cancel"):
		return ICONS["cancel"]
	if key in ["jump","run_for_it","run_talisman","push_self","push_enemy","ring_switch","stay"] or key.begins_with("push_self_"):
		return ICONS["move"]
	if key=="fight_hand":
		return ICONS["fight"]
	if key in ["ammo_shot","wraith_shot"]:
		return ICONS["shoot"]
	if key in ["pass_phase","use_stored_action"]:
		return ICONS["end"]
	if key in ["ring_escape","reality_exit"]:
		return ICONS["exit"]
	if key in ["break_ice","drop_shrunk"]:
		return ICONS["collect"] if key=="break_ice" else ICONS["drop"]
	if key.begins_with("spell_"):
		var info: Dictionary = catalog.get(key.trim_prefix("spell_"),{})
		return school(str(info.get("school","")))
	if key.begins_with("potion_") or key.begins_with("gear_") or key.begins_with("weapon_"):
		return ICONS["items"]
	return ICONS.get(key,null)


static func spell_details(info: Dictionary, tn: int) -> String:
	var kind: String = str(info.get("kind","")).replace("_"," ").capitalize()
	var detail := "%s · %s · TN %d" % [str(info.get("school","")).capitalize(),kind,tn]
	if info.has("range"):
		detail += " · Range %s″" % str(info["range"])
	if info.has("power"):
		detail += " · Power +%s" % str(info["power"])
	return detail


static func apply(button: Button, key: String, catalog: Dictionary) -> void:
	button.icon = command(key,catalog)
	button.add_theme_constant_override("icon_max_width",28)
	button.expand_icon = true
	if key in ["end","cast_confirm","resist_confirm","transfer_confirm","group_begin"]:
		button.add_theme_stylebox_override("normal",BattleTheme.panel(Color(0.17,0.27,0.29),Color(0.72,0.61,0.38)))
