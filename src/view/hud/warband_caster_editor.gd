class_name WarbandCasterEditor
extends RefCounted
## Individual weapon switches rather than a long preset dropdown.


static func build(inspector: WarbandInspector,parent: VBoxContainer) -> void:
	var draft := inspector.draft
	var wizard := inspector.slot==0
	if wizard:
		var name := LineEdit.new()
		name.text=draft.wizard_name
		name.placeholder_text="Name your wizard"
		name.custom_minimum_size.y=54
		name.add_theme_font_size_override("font_size",23)
		parent.add_child(name)
		name.text_changed.connect(func(value: String) -> void:
			draft.wizard_name=value
			inspector._title.text=value
			inspector.changed.emit())
		WorkshopUI.label(parent,WarbandAdvice.school(draft),21)
	else:
		WorkshopUI.label(parent,"Second caster · 100 gc. Uses the wizard's spellbook at +2 casting difficulty.",22)
		var hire := WorkshopUI.button(parent,"Dismiss apprentice" if draft.apprentice else "Hire apprentice · 100 gc",func() -> void:
			draft.apprentice=not draft.apprentice
			inspector.changed.emit()
			inspector._refresh_detail(),true)
		hire.disabled=not draft.apprentice and draft.cost()+draft.db.get_def("apprentice").cost>WarbandDraft.BUDGET
		if not draft.apprentice:
			return
	var weapons: Array=draft.wizard_weapons if wizard else draft.apprentice_weapons
	var limit := 5 if wizard else 4
	WorkshopUI.label(parent,"EQUIPMENT · %d/%d SLOTS"%[CasterLoadout.weapon_slots(weapons),limit],18,WorkshopUI.GOLD)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation",8)
	parent.add_child(flow)
	for id in ["staff","hand_weapon","two_handed","bow","crossbow"]:
		if not draft.db.content_profile.allows("weapons",id):
			continue
		var weapon: WeaponDef=draft.db.weapons[id]
		var b := CheckBox.new()
		b.text=weapon.name
		b.button_pressed=weapons.has(id)
		b.custom_minimum_size.y=46
		b.add_theme_font_size_override("font_size",21)
		var proposed := weapons.duplicate()
		if not proposed.has(id):
			proposed.append(id)
		b.disabled=not weapons.has(id) and (not CasterLoadout.valid(proposed) or CasterLoadout.weapon_slots(proposed)>limit)
		flow.add_child(b)
		b.toggled.connect(_toggle.bind(inspector,id))
	var def := WorkshopUI.figure(draft,inspector.slot).def
	WorkshopUI.label(parent,WarbandAdvice.loadout(def),20,WorkshopUI.MUTED)
	WorkshopUI.button(parent,"Edit shared spellbook ›",func() -> void: inspector.spells.emit())


static func _toggle(on: bool,inspector: WarbandInspector,id: String) -> void:
	var draft := inspector.draft
	var weapons: Array=draft.wizard_weapons if inspector.slot==0 else draft.apprentice_weapons
	var proposed := weapons.duplicate()
	if on:
		proposed.append(id)
	else:
		proposed.erase(id)
	if not proposed.has("dagger"):
		proposed.append("dagger")
	if not CasterLoadout.valid(proposed) or CasterLoadout.weapon_slots(proposed)>(5 if inspector.slot==0 else 4):
		return
	if inspector.slot==0:
		draft.wizard_weapons=proposed
	else:
		draft.apprentice_weapons=proposed
	inspector.changed.emit()
	inspector._refresh_detail()
