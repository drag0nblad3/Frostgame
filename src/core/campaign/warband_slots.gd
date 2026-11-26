class_name WarbandSlots
extends RefCounted
## Local named roster slots, each with independent campaign and battle files.
## Slot zero preserves the original save paths and requires no migration.
const COUNT := 8
const ACTIVE := "user://frostgame_active_slot_v1.json"


static func active() -> int:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(ACTIVE)) if FileAccess.file_exists(ACTIVE) else null
	return clampi(int(value.get("slot",0)),0,COUNT-1) if value is Dictionary else 0


static func select_slot(slot: int) -> bool:
	return slot>=0 and slot<COUNT and _write(ACTIVE,{"slot":slot})


static func path_for(base: String,slot: int=-1) -> String:
	var index := active() if slot<0 else slot
	return base if index==0 else base.get_basename()+"_slot%d."%(index+1)+base.get_extension()


static func roster_path(slot: int=-1) -> String:
	return path_for("user://frostgame_roster_v1.json",slot)


static func roster(slot: int=-1) -> Dictionary:
	var path := roster_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value["roster"] if value is Dictionary and value.get("version",0)==1 and value.get("roster") is Dictionary else {}


static func save_roster(data: Dictionary,slot: int=-1) -> bool:
	return not data.is_empty() and _write(roster_path(slot),{"version":1,"roster":data})


static func summary(slot: int) -> String:
	var draft := roster(slot)
	var progress := CampaignProgress.new()
	if progress.load_save(path_for(CampaignProgress.PATH,slot)):
		return "%s · %s · Level %d · %d battles"%[progress.data["name"],str(progress.data["school"]).capitalize(),progress.data["level"],progress.data["games"]]
	if not draft.is_empty():
		return "%s · %s · %d members"%[draft.get("name","Warband"),str(draft.get("school","")).capitalize(),draft.get("figures",[]).size()]
	if FileAccess.file_exists(path_for(BattleSnapshot.PATH,slot)) or FileAccess.file_exists(path_for(LayeredCheckpoint.PATH,slot)):
		return "Saved battle · no roster"
	return "Empty slot"


static func _write(path: String,data: Dictionary) -> bool:
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return DirAccess.rename_absolute(path+".tmp",path)==OK


static func content_path(slot: int=-1) -> String:
	return path_for("user://frostgame_content_v1.json",slot)


static func content_profile(slot: int=-1) -> ContentProfile:
	var path := content_path(slot)
	if not FileAccess.file_exists(path):
		return ContentProfile.new()
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return ContentProfile.new(data.get("enabled",[])) if data is Dictionary and data.get("version",0)==1 and data.get("enabled") is Array else ContentProfile.new()


static func change_content(ids: Array,slot: int=-1) -> Array[String]:
	var before := content_profile(slot)
	var after := ContentProfile.new(ids)
	var campaign := CampaignProgress.new()
	var campaign_path := path_for(CampaignProgress.PATH,slot)
	var loaded := campaign.load_save(campaign_path)
	if FileAccess.file_exists(campaign_path) and not loaded:
		return ["Cannot safely inspect this campaign. Content settings were not changed."]
	var errors := ExpansionSafety.conflicts(before,after,roster(slot),campaign.data)
	if not errors.is_empty():
		return errors
	if not _write(content_path(slot),{"version":1,"enabled":after.enabled}):
		return ["Could not save content settings."]
	return []
