class_name WarbandSetup
extends AcceptDialog
## Modal roster editor for a new skirmish, with live rules validation.

signal drafted(roster: Dictionary)

var draft: WarbandDraft
var _spell_rows: VBoxContainer
var _recruits: OptionButton
var _roster: ItemList
var _summary: Label
var _name: LineEdit
var _school: OptionButton
var _apprentice: CheckBox
var _hire: Button
var _recruit_portrait: MiniaturePortrait
var _recruit_info: Label


func setup(db: FigureDb) -> void:
	draft = WarbandDraft.new(db)
	draft.choose_defaults()
	theme = BattleTheme.create()
	title = "Create a wizard and warband"
	get_ok_button().text = "Begin skirmish"
	dialog_hide_on_ok = false
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(700, 480)
	add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	_name = LineEdit.new()
	_name.placeholder_text = "Wizard name"
	_name.text = draft.wizard_name
	body.add_child(_name)
	_name.text_changed.connect(func(value: String) -> void:
		draft.wizard_name = value
		_update())
	_school = OptionButton.new()
	for id: String in draft.schools:
		_school.add_item(id.capitalize())
		_school.set_item_metadata(_school.item_count - 1, id)
		if id == draft.school:
			_school.select(_school.item_count - 1)
	body.add_child(_school)
	_school.item_selected.connect(_change_school)
	_spell_rows = VBoxContainer.new()
	body.add_child(_spell_rows)
	_apprentice = CheckBox.new()
	_apprentice.text = "Hire apprentice (100 gc)"
	_apprentice.button_pressed = draft.apprentice
	body.add_child(_apprentice)
	_apprentice.toggled.connect(func(on: bool) -> void:
		draft.apprentice = on
		_update())
	_add_loadout(body, "Wizard weapons", false)
	_add_loadout(body, "Apprentice weapons", true)
	var row := HBoxContainer.new()
	body.add_child(row)
	_recruits = OptionButton.new()
	_recruits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for id: String in db.figures:
		var d := db.get_def(id)
		if d.role != "soldier":
			continue
		_recruits.add_item("%s · %d gc%s" % [d.name, d.cost, " · Specialist" if d.specialist else ""])
		_recruits.set_item_metadata(_recruits.item_count - 1, id)
	row.add_child(_recruits)
	_recruits.item_selected.connect(func(_i: int) -> void: _update())
	_hire = Button.new()
	_hire.text = "Hire"
	row.add_child(_hire)
	_hire.pressed.connect(func() -> void:
		draft.hire(str(_recruits.get_selected_metadata()))
		_update())
	var recruit_card := HBoxContainer.new()
	body.add_child(recruit_card)
	_recruit_portrait = MiniaturePortrait.new()
	_recruit_portrait.custom_minimum_size = Vector2(190, 165)
	recruit_card.add_child(_recruit_portrait)
	_recruit_info = Label.new()
	_recruit_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_recruit_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recruit_card.add_child(_recruit_info)
	_roster = ItemList.new()
	_roster.custom_minimum_size.y = 130
	body.add_child(_roster)
	var remove := Button.new()
	remove.text = "Remove selected soldier"
	body.add_child(remove)
	remove.pressed.connect(func() -> void:
		var selected := _roster.get_selected_items()
		if not selected.is_empty():
			draft.soldiers.remove_at(selected[0])
			_update())
	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_summary)
	confirmed.connect(_confirm)
	_rebuild_spells()
	_update()


func _change_school(index: int) -> void:
	draft.school = str(_school.get_item_metadata(index))
	draft.choose_defaults()
	_rebuild_spells()
	_update()


func _rebuild_spells() -> void:
	for child in _spell_rows.get_children():
		_spell_rows.remove_child(child)
		child.queue_free()
	for slot in 8:
		var choice := OptionButton.new()
		var label := Label.new()
		label.text = "Home school %d" % (slot + 1) if slot < 3 else ("Aligned: " + str(draft.schools[draft.school]["aligned"][slot - 3]).capitalize() if slot < 6 else "Neutral school")
		_spell_rows.add_child(label)
		for id in draft.candidates(slot):
			var info: Dictionary = draft.catalog[id]
			var live: bool = info["kind"] != "unimplemented"
			var suffix := "" if live else " · NOT PLAYABLE YET"
			if Rituals.BEFORE.has(id) or Rituals.AFTER.has(id):
				suffix = " · Campaign ritual" if info["kind"] == "ritual" else " · Battle / preparation"
			choice.add_item("%s · %s · TN%d%s" % [info["name"], str(info["school"]).capitalize(), draft.casting_number(id), suffix])
			choice.set_item_metadata(choice.item_count - 1, id)
			if draft.spells[slot] == id:
				choice.select(choice.item_count - 1)
		_spell_rows.add_child(choice)
		choice.item_selected.connect(func(index: int) -> void:
			draft.spells[slot] = str(choice.get_item_metadata(index))
			_update())


func _update() -> void:
	if _summary == null:
		return
	_roster.clear()
	for id in draft.soldiers:
		var d := draft.db.get_def(id)
		_roster.add_item("%s · %d gc" % [d.name, d.cost])
	var problems := draft.errors()
	var live := 0
	for id in draft.spells:
		if draft.catalog[id]["kind"] != "unimplemented" or Rituals.BEFORE.has(id) or Rituals.AFTER.has(id):
			live += 1
	_summary.text = "%d gc left | %d/8 soldiers | %d/4 specialists | %d/8 implemented spells\n%s" % [WarbandDraft.BUDGET - draft.cost(), draft.soldiers.size(), draft.specialists(), live, "Campaign rituals are available between battles." if problems.is_empty() else "\n".join(problems)]
	var recruit_id := str(_recruits.get_selected_metadata())
	_hire.disabled = not draft.can_hire(recruit_id)
	var definition := draft.db.get_def(recruit_id)
	if definition != null:
		_recruit_portrait.set_figure(Figure.new(0, definition, 0, Vector2.ZERO, draft.db.unarmed()), FigureView.SIDE_COLORS[0])
		_recruit_info.text = "%s · %d gc\nM %d″   F %+d   S %+d\nA %d   W %+d   H %d\n%s" % [definition.name, definition.cost, definition.move, definition.fight, definition.shoot, definition.armour, definition.will, definition.health, "Specialist" if definition.specialist else "Standard soldier"]
	get_ok_button().disabled = not problems.is_empty()


func _confirm() -> void:
	if not draft.errors().is_empty():
		return
	drafted.emit(draft.as_warband())
	hide()



func _add_loadout(body: VBoxContainer, title_text: String, for_apprentice: bool) -> void:
	var label := Label.new()
	label.text = title_text
	body.add_child(label)
	var choice := OptionButton.new()
	for preset: String in CasterLoadout.PRESETS:
		var weapons: Array = CasterLoadout.PRESETS[preset]
		choice.add_item("%s · %d slots" % [preset, CasterLoadout.weapon_slots(weapons)])
		choice.set_item_metadata(choice.item_count - 1, preset)
	body.add_child(choice)
	choice.item_selected.connect(func(index: int) -> void:
		var weapons: Array = CasterLoadout.PRESETS[choice.get_item_metadata(index)]
		if for_apprentice:
			draft.apprentice_weapons = weapons.duplicate()
		else:
			draft.wizard_weapons = weapons.duplicate()
		_update())
