class_name ScenarioDialog
extends AcceptDialog
## Read-only current briefing or explicit start confirmation.
signal start_requested
var _body: RichTextLabel
var _mode_start := false


func _ready() -> void:
	title = "Scenario briefing"
	exclusive = true
	unresizable = true
	theme = BattleTheme.create()
	_body = RichTextLabel.new()
	_body.bbcode_enabled = false
	_body.fit_content = false
	_body.scroll_active = true
	_body.custom_minimum_size = Vector2(260, 180)
	_body.add_theme_font_size_override("normal_font_size", 20)
	add_child(_body)
	confirmed.connect(func() -> void:
		if _mode_start:
			start_requested.emit())


func show_briefing(id: String, state: GameState, start: bool) -> void:
	_mode_start = start
	title = ScenarioBriefing.title(id)
	get_ok_button().text = "Start skirmish" if start else "Return to battle"
	var data: Dictionary = JsonFile.read(ScenarioLoader.DIR + id + ".json")
	var count: int = data.get("treasures", []).size()
	var encounters := "Wandering encounters enabled." if data.get("random_encounters", false) else "No random pickup encounters."
	_body.text = ScenarioBriefing.description(id) + "\n\n%d treasure tokens. %s\n\nMost secured treasure wins. A second movement action is at half speed; carrying ordinary treasure also halves movement." % [count, encounters]
	if start:
		_body.text += "\n\nStarting a skirmish replaces the current battle. Use Menu → Save battle first if you want to return to it."
	elif state != null:
		_body.text += "\n\nCURRENT PROGRESS\n" + ScenarioBriefing.progress(state)
	var viewport := get_parent().get_viewport().get_visible_rect().size
	_body.custom_minimum_size = Vector2(minf(540, viewport.x * 0.78), minf(310, viewport.y * 0.55))
	popup_centered()
