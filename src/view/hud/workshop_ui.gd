class_name WorkshopUI
extends RefCounted
## Shared typography and compact controls for the warband workshop.
const GOLD := Color("e5c58a")
const PAPER := Color("e6edf0")
const MUTED := Color("b9ccd6")


static func label(parent: Node,value: String,font: int=25,color: Color=PAPER) -> Label:
	var l := Label.new()
	l.text=value
	l.add_theme_font_size_override("font_size",font)
	l.add_theme_color_override("font_color",color)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l


static func button(parent: Node,value: String,action: Callable,primary: bool=false) -> Button:
	var b := Button.new()
	b.text=value
	b.custom_minimum_size.y=64
	b.add_theme_font_size_override("font_size",25)
	b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	if primary:
		b.add_theme_stylebox_override("normal",BattleTheme.panel(Color("305664"),GOLD))
	parent.add_child(b)
	b.pressed.connect(action)
	return b


static func column(parent: Node) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	col.size_flags_vertical=Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation",8)
	parent.add_child(col)
	return col


static func scroll(parent: Node) -> VBoxContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	s.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	s.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	s.size_flags_vertical=Control.SIZE_EXPAND_FILL
	parent.add_child(s)
	return column(s)


static func clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


static func stats(parent: Node,d: FigureDef) -> void:
	var grid := GridContainer.new()
	grid.columns=3
	grid.add_theme_constant_override("h_separation",5)
	grid.add_theme_constant_override("v_separation",5)
	parent.add_child(grid)
	var names := ["MOVE","FIGHT","SHOOT","ARMOUR","WILL","HEALTH"]
	var values := ["%d″"%d.move,"%+d"%d.fight,"%+d"%d.shoot,str(d.armour),"%+d"%d.will,str(d.health)]
	for i in names.size():
		var card := PanelContainer.new()
		card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel",BattleTheme.panel(Color("203441"),Color("47616f")))
		grid.add_child(card)
		var col := column(card)
		col.add_theme_constant_override("separation",0)
		label(col,names[i],18,MUTED).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		label(col,values[i],37,GOLD).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER


static func figure(draft: WarbandDraft,slot: int) -> Figure:
	var id := "wizard" if slot==0 else ("apprentice" if slot==1 else draft.soldiers[slot-2])
	var d := draft.db.get_def(id)
	if slot<2:
		d=CasterLoadout.definition(d,draft.wizard_weapons if slot==0 else draft.apprentice_weapons,draft.db)
	return Figure.new(slot,d,0,Vector2.ZERO,draft.db.unarmed())
