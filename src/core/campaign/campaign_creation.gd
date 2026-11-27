class_name CampaignCreation
extends RefCounted
## Explicit one-write campaign creation, never replaces an existing file.


static func create(roster: Dictionary,profile: ContentProfile,story: bool,veil: bool,pursuit: bool,path: String="") -> String:
	var target := WarbandSlots.path_for(CampaignProgress.PATH) if path.is_empty() else path
	if FileAccess.file_exists(target):
		return "A campaign already exists in this save."
	if not profile.errors().is_empty():
		return "; ".join(profile.errors())
	var db := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,profile)
	var draft := WarbandDraft.new(db)
	draft.choose_defaults()
	if not roster.is_empty() and not draft.restore_roster(roster):
		return "The starting warband is incompatible. Edit it before starting."
	var progress := CampaignProgress.new()
	progress.start(draft.as_warband(),profile)
	if story and not RedKingCampaign.start(progress.data,profile,veil,pursuit):
		return "The Red King storyline is not enabled in this save."
	if not progress.save(target):
		return "Could not save the new campaign."
	return ""
