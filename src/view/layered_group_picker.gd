class_name LayeredGroupPicker
extends RefCounted
## Declare the exact eligible group; the controller owns the two action passes.


static func choose(parent: Control,c: GameController,refresh: Callable) -> void:
	if not c.can_begin_group():
		return
	var s := c.state
	var leader := s.figure(s.early.leaders[s.current_side()])
	var limit := leader.early_limit()
	var ids: Array[int] = [leader.id]
	var dialog := ConfirmationDialog.new()
	dialog.title="Declare group"
	dialog.ok_button_text="Begin group"
	parent.add_child(dialog)
	var col := VBoxContainer.new()
	dialog.add_child(col)
	var label := Label.new()
	label.text="%s leads. Select 1–%d soldiers." % [leader.label(),limit]
	col.add_child(label)
	var detail := Label.new()
	detail.text="All members move before any second actions."
	col.add_child(detail)
	var options: Array[CheckBox] = []
	for f in c.activatable():
		if f==leader or f.spell_effects.has("possess"):
			continue
		var option := CheckBox.new()
		option.text="%s • %s (%.1f in)" % [f.label(),f.surface_id,f.elevation]
		option.set_meta("figure_id",f.id)
		option.custom_minimum_size.y=44
		col.add_child(option)
		options.append(option)
	for option in options:
		option.toggled.connect(func(checked: bool) -> void:
			var id := int(option.get_meta("figure_id"))
			if checked:
				ids.append(id)
			else:
				ids.erase(id)
			for other in options:
				other.disabled=not other.button_pressed and ids.size()>=limit+1
			dialog.get_ok_button().disabled=ids.size()<2)
	dialog.get_ok_button().disabled=true
	dialog.confirmed.connect(func() -> void:
		c.begin_group(ids)
		refresh.call()
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	PhoneSafeArea.popup_dialog(dialog)
