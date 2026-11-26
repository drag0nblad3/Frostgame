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


func setup(progress: CampaignProgress) -> void:
	campaign = progress
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
	if d.is_empty():
		summary.text = "Create a warband first, or start with a basic default draft. Campaign progress is saved between battles."
		return
	var lines: Array[String] = ["%s · Level %d · %d XP · %d gc · %d battles" % [d["name"], d["level"], d["xp"], d["gold"], d["games"]]]
	for unit: Dictionary in d["units"]:
		lines.append("%s #%d%s%s" % [str(unit["type"]).capitalize(), int(unit["id"]) + 1, " — dead" if unit["dead"] else (" — resting" if int(unit["miss"]) > 0 else ""), " — injuries: %d" % unit["injuries"] if int(unit["injuries"]) > 0 else ""])
	lines.append("Unidentified loot entries: %d" % d["loot"].size())
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
