class_name ScenarioDialog
extends ExpeditionScreen
## Read-only current briefing or explicit start confirmation.
signal start_requested
var _body: RichTextLabel
var _mode_start := false
var _split: BoxContainer
var _map: ScenarioMapPreview


func _ready() -> void:
	build("SCENARIO BRIEFING","Return to battle",_accept)
	_split=BoxContainer.new()
	_split.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_split.add_theme_constant_override("separation",14)
	body.add_child(_split)
	_map=ScenarioMapPreview.new()
	_map.custom_minimum_size.y=160
	_map.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_map.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_split.add_child(_map)
	_body=RichTextLabel.new()
	_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_body.size_flags_stretch_ratio=1.4
	_body.add_theme_font_size_override("normal_font_size",26)
	_body.add_theme_constant_override("line_separation",8)
	_split.add_child(_body)


func _accept() -> void:
	hide()
	if _mode_start:
		start_requested.emit()


func _reflow() -> void:
	if _split!=null:
		_split.vertical=size.x<size.y


func show_briefing(id: String, state: GameState, start: bool) -> void:
	_mode_start = start
	title = ScenarioBriefing.title(id)
	heading.text=title
	action.text = "Start skirmish" if start else "Return to battle"
	var data: Dictionary = JsonFile.read(ScenarioLoader.DIR + id + ".json")
	_map.setup_scenario(data)
	subtitle.text="Battlefield objectives and special rules"
	var count: int = data.get("treasures", []).size()
	var encounters := "Wandering encounters enabled." if data.get("random_encounters", false) else "No random pickup encounters."
	_body.text = ScenarioBriefing.description(id)
	if not id.begins_with("red_king_"):
		_body.text += "\n\n%d treasure tokens. %s\n\nMost secured treasure wins. A second movement action is at half speed; carrying ordinary treasure also halves movement." % [count, encounters]
	else:
		_body.text += "\n\nExpansion encounter · Follow the special objectives above."
	if start:
		_body.text += "\n\nStarting a skirmish replaces the current battle. Use Menu → Save battle first if you want to return to it."
	elif state != null:
		_body.text += "\n\nCURRENT PROGRESS\n" + ScenarioBriefing.progress(state)
	show_screen()
