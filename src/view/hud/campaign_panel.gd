class_name CampaignPanel
extends AcceptDialog
## Between-battle campaign overview. Starting a campaign is an explicit action.
signal start_requested
signal story_requested(include_veil: bool, strict_pursuit: bool)
signal begin_requested
signal restart_requested
signal scenario_selected(id: String)
var _scroll: ScrollContainer
var _scenario: OptionButton
var _sections: Array[VBoxContainer]=[]
var _section_picker: OptionButton
var _roster_summary: Label
var _history_summary: Label
var _briefing: Label
var _depart_status: Label
var _quick_prepare: Button
var _quick_gear: Button
var _quick_warband: Button
var _quick_report: Button
const SECTIONS := ["Expedition", "Warband", "Equipment", "Rituals", "Base", "Rules & chronicle"]
var campaign: CampaignProgress
var summary: Label
var base_banner: BaseBanner
var _spell_catalog: Dictionary
var spells: OptionButton
var improve: Button
var start: Button
var story_start: Button
var story_veil: CheckBox
var story_strict_pursuit: CheckBox
var recruit_status: CheckBox
var roll_recruits: Button
var reality_option: CheckBox
var wounded_option: CheckBox
var mantle_option: CheckBox
var secret_hrut: CheckBox
var skip_mind_button: Button
var reconcile_button: Button
var continue_skirmishes: Button
var begin: Button
var db: FigureDb
var stat: OptionButton
var upgrade: Button
var recruit: OptionButton
var hire_button: Button
var members: OptionButton
var dismiss_button: Button
var treat_button: Button
var base_choice: OptionButton
var base_button: Button
var grimoire: OptionButton
var learn_button: Button
var controls: Array[Control] = []
var inventory: InventoryPanel
var rituals: RitualPanel
var base_upgrades: BaseUpgradePanel
var succession: SuccessionPanel
var niggle: OptionButton
var niggle_button: Button
var treasure_choice: Label
var keep_treasure: Button
var alternate_treasure: Button
var exchange_treasure: Button
var treasure_dice := Dice.new(0)


