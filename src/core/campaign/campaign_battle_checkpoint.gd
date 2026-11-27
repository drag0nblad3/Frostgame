class_name CampaignBattleCheckpoint
extends RefCounted
## A separate per-slot recovery checkpoint; manual battle saves are untouched.
const PATH := "user://frostgame_expedition_v1.dat"


static func path() -> String:
	return WarbandSlots.path_for(PATH)


static func save(c: GameController,scenario: String,campaign_hash: String,watch: bool) -> bool:
	if campaign_hash.is_empty() or not BattleSnapshot.can_save(c):
		return false
	return BattleSnapshot.save(c,{"scenario":scenario,"campaign":true,"campaign_hash":campaign_hash,"watch":watch},path())


static func read() -> Dictionary:
	return BattleSnapshot.read(path())


static func clear() -> void:
	if FileAccess.file_exists(path()):
		DirAccess.remove_absolute(path())
