class_name LayeredSpellPicker
extends RefCounted
## Inspect the shared spell catalogue, then select an explicit floor-aware target.


static func choose(parent: Control,c: GameController,refresh: Callable) -> void:
	var options := LayeredFigureSpells.options(c)
	if options.is_empty():
		return
	var f := c.state.active()
	if f==null:
		return
	var legal: Array[String]=[]
	legal.assign(options.keys())
	var book := BattleSpellbook.new()
	parent.add_child(book)
	book.chosen.connect(func(key: String) -> void:
		book.queue_free()
		_targets(parent,c,refresh,key.trim_prefix("spell_"),options))
	book.cancelled.connect(book.queue_free)
	book.open(f.label(),SpellReference.battle_entries(c.state,f,legal))


static func _targets(parent: Control,c: GameController,refresh: Callable,id: String,options: Dictionary) -> void:
	if not options.has(id):
		return
	var dialog := ConfirmationDialog.new()
	var spell := "enchant_weapon" if id=="enchant_ammo" else id
	var info: Dictionary=c.state.spell_catalog[spell]
	dialog.title=str(info["name"])+" · Choose target"
	dialog.ok_button_text="Roll casting"
	parent.add_child(dialog)
	var col := VBoxContainer.new()
	dialog.add_child(col)
	var description := WorkshopUI.label(col,str(SpellReference.entry(spell).get("effect","")),24)
	description.custom_minimum_size.x=360
	var targets := OptionButton.new()
	targets.custom_minimum_size.y=60
	targets.fit_to_longest_item=false
	col.add_child(targets)
	for figure_id: int in options[id]:
		var f := c.state.figure(figure_id)
		targets.add_item("%s #%d • %s • %.1f in"%[f.label(),f.id,f.surface_id,f.elevation])
		targets.set_item_metadata(targets.item_count-1,f.id)
	targets.select(0)
	dialog.confirmed.connect(func() -> void:
		c.start_cast(spell,int(targets.get_selected_metadata()),id=="enchant_ammo")
		refresh.call()
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	PhoneSafeArea.popup_dialog(dialog)