func setup(progress: CampaignProgress, figures: FigureDb) -> void:
	campaign = progress
	db = figures
	_spell_catalog = JsonFile.read("res://data/spells.json")
	theme = BattleTheme.create()
	title = "Campaign headquarters"
	get_ok_button().text = "Close"
	var scroll := ScrollContainer.new()
	_scroll=scroll
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var root := VBoxContainer.new()
	add_child(root)
	_section_picker=OptionButton.new()
	_section_picker.custom_minimum_size.y=48
	for section: String in SECTIONS:
		_section_picker.add_item(section)
	root.add_child(_section_picker)
	_section_picker.item_selected.connect(_show_section)
	fit_phone()
	root.add_child(scroll)
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)
	base_banner = BaseBanner.new()
	col.add_child(base_banner)
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(summary)
	treasure_choice = Label.new()
	treasure_choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(treasure_choice)
	keep_treasure = _command(col, "Keep first result", func() -> void:
		if campaign.resolve_treasure(false, treasure_dice):
			changed())
	alternate_treasure = _command(col, "Choose second result", func() -> void:
		if campaign.resolve_treasure(true, treasure_dice):
			changed())
	exchange_treasure=_command(col,"Exchange treasure",func() -> void:
		if RedKingRewards.exchange(campaign.data,treasure_dice):
			changed())
	spells = OptionButton.new()
	spells.add_theme_constant_override("icon_max_width",28)
	col.add_child(spells)
	improve = Button.new()
	improve.text = "Improve spell (100 XP)"
	col.add_child(improve)
	improve.pressed.connect(func() -> void:
		if spells.item_count > 0 and campaign.improve_spell(str(spells.get_selected_metadata())):
			campaign.save()
			refresh(false))
	stat = OptionButton.new()
	for id: String in CampaignProgress.STAT_CAPS:
		stat.add_item(id.capitalize())
		stat.set_item_metadata(stat.item_count - 1, id)
	col.add_child(stat)
	upgrade = _command(col, "Improve stat (100 XP)", func() -> void:
		if campaign.improve_stat(str(stat.get_selected_metadata()), db):
			changed())
	recruit = OptionButton.new()
	for id: String in db.figures:
		if db.available(id) and (db.get_def(id).role in ["soldier", "apprentice"] or id=="foulhorn"):
			recruit.add_item(db.get_def(id).name)
			recruit.set_item_metadata(recruit.item_count - 1, id)
	col.add_child(recruit)
	hire_button = _command(col, "Recruit", func() -> void:
		if campaign.hire(str(recruit.get_selected_metadata()), db):
			changed())
	members = OptionButton.new()
	col.add_child(members)
	dismiss_button = _command(col, "Dismiss selected member", func() -> void:
		if members.item_count > 0 and campaign.dismiss(int(members.get_selected_metadata())):
			changed())
	treat_button = _command(col, "Treat wounded caster (150gc; 50gc with apothecary)", func() -> void:
		if members.item_count > 0 and campaign.treat(int(members.get_selected_metadata())):
			changed())
	niggle = OptionButton.new()
	col.add_child(niggle)
	niggle_button = _command(col, "Pay treatment for niggling injury", func() -> void:
		if niggle.item_count > 0 and InjuryRules.treat(campaign.data, int(niggle.get_selected_metadata())):
			changed())
	base_choice = OptionButton.new()
	for id in CampaignProgress.BASES:
		if not db.content_profile.allows("bases",id):
			continue
		base_choice.add_item(id.capitalize() + " · " + str(BaseRules.BENEFITS.get(id, "")))
		base_choice.set_item_metadata(base_choice.item_count - 1, id)
	col.add_child(base_choice)
	base_button = _command(col, "Choose base (changing discards upgrades)", func() -> void:
		if campaign.choose_base(str(base_choice.get_selected_metadata())):
			changed())
	grimoire = OptionButton.new()
	col.add_child(grimoire)
	learn_button = _command(col, "Learn grimoire spell (100 XP)", func() -> void:
		if grimoire.item_count > 0 and campaign.learn_grimoire(int(grimoire.get_selected_metadata()), db):
			changed())
	controls.assign([stat, upgrade, recruit, hire_button, members, dismiss_button, treat_button, niggle, niggle_button, base_choice, base_button, grimoire, learn_button])
	inventory = InventoryPanel.new()
	col.add_child(inventory)
	inventory.setup(campaign, db, changed)
	controls.append(inventory)
	rituals = RitualPanel.new()
	col.add_child(rituals)
	rituals.setup(campaign, changed)
	controls.append(rituals)
	base_upgrades = BaseUpgradePanel.new()
	col.add_child(base_upgrades)
	base_upgrades.setup(campaign, db, changed)
	controls.append(base_upgrades)
	succession = SuccessionPanel.new()
	col.add_child(succession)
	succession.setup(campaign, changed, func() -> void: restart_requested.emit())
	start = Button.new()
	start.text = "Start campaign with current drafted warband"
	col.add_child(start)
	start.pressed.connect(func() -> void: start_requested.emit())
	story_veil=CheckBox.new()
	story_veil.text="Include optional Veil of Unreality"
	story_veil.button_pressed=true
	col.add_child(story_veil)
	story_strict_pursuit=CheckBox.new()
	story_strict_pursuit.text="Act II: no resupply during pursuit"
	story_strict_pursuit.tooltip_text="Optional harder intermission between Back Into the Fire and The Demons and the Mad Man."
	col.add_child(story_strict_pursuit)
	story_start=_command(col,"Start The Red King storyline",func() -> void: story_requested.emit(story_veil.button_pressed,story_strict_pursuit.button_pressed))
	reality_option=CheckBox.new()
	reality_option.text="Optional Reality Cracks (compatible maps)"
	reality_option.toggled.connect(func(on: bool) -> void:
		campaign.data["reality_cracks"]=on
		campaign.save())
	col.add_child(reality_option)
	wounded_option=CheckBox.new()
	wounded_option.text="Optional Wounded rule (all figures)"
	wounded_option.toggled.connect(func(on: bool) -> void:
		campaign.data["wounded_rules"]=on
		campaign.save())
	col.add_child(wounded_option)
	mantle_option=CheckBox.new()
	mantle_option.text="Red King: specialist animal companions"
	mantle_option.tooltip_text="Bear/leopard companions count as specialists unless the matching mantle is equipped. Core rules count them as standard soldiers."
	mantle_option.toggled.connect(func(on: bool) -> void:
		campaign.data[CompanionMantle.OPTION]=on
		changed())
	col.add_child(mantle_option)
	recruit_status=CheckBox.new()
	recruit_status.text="Roll optional status for random recruits"
	recruit_status.toggled.connect(func(on: bool) -> void:
		campaign.data["red_king_recruit_status"]=on
		campaign.save())
	col.add_child(recruit_status)
	roll_recruits=_command(col,"Roll random recruits",func() -> void:
		if RaggedWarbands.fill(campaign.data,db,treasure_dice)>0:
			changed())
	secret_hrut=CheckBox.new()
	secret_hrut.text="Spend Secret of the Hrut (+1 Fight)"
	secret_hrut.tooltip_text="One encounter only; all warband members gain +1 Fight against Hrut."
	secret_hrut.toggled.connect(func(on: bool) -> void:
		campaign.data["red_king_use_secret_hrut"]=on
		campaign.save())
	col.add_child(secret_hrut)
	skip_mind_button=_command(col,"Skip Mindscape (no rewards)",func() -> void:
		if RedKingCampaign.skip_mind(campaign.data):
			changed())
	reconcile_button=_command(col,"Reconcile warband after The Red King",func() -> void:
		if RedKingCampaign.reconcile(campaign.data,db):
			changed())
	continue_skirmishes=_command(col,"Return to ordinary campaign",func() -> void:
		if RedKingCampaign.return_to_skirmishes(campaign.data,db):
			changed())
	_scenario=OptionButton.new()
	_scenario.fit_to_longest_item=false
	_scenario.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	for id: String in ScenarioBriefing.available_entries(db.content_profile):
		if not RedKingCampaign.freeform_permits(id):
			continue
		_scenario.add_item(ScenarioBriefing.title(id))
		_scenario.set_item_metadata(_scenario.item_count-1,id)
		if id=="treasure_skirmish":
			_scenario.select(_scenario.item_count-1)
	_scenario.item_selected.connect(func(i: int) -> void:
		scenario_selected.emit(str(_scenario.get_item_metadata(i)))
		_refresh_briefing())
	col.add_child(_scenario)
	begin = Button.new()
	begin.text = "Play next campaign skirmish"
	col.add_child(begin)
	begin.pressed.connect(func() -> void: begin_requested.emit())
	_build_sections(col)


