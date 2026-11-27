class_name CampaignStartScreen
extends ExpeditionScreen
## Start a new campaign from Home, before loading any battle scene.
signal created
signal edit_requested

var _split: BoxContainer
var _lineup: WarbandLineup
var _roster_title: Label
var _roster_detail: Label
var _modes: VBoxContainer
var _ordinary: Button
var _story_button: Button
var _veil: CheckBox
var _pursuit: CheckBox
var _story_detail: Label
var _status: Label
var _story := false
var _profile: ContentProfile
var _roster: Dictionary
var _valid := true


func _ready() -> void:
	build("BEGIN YOUR CAMPAIGN","Create campaign",_create)
	_split=BoxContainer.new()
	_split.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_split.add_theme_constant_override("separation",12)
	body.add_child(_split)
	var visual := WorkshopUI.column(_split)
	visual.size_flags_stretch_ratio=1.25
	_roster_title=WorkshopUI.label(visual,"",31,WorkshopUI.GOLD)
	_roster_detail=WorkshopUI.label(visual,"",22,WorkshopUI.MUTED)
	_lineup=WarbandLineup.new()
	_lineup.custom_minimum_size.y=170
	_lineup.size_flags_vertical=Control.SIZE_EXPAND_FILL
	visual.add_child(_lineup)
	WorkshopUI.button(visual,"Customize starting warband",_edit,true)
	_lineup.selected.connect(func(_slot: int) -> void: _edit())
	_modes=WorkshopUI.scroll(_split)
	_modes.get_parent().size_flags_stretch_ratio=1.0
	WorkshopUI.label(_modes,"CAMPAIGN TYPE",20,WorkshopUI.GOLD)
	_ordinary=WorkshopUI.button(_modes,"Free-form campaign",_choose.bind(false),true)
	WorkshopUI.label(_modes,"Choose your own scenarios. Earn XP, recruit soldiers, collect magical gear and establish a base.",24)
	_story_button=WorkshopUI.button(_modes,"The Red King storyline",_choose.bind(true),true)
	_story_detail=WorkshopUI.label(_modes,"",23,WorkshopUI.MUTED)
	_veil=CheckBox.new()
	_veil.text="Include optional Veil of Unreality"
	_veil.button_pressed=true
	_veil.custom_minimum_size.y=56
	_veil.add_theme_font_size_override("font_size",23)
	_modes.add_child(_veil)
	_pursuit=CheckBox.new()
	_pursuit.text="Harder Act II pursuit · no resupply"
	_pursuit.custom_minimum_size.y=56
	_pursuit.add_theme_font_size_override("font_size",23)
	_modes.add_child(_pursuit)
	WorkshopUI.label(_modes,"The selected rulebooks and starting roster belong to this save slot. Campaign creation does not erase other slots.",20,WorkshopUI.MUTED)
	_status=WorkshopUI.label(body,"",22,Color("edaa91"))
	_status.visible=false


func open() -> void:
	_profile=WarbandSlots.content_profile()
	_roster=WarbandSlots.roster()
	var db := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,_profile)
	var draft := WarbandDraft.new(db)
	draft.choose_defaults()
	_valid=_roster.is_empty() or draft.restore_roster(_roster)
	_lineup.set_draft(draft)
	_roster_title.text=draft.wizard_name if not _roster.is_empty() and _valid else "Your starting expedition"
	_roster_detail.text="%s · %d members · %d gc remaining"%[draft.school.capitalize(),1+int(draft.apprentice)+draft.soldiers.size(),WarbandDraft.BUDGET-draft.cost()]
	subtitle.text="Save %d · %s"%[WarbandSlots.active()+1,"Core rules" if _profile.enabled.is_empty() else "Core + "+", ".join(_profile.enabled)]
	var allowed := _profile.enabled.has("red_king") and _profile.allows("campaigns","red_king")
	_story_button.disabled=not allowed
	_story_detail.text="A linked sequence of dangerous encounters, with special rewards, pursuit and a final confrontation." if allowed else "Enable The Red King under Rulebook content on the home screen to unlock this storyline."
	_status.visible=not _valid
	_status.text="Starting roster is incompatible. Customize it first."
	_choose(_story and allowed)
	show_screen()


func _reflow() -> void:
	if _split!=null:
		_split.vertical=size.x<size.y


func _choose(story: bool) -> void:
	_story=story and not _story_button.disabled
	_ordinary.disabled=not _story
	_veil.visible=_story
	_pursuit.visible=_story
	action.text="Begin The Red King" if _story else "Create free-form campaign"
	action.disabled=not _valid


func _edit() -> void:
	hide()
	edit_requested.emit()


func _create() -> void:
	var error := CampaignCreation.create(_roster,_profile,_story,_veil.button_pressed,_pursuit.button_pressed)
	if not error.is_empty():
		_status.text=error
		_status.show()
		return
	hide()
	created.emit()
