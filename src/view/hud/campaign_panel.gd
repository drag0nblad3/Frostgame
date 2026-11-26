class_name CampaignPanel
extends AcceptDialog
## Between-battle campaign overview. Starting a campaign is an explicit action.
signal start_requested
signal begin_requested
signal restart_requested
signal scenario_selected(id: String)
var _scroll: ScrollContainer
var _scenario: OptionButton
var campaign: CampaignProgress
var summary: Label
var base_banner: BaseBanner
var _spell_catalog: Dictionary
var spells: OptionButton
var improve: Button
var start: Button
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
	fit_phone()
	add_child(scroll)
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
		if db.available(id) and db.get_def(id).role in ["soldier", "apprentice"]:
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
	_scenario=OptionButton.new()
	_scenario.fit_to_longest_item=false
	_scenario.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	for id: String in ScenarioBriefing.available_entries(db.content_profile):
		_scenario.add_item(ScenarioBriefing.title(id))
		_scenario.set_item_metadata(_scenario.item_count-1,id)
		if id=="treasure_skirmish":
			_scenario.select(_scenario.item_count-1)
	_scenario.item_selected.connect(func(i: int) -> void:scenario_selected.emit(str(_scenario.get_item_metadata(i))))
	col.add_child(_scenario)
	begin = Button.new()
	begin.text = "Play next campaign skirmish"
	col.add_child(begin)
	begin.pressed.connect(func() -> void: begin_requested.emit())


func refresh(in_battle: bool) -> void:
	var d := campaign.data
	base_banner.refresh(d)
	start.visible = d.is_empty()
	begin.visible = not d.is_empty()
	_scenario.visible=not d.is_empty() and not in_battle
	spells.visible = not d.is_empty()
	improve.visible = not d.is_empty()
	var pending: Array = d.get("pending_treasure", [])
	var deciding := not pending.is_empty() and not in_battle
	succession.refresh(in_battle, deciding)
	treasure_choice.visible = deciding
	keep_treasure.visible = deciding
	alternate_treasure.visible = deciding
	if deciding:
		var entry: Dictionary = pending[0]
		treasure_choice.text = "Treasure %d: %s" % [int(entry["token"]) + 1, CampaignProgress.treasure_label(int(entry["first"]))]
		if entry["central"]:
			alternate_treasure.text = "Reroll central treasure (must accept)"
		else:
			alternate_treasure.text = "Choose: " + CampaignProgress.treasure_label(int(entry["second"]))
	for control in controls:
		control.visible = not d.is_empty() and not in_battle and not deciding
	if d.is_empty():
		summary.text = "Create a warband first, or start with a basic default draft. Campaign progress is saved between battles."
		return
	inventory.refresh()
	rituals.refresh()
	base_upgrades.refresh()
	var lines: Array[String] = ["%s · Level %d · %d XP · %d gc · %d battles" % [d["name"], d["level"], d["xp"], d["gold"], d["games"]]]
	if RaggedWarbands.active(d):
		lines.append("RAGGED WARBANDS · No hiring, purchases or base benefits. Free random replacements before battle.")
	for unit: Dictionary in d["units"]:
		lines.append("%s #%d%s%s" % [str(unit["type"]).capitalize(), int(unit["id"]) + 1, " — dead" if unit["dead"] else (" — resting" if int(unit["miss"]) > 0 else ""), " — injuries: %d" % unit["injuries"] if int(unit["injuries"]) > 0 else ""])
	for unit: Dictionary in d["units"]:
		for id: String in unit.get("injury_types", {}):
			lines.append("  #%d: %s ×%d" % [int(unit["id"]) + 1, id.replace("_", " ").capitalize(), unit["injury_types"][id]])
		if InjuryRules.blind(unit) and not unit["dead"]:
			lines.append("  #%d: cannot deploy until cured." % [int(unit["id"]) + 1])
	niggle.clear()
	for unit: Dictionary in d["units"]:
		var price := InjuryRules.treatment_price(d, unit)
		if price >= 0:
			niggle.add_item("%s #%d · %d gc" % [str(unit["type"]).capitalize(), int(unit["id"]) + 1, price])
			niggle.set_item_metadata(niggle.item_count - 1, int(unit["id"]))
	niggle_button.disabled = niggle.item_count == 0
	var reserve := BaseResources.reserve_id(d, db)
	if reserve >= 0:
		lines.append("Inn reserve: %s #%d" % [db.get_def(d["units"][reserve]["type"]).name, reserve + 1])
	lines.append("Base: %s | Stored loot: %d" % [str(d.get("base", "")).capitalize(), d["loot"].size()])
	lines.append("Stat advances: %s" % str(d.get("advances", {})))
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
	base_button.disabled = RaggedWarbands.active(d) or int(d["games"]) == 0
	for i in base_choice.item_count:
		var id := str(base_choice.get_item_metadata(i))
		var proposed := d.duplicate(true)
		if id != d.get("base", ""):
			proposed["base"] = id
			proposed["resources"] = []
		base_choice.set_item_disabled(i, not BaseResources.fits(proposed, db))
	dismiss_button.disabled = RaggedWarbands.active(d) or members.item_count == 0
	treat_button.disabled = RaggedWarbands.active(d) or members.item_count == 0
	learn_button.disabled = not CampaignSuccession.living_wizard(d) or grimoire.item_count == 0 or int(d["xp"]) < 100
	for i in recruit.item_count:
		var id := str(recruit.get_item_metadata(i))
		recruit.set_item_text(i, "%s · %d gc" % [db.get_def(id).name, campaign.recruitment_cost(id, db)])
		recruit.set_item_disabled(i, not campaign.can_hire(id, db))
	for line: String in d["last_report"]:
		lines.append(line)
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
	begin.disabled = in_battle or not campaign.can_deploy()


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
	_scroll.custom_minimum_size=Vector2(minf(720,bounds.x*0.86),minf(490,bounds.y*0.76))


func select_scenario(id: String) -> void:
	for i in _scenario.item_count:
		if _scenario.get_item_metadata(i)==id:
			_scenario.select(i)
			return
