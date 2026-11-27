class_name ExpansionDialog
extends AcceptDialog
## Per-slot book selection, applied on explicit confirmation.
signal changed
var _slot := 0
var _checks := {}
var _rows: VBoxContainer
var _scroll: ScrollContainer
var _status: Label


func _ready() -> void:
	theme=BattleTheme.create()
	dialog_hide_on_ok=false
	get_ok_button().text="Apply to save"
	add_cancel_button("Cancel")
	var col := VBoxContainer.new()
	add_child(col)
	var intro := Label.new()
	intro.text="Choose which rulebooks contribute content to this save. Core rules are always enabled."
	intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	col.add_child(intro)
	_scroll=ScrollContainer.new()
	_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_scroll)
	_rows=VBoxContainer.new()
	_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_scroll.add_child(_rows)
	_status=Label.new()
	_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_status)
	confirmed.connect(_apply)


func open(slot: int) -> void:
	_slot=slot
	title="Rulebook content · Save %d"%(slot+1)
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_checks.clear()
	var profile := WarbandSlots.content_profile(slot)
	var core := CheckBox.new()
	core.text="Frostgrave Second Edition · Core"
	core.button_pressed=true
	core.disabled=true
	core.custom_minimum_size.y=52
	_rows.add_child(core)
	for id: String in profile.packs:
		var pack: Dictionary=profile.packs[id]
		var check := CheckBox.new()
		check.text=str(pack.get("name",id))
		check.button_pressed=profile.enabled.has(id)
		check.disabled=not ContentProfile.playable(pack)
		if check.disabled:
			check.text+=" · In development"
		elif pack.get("status","ready")=="playtest":
			check.text+=" · Playtest"
		check.custom_minimum_size.y=52
		_rows.add_child(check)
		_checks[id]=check
		var detail := Label.new()
		detail.text=str(pack.get("description","Optional expansion content."))
		detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		_rows.add_child(detail)
		if id=="red_king" and ContentProfile.playable(pack):
			var hint := Label.new()
			hint.text="After applying: open Campaign, then choose Start The Red King storyline on a new campaign save. Individual encounters also appear under Skirmish."
			hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			_rows.add_child(hint)
	if _checks.is_empty():
		var empty := Label.new()
		empty.text="No expansion books are registered yet. New books will appear here when their digital content is installed."
		empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		_rows.add_child(empty)
	_status.modulate=Color.WHITE
	_status.text="Changes do not delete your roster or campaign. A saved battle requires its original selection to resume."
	var bounds := PhoneSafeArea.safe_rect(get_parent().get_viewport(),14).size
	_scroll.custom_minimum_size=Vector2(minf(660,bounds.x*0.8),minf(280,bounds.y*0.40))
	PhoneSafeArea.popup_dialog(self)


func _apply() -> void:
	var enabled: Array[String]=[]
	for id: String in _checks:
		if _checks[id].button_pressed:
			enabled.append(id)
	var errors := WarbandSlots.change_content(enabled,_slot)
	if not errors.is_empty():
		_status.text="\n".join(errors)
		_status.modulate=Color("e3ae8d")
		return
	changed.emit()
	hide()