func refresh(in_battle: bool) -> void:
	var d := campaign.data
	base_banner.refresh(d)
	start.visible = d.is_empty()
	story_start.visible=d.is_empty() and db.content_profile.enabled.has("red_king") and db.content_profile.allows("campaigns","red_king")
	story_veil.visible=story_start.visible
	story_strict_pursuit.visible=story_start.visible
	begin.visible = not d.is_empty()
	_scenario.visible=not d.is_empty() and not in_battle and not RedKingCampaign.active(d)
	var stage := RedKingCampaign.next_stage(d)
	_refresh_briefing()
	reality_option.visible=not d.is_empty() and not in_battle and db.content_profile.rule("red_king_reality_cracks")
	reality_option.set_pressed_no_signal(bool(d.get("reality_cracks",false)))
	wounded_option.visible=not d.is_empty() and not in_battle
	wounded_option.set_pressed_no_signal(bool(d.get("wounded_rules",false)))
	mantle_option.visible=not d.is_empty() and not in_battle and db.content_profile.enabled.has("red_king")
	mantle_option.set_pressed_no_signal(bool(d.get(CompanionMantle.OPTION,false)))
	recruit_status.visible=RaggedWarbands.active(d) and not in_battle and not stage.is_empty()
	recruit_status.set_pressed_no_signal(bool(d.get("red_king_recruit_status",false)))
	roll_recruits.visible=RaggedWarbands.active(d) and not in_battle and not stage.is_empty() and d.get("pending_treasure",[]).is_empty() and CampaignSuccession.living_wizard(d) and RaggedWarbands.ready_count(d)<10
	roll_recruits.text="Roll %d replacement recruits"%maxi(0,10-RaggedWarbands.ready_count(d))
	secret_hrut.visible=bool(d.get("red_king_secret_hrut",false)) and not in_battle and (not RedKingCampaign.active(d) or (not stage.is_empty() and stage.get("id","")!="red_king_mind"))
	secret_hrut.set_pressed_no_signal(bool(d.get("red_king_use_secret_hrut",false)))
	skip_mind_button.visible=RedKingCampaign.next_id(d)=="red_king_mind" and not in_battle
	skip_mind_button.disabled=not d.get("pending_treasure",[]).is_empty()
	reconcile_button.visible=RedKingCampaign.active(d) and stage.is_empty() and RaggedWarbands.active(d) and not in_battle
	reconcile_button.disabled=not d.get("pending_treasure",[]).is_empty()
	continue_skirmishes.visible=bool(d.get("red_king_reconcile_pending",false)) and not in_battle
	continue_skirmishes.disabled=not BaseResources.fits(d,db)
	begin.text=("Play "+str(stage.get("title","")) if not stage.is_empty() else "Story concluded") if RedKingCampaign.active(d) else "Play next campaign skirmish"
	spells.visible = not d.is_empty() and not in_battle
	improve.visible = spells.visible
	var pending: Array = d.get("pending_treasure", [])
	var deciding := not pending.is_empty() and not in_battle
	succession.refresh(in_battle, deciding)
	treasure_choice.visible = deciding
	keep_treasure.visible = deciding
	alternate_treasure.visible = deciding
	exchange_treasure.visible=false
	if deciding:
		var entry: Dictionary = pending[0]
		treasure_choice.text = "%d reward choices remaining\nTreasure %d: %s" % [pending.size(), int(entry["token"]) + 1, CampaignProgress.treasure_label(int(entry["first"]))]
		keep_treasure.text="Keep first result"
		if entry.has("rk_roll"):
			var rolls: Array=entry["rk_roll"]
			treasure_choice.text="%d reward choices remaining\nRed King rolls %d, %d · Optional +2"%[pending.size(),rolls[0],rolls[1]]
			keep_treasure.text="Keep: "+RedKingRewards.label(rolls[0],rolls[1])
			alternate_treasure.text="+2: "+RedKingRewards.label(rolls[0],rolls[1]+2)
		elif entry["central"]:
			alternate_treasure.text = "Reroll central treasure (must accept)"
		elif int(entry.get("second",0))>0:
			alternate_treasure.text = "Choose: " + CampaignProgress.treasure_label(int(entry["second"]))
		else:
			alternate_treasure.visible=false
		var exchange := RedKingRewards.offer(d,entry)
		exchange_treasure.visible=not exchange.is_empty()
		exchange_treasure.text="Exchange for artefact" if exchange=="artefact" else "Exchange for Red King treasure"
	for control in controls:
		control.visible = not d.is_empty() and not in_battle and not deciding
	_section_picker.visible=not d.is_empty() and not deciding and not in_battle
	_briefing.visible=_briefing.visible and not deciding and not in_battle
	_quick_prepare.visible=_section_picker.visible and (ScrollShield.campaign_index(d,"roll")>=0 or (not stage.is_empty() and RaggedWarbands.active(d)))
	_quick_prepare.text="Roll Scroll Shield / prepare rituals" if ScrollShield.campaign_index(d,"roll")>=0 else "Prepare summoning rituals first"
	_quick_gear.visible=_section_picker.visible and RaggedWarbands.has_unassigned(d) and RaggedWarbands.active(d)
	_quick_warband.visible=_section_picker.visible and not CampaignSuccession.living_wizard(d)
	_quick_report.visible=_section_picker.visible and not d.get("last_report",[]).is_empty()
	if deciding:
		recruit_status.hide()
		secret_hrut.hide()
		reconcile_button.hide()
		continue_skirmishes.hide()
	if not _section_picker.visible:
		_show_section(0)
	if d.is_empty():
		_depart_status.hide()
		summary.text = "Choose a campaign. Your saved warband or a default draft will be used. Progress is saved between battles."
		return
	inventory.refresh()
	rituals.refresh()
	base_upgrades.refresh()
	var lines: Array[String] = ["%s · Level %d · %d XP · %d gc · %d battles" % [d["name"], d["level"], d["xp"], d["gold"], d["games"]]]
	if RedKingCampaign.active(d):
		lines.append("THE RED KING · "+("Story concluded" if stage.is_empty() else "Act %d · Chapter %d/%d · %s"%[stage["act"],stage["number"],RedKingCampaign.stages().size(),stage["title"]]))
		if stage.is_empty():
			lines.append("Finale: "+("Red King defeated." if d.get("red_king_completed",false) else "The invasion was not stopped."))
		if RedKingCampaign.economy_locked(d) and not RaggedWarbands.active(d):
			lines.append("Pursued by the Red King: no purchases, hiring or base benefits until after this encounter.")
	if RaggedWarbands.active(d):
		lines.append("RAGGED WARBANDS · %d/10 ready. No hiring, purchases or base benefits. Finish summoning rituals, roll replacements, then assign equipment."%mini(10,RaggedWarbands.ready_count(d)))
		if RaggedWarbands.ready_count(d)>10:
			lines.append("%d recovered surplus members remain in reserve."%(RaggedWarbands.ready_count(d)-10))
	var roster_lines: Array[String]=[]
	for unit: Dictionary in d["units"]:
		roster_lines.append("%s #%d%s%s" % [str(unit["type"]).capitalize(), int(unit["id"]) + 1, " — dead" if unit["dead"] else (" — dismissed" if unit.get("dismissed",false) else (" — separated" if unit.get("ragged_absent",false) else (" — resting" if int(unit["miss"]) > 0 else ""))), " — injuries: %d" % unit["injuries"] if int(unit["injuries"]) > 0 else ""])
	for unit: Dictionary in d["units"]:
		for id: String in unit.get("injury_types", {}):
			roster_lines.append("  #%d: %s ×%d" % [int(unit["id"]) + 1, id.replace("_", " ").capitalize(), unit["injury_types"][id]])
		if InjuryRules.blind(unit) and not unit["dead"]:
			roster_lines.append("  #%d: cannot deploy until cured." % [int(unit["id"]) + 1])
	niggle.clear()
	for unit: Dictionary in d["units"]:
		var price := InjuryRules.treatment_price(d, unit)
		if price >= 0:
			niggle.add_item("%s #%d · %d gc" % [str(unit["type"]).capitalize(), int(unit["id"]) + 1, price])
			niggle.set_item_metadata(niggle.item_count - 1, int(unit["id"]))
	niggle_button.disabled = niggle.item_count == 0
	var reserve := BaseResources.reserve_id(RedKingCampaign.capacity_context(d), db)
	if reserve >= 0:
		roster_lines.append("Inn reserve: %s #%d" % [db.get_def(d["units"][reserve]["type"]).name, reserve + 1])
	var blockers := campaign.deployment_blockers()
	_depart_status.visible=not in_battle
	_depart_status.text="Ready to depart" if blockers.is_empty() else "Before departure:\n• "+"\n• ".join(blockers)
	_depart_status.modulate=Color("a9ddbf") if blockers.is_empty() else Color("f2c392")
	lines.append("Base: %s | Stored loot: %d" % [str(d.get("base", "")).capitalize(), d["loot"].size()])
	roster_lines.append("Stat advances: %s" % str(d.get("advances", {})))
	_roster_summary.text="\n".join(roster_lines)
	members.clear()
	for i in d["units"].size():
		var unit: Dictionary = d["units"][i]
		if unit["dead"] or unit.get("dismissed", false) or unit.get("ragged_absent",false) or unit["type"] == "wizard" and int(unit["miss"]) == 0:
			continue
		members.add_item("%s #%d%s" % [str(unit["type"]).capitalize(), int(unit["id"]) + 1, " (resting)" if int(unit["miss"]) > 0 else ""])
		members.set_item_metadata(members.item_count - 1, i)
	grimoire.clear()
	for i in d["loot"].size():
		var item: Dictionary = d["loot"][i]
		if item["kind"] == "grimoire" and item.has("spell") and not d["spells"].has(item["spell"]):
			grimoire.add_item(str(item["spell"]).capitalize())
			grimoire.set_item_metadata(grimoire.item_count - 1, i)
	upgrade.disabled = not CampaignSuccession.living_wizard(d) or bool(d.get("stat_improved", false)) or int(d["xp"]) < 100
	base_button.disabled = RedKingCampaign.economy_locked(d) or int(d["games"]) == 0
	for i in base_choice.item_count:
		var id := str(base_choice.get_item_metadata(i))
		var proposed := d.duplicate(true)
		if id != d.get("base", ""):
			proposed["base"] = id
			proposed["resources"] = []
		base_choice.set_item_disabled(i, not BaseResources.fits(proposed, db))
	dismiss_button.disabled = RedKingCampaign.economy_locked(d) or members.item_count == 0
	treat_button.disabled = RedKingCampaign.economy_locked(d) or members.item_count == 0
	learn_button.disabled = not CampaignSuccession.living_wizard(d) or grimoire.item_count == 0 or int(d["xp"]) < 100
	for i in recruit.item_count:
		var id := str(recruit.get_item_metadata(i))
		recruit.set_item_text(i, "%s · %d gc" % [db.get_def(id).name, campaign.recruitment_cost(id, db)])
		recruit.set_item_disabled(i, not campaign.can_hire(id, db))
	var history_lines: Array[String]=[]
	if RedKingCampaign.active(d) or d.has("red_king_history"):
		for chapter: Dictionary in RedKingCampaign.stages():
			var id := str(chapter["id"])
			var status := "Complete" if d.get("red_king_history",[]).has(id) else ("Next" if id==RedKingCampaign.next_id(d) else ("Skipped" if int(chapter["number"])<=int(d.get("red_king_stage",0)) else "Ahead"))
			history_lines.append("%02d · %s — %s"%[chapter["number"],chapter["title"],status])
		history_lines.append("")
	history_lines.append("Latest report")
	for line: String in d["last_report"]:
		history_lines.append(line)
	_history_summary.text="\n".join(history_lines)
	if in_battle:
		lines.append("Campaign battle in progress. Close to return.")
	summary.text = "\n".join(lines)
	spells.clear()
	for id: String in d["spells"]:
		if int(d["spells"][id]) <= 5:
			continue
		var info: Dictionary = _spell_catalog.get(id,{})
		spells.add_icon_item(ActionArt.school(str(info.get("school",""))),"%s · TN%d" % [str(info.get("name",id.capitalize())), d["spells"][id]])
		spells.set_item_metadata(spells.item_count - 1, id)
	improve.disabled = deciding or in_battle or not CampaignSuccession.living_wizard(d) or bool(d["spell_improved"]) or int(d["xp"]) < 100 or spells.item_count == 0
	begin.disabled = in_battle or not blockers.is_empty()
	begin.visible=not in_battle and not d.is_empty() and (not RedKingCampaign.active(d) or not stage.is_empty())
	hire_button.disabled=true
	for i in recruit.item_count:
		if not recruit.is_item_disabled(i):
			hire_button.disabled=false
			break


