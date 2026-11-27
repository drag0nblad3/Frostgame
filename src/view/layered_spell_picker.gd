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
	var detail := RichTextLabel.new()
	detail.custom_minimum_size=Vector2(400,180)
	detail.size_flags_vertical=Control.SIZE_EXPAND_FILL
	detail.add_theme_font_size_override("normal_font_size",23)
	col.add_child(detail)
	for id: String in options:
		spells.add_item(id.replace("_"," ").capitalize())
		spells.set_item_metadata(spells.item_count-1,id)
	var populate := func(index: int) -> void:
		targets.clear()
		var id: String = spells.get_item_metadata(index)
		var spell_id := "enchant_weapon" if id=="enchant_ammo" else id
		var spec: Dictionary=c.state.spell_catalog[spell_id]
		var f := c.state.active()
		var tn := int(c.state.spellbooks.get(f.side,{}).get(spell_id,spec["number"]))
		detail.text=ActionArt.spell_details(spec,tn)+"\n\n"+SpellReference.describe(spell_id)
		for figure_id: int in options[id]:
			var f := c.state.figure(figure_id)
			targets.add_item("%s #%d • %s • %.1f in" % [f.label(),f.id,f.surface_id,f.elevation])
			targets.set_item_metadata(targets.item_count-1,f.id)
		targets.select(0)
	spells.item_selected.connect(populate)
	spells.select(0)
	populate.call(0)
	dialog.confirmed.connect(func() -> void:
		var id := str(spells.get_selected_metadata())
		c.start_cast("enchant_weapon" if id=="enchant_ammo" else id,int(targets.get_selected_metadata()),id=="enchant_ammo")
		refresh.call()
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	PhoneSafeArea.popup_dialog(dialog)
