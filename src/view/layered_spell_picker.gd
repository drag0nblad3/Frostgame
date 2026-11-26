class_name LayeredSpellPicker
extends RefCounted
## Named figure targets preserve floor identity even when their projections overlap.


static func choose(parent: Control,c: GameController,refresh: Callable) -> void:
	var options := LayeredFigureSpells.options(c)
	if options.is_empty():
		return
	var dialog := ConfirmationDialog.new()
	dialog.title="Cast spell"
	dialog.ok_button_text="Roll casting"
	parent.add_child(dialog)
	var col := VBoxContainer.new()
	dialog.add_child(col)
	var spells := OptionButton.new()
	var targets := OptionButton.new()
	spells.custom_minimum_size.y=44
	targets.custom_minimum_size.y=44
	col.add_child(spells)
	col.add_child(targets)
	for id: String in options:
		spells.add_item(id.replace("_"," ").capitalize())
		spells.set_item_metadata(spells.item_count-1,id)
	var populate := func(index: int) -> void:
		targets.clear()
		var id: String = spells.get_item_metadata(index)
		for figure_id: int in options[id]:
			var f := c.state.figure(figure_id)
			targets.add_item("%s #%d • %s • %.1f in" % [f.label(),f.id,f.surface_id,f.elevation])
			targets.set_item_metadata(targets.item_count-1,f.id)
		targets.select(0)
	spells.item_selected.connect(populate)
	spells.select(0)
	populate.call(0)
	dialog.confirmed.connect(func() -> void:
		c.start_cast(str(spells.get_selected_metadata()),int(targets.get_selected_metadata()))
		refresh.call()
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()