func changed() -> void:
	campaign.save()
	refresh(false)


func _command(parent: Control, label: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = label
	parent.add_child(b)
	b.pressed.connect(callback)
	return b


func fit_phone() -> void:
	var bounds := PhoneSafeArea.safe_rect(get_parent().get_viewport(),14).size
	_scroll.custom_minimum_size=Vector2(minf(900,bounds.x*0.86),minf(440,bounds.y*0.58))


func select_scenario(id: String) -> void:
	for i in _scenario.item_count:
		if _scenario.get_item_metadata(i)==id:
			_scenario.select(i)
			_refresh_briefing()
			return


## Group existing controls without changing their callbacks or campaign rules.
func _build_sections(col: VBoxContainer) -> void:
	for section: String in SECTIONS:
		var page := VBoxContainer.new()
		page.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		page.add_theme_constant_override("separation",8)
		col.add_child(page)
		_sections.append(page)
	_briefing=_info_label()
	_depart_status=_info_label()
	_roster_summary=_info_label()
	_history_summary=_info_label()
	_quick_prepare=_command(_sections[0],"Prepare summoning rituals first",func() -> void: _show_section(3))
	_quick_gear=_command(_sections[0],"Assign or discard new loot",func() -> void: _show_section(2))
	_quick_warband=_command(_sections[0],"Resolve wizard succession",func() -> void: _show_section(1))
	_quick_report=_command(_sections[0],"Read latest battle report",func() -> void: _show_section(5))
	_sections[0].add_child(_briefing)
	_sections[0].add_child(_depart_status)
	_sections[1].add_child(_roster_summary)
	_sections[5].add_child(_history_summary)
	_move_controls(0,[summary,start,story_veil,story_strict_pursuit,story_start,treasure_choice,keep_treasure,alternate_treasure,exchange_treasure,_scenario,begin,secret_hrut,skip_mind_button,recruit_status,roll_recruits,reconcile_button,continue_skirmishes])
	_sections[0].move_child(summary,0)
	_sections[0].move_child(_scenario,1)
	_sections[0].move_child(_briefing,2)
	_sections[0].move_child(_depart_status,3)
	_sections[0].move_child(begin,4)
	_move_controls(1,[spells,improve,stat,upgrade,recruit,hire_button,members,dismiss_button,treat_button,niggle,niggle_button,grimoire,learn_button,succession])
	_move_controls(2,[inventory])
	_move_controls(3,[rituals])
	_move_controls(4,[base_banner,base_choice,base_button,base_upgrades])
	_move_controls(5,[reality_option,wounded_option,mantle_option])
	_touch_controls(col)
	_show_section(0)


func _move_controls(index: int,items: Array) -> void:
	for control: Control in items:
		control.reparent(_sections[index],false)


func _info_label() -> Label:
	var label := Label.new()
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label


func _touch_controls(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton:
			child.custom_minimum_size.y=maxf(48,child.custom_minimum_size.y)
		if child is OptionButton:
			child.fit_to_longest_item=false
			child.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		elif child is Button:
			child.clip_text=true
			if child.tooltip_text.is_empty():
				child.tooltip_text=child.text
		if child is Control:
			_touch_controls(child)


func _show_section(index: int) -> void:
	if index<0 or index>=_sections.size():
		return
	_section_picker.select(index)
	for i in _sections.size():
		_sections[i].visible=i==index
	_scroll.scroll_vertical=0


func _refresh_briefing() -> void:
	if _briefing==null:
		return
	var d := campaign.data
	var id := RedKingCampaign.next_id(d) if RedKingCampaign.active(d) else str(_scenario.get_selected_metadata())
	_briefing.visible=not d.is_empty() and not id.is_empty()
	_briefing.text=ScenarioBriefing.description(id) if _briefing.visible else ""
