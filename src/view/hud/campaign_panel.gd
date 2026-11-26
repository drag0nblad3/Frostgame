class_name CampaignPanel
extends AcceptDialog
## Between-battle campaign overview. Starting a campaign is an explicit action.
signal start_requested
signal begin_requested
var campaign: CampaignProgress
var summary: Label
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


func setup(progress: CampaignProgress, figures: FigureDb) -> void:
	campaign = progress
	db = figures
	title = "Campaign"
	get_ok_button().text = "Close"
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(650, 400)
	add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(summary)
	spells = OptionButton.new()
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
		if db.get_def(id).role in ["soldier", "apprentice"]:
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
	base_choice = OptionButton.new()
	for id in CampaignProgress.BASES:
		base_choice.add_item(id.capitalize())
		base_choice.set_item_metadata(base_choice.item_count - 1, id)
	col.add_child(base_choice)
	base_button = _command(col, "Choose base (free after first battle)", func() -> void:
		if campaign.choose_base(str(base_choice.get_selected_metadata())):
			changed())
	grimoire = OptionButton.new()
	col.add_child(grimoire)
	learn_button = _command(col, "Learn grimoire spell (100 XP)", func() -> void:
		if grimoire.item_count > 0 and campaign.learn_grimoire(int(grimoire.get_selected_metadata()), db):
			changed())
	controls.assign([stat, upgrade, recruit, hire_button, members, dismiss_button, treat_button, base_choice, base_button, grimoire, learn_button])
	inventory = InventoryPanel.new()
	col.add_child(inventory)
	inventory.setup(campaign, db, changed)
	controls.append(inventory)
	start = Button.new()
	start.text = "Start campaign with current drafted warband"
	col.add_child(start)
	start.pressed.connect(func() -> void: start_requested.emit())
	begin = Button.new()
	begin.text = "Play next campaign skirmish"
	col.add_child(begin)
	begin.pressed.connect(func() -> void: begin_requested.emit())


func refresh(in_battle: bool) -> void:
	var d := campaign.data
	start.visible = d.is_empty()
	begin.visible = not d.is_empty()
	spells.visible = not d.is_empty()
	improve.visible = not d.is_empty()
	for control in controls:
		control.visible = not d.is_empty() and not in_battle
	if d.is_empty():
		summary.text = "Create a warband first, or start with a basic default draft. Campaign progress is saved between battles."
		return
	inventory.refresh()
	var lines: Array[String] = ["%s · Level %d · %d XP · %d gc · %d battles" % [d["name"], d["level"], d["xp"], d["gold"], d["games"]]]
	for unit: Dictionary in d["units"]:
		lines.append("%s #%d%s%s" % [str(unit["type"]).capitalize(), int(unit["id"]) + 1, " — dead" if unit["dead"] else (" — resting" if int(unit["miss"]) > 0 else ""), " — injuries: %d" % unit["injuries"] if int(unit["injuries"]) > 0 else ""])
	lines.append("Base: %s | Stored loot: %d" % [str(d.get("base", "")).capitalize(), d["loot"].size()])
	lines.append("Stat advances: %s" % str(d.get("advances", {})))
	members.clear()
	for i in d["units"].size():
		var unit: Dictionary = d["units"][i]
		if unit["dead"] or unit.get("dismissed", false) or unit["type"] == "wizard" and int(unit["miss"]) == 0:
			continue
		members.add_item("%s #%d%s" % [str(unit["type"]).capitalize(), int(unit["id"]) + 1, " (resting)" if int(unit["miss"]) > 0 else ""])
		members.set_item_metadata(members.item_count - 1, i)
	grimoire.clear()
	for i in d["loot"].size():
		var item: Dictionary = d["loot"][i]
		if item["kind"] == "grimoire" and item.has("spell") and not d["spells"].has(item["spell"]):
			grimoire.add_item(str(item["spell"]).capitalize())
			grimoire.set_item_metadata(grimoire.item_count - 1, i)
	upgrade.disabled = bool(d.get("stat_improved", false)) or int(d["xp"]) < 100
	base_button.disabled = int(d["games"]) == 0
	dismiss_button.disabled = members.item_count == 0
	treat_button.disabled = members.item_count == 0
	learn_button.disabled = grimoire.item_count == 0 or int(d["xp"]) < 100
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
		spells.add_item("%s · TN%d" % [id.capitalize(), d["spells"][id]])
		spells.set_item_metadata(spells.item_count - 1, id)
	improve.disabled = in_battle or bool(d["spell_improved"]) or int(d["xp"]) < 100 or spells.item_count == 0
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
