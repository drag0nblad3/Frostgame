class_name ExpeditionHome
extends Control
## Scenic home with a live city backdrop and a separate expedition command area.
signal requested(key: String)
signal slot_selected(slot: int)

var buttons := {}
var slots: OptionButton
var notice: Label
var roster_name: Label
var roster_info: Label
var content: Label
var _layout: BoxContainer
var _hero: VBoxContainer
var _commands: VBoxContainer
var _title: Label
var _support: GridContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme=BattleTheme.create()
	var shade := ColorRect.new()
	shade.color=Color(0.025,0.045,0.075,0.16)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var safe := PhoneSafeArea.new()
	safe.padding=8
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe)
	_layout=BoxContainer.new()
	_layout.add_theme_constant_override("separation",12)
	safe.add_child(_layout)
	_hero=WorkshopUI.column(_layout)
	_hero.size_flags_stretch_ratio=1.0
	var mast := _panel(_hero,Color(0.035,0.065,0.095,0.84))
	WorkshopUI.label(mast,"A WIZARD'S EXPEDITION",22,WorkshopUI.GOLD)
	_title=WorkshopUI.label(mast,"FROSTGAME",58,WorkshopUI.PAPER)
	WorkshopUI.label(mast,"Rival warbands · Frozen ruins",23,WorkshopUI.MUTED)
	var view := Control.new()
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	view.size_flags_vertical=Control.SIZE_EXPAND_FILL
	view.custom_minimum_size.y=100
	_hero.add_child(view)
	var card := _panel(_hero,Color(0.035,0.065,0.095,0.94))
	WorkshopUI.label(card,"ACTIVE EXPEDITION",17,WorkshopUI.GOLD)
	roster_name=WorkshopUI.label(card,"",32)
	roster_info=WorkshopUI.label(card,"",22,WorkshopUI.MUTED)
	slots=OptionButton.new()
	slots.fit_to_longest_item=false
	slots.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	slots.custom_minimum_size.y=62
	slots.add_theme_font_size_override("font_size",23)
	card.add_child(slots)
	slots.item_selected.connect(func(i: int) -> void: slot_selected.emit(i))
	_button(card,"warband","Create warband",true)
	var surface := _panel(_layout,Color(0.035,0.065,0.095,0.95))
	surface.get_parent().size_flags_stretch_ratio=1.22
	surface.get_parent().size_flags_vertical=Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	surface.add_child(scroll)
	_commands=WorkshopUI.column(scroll)
	WorkshopUI.label(_commands,"CHOOSE YOUR EXPEDITION",24,WorkshopUI.GOLD)
	_button(_commands,"resume","Resume saved battle",true)
	_mode("campaign","Campaign","Build a lasting warband, recover treasure, gain levels and establish a base.")
	_mode("skirmish","Skirmish","Choose a battlefield and play a standalone battle without campaign progression.")
	_support=GridContainer.new()
	_support.columns=2
	_commands.add_child(_support)
	_button(_support,"training","Training yard")
	_button(_support,"guide","Field guide")
	_button(_support,"expansions","Rulebook content")
	_button(_support,"graphics","Graphics quality")
	notice=WorkshopUI.label(_commands,"",19,Color("edb19a"))
	notice.visible=false
	content=WorkshopUI.label(_commands,"",19,WorkshopUI.MUTED)
	resized.connect(_reflow)
	_reflow()


func _panel(parent: Node,color: Color) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",BattleTheme.panel(color,Color("60717b"),4))
	parent.add_child(panel)
	return WorkshopUI.column(panel)


func _button(parent: Node,key: String,value: String,primary: bool=false) -> Button:
	var b := WorkshopUI.button(parent,value,func() -> void: requested.emit(key),primary)
	b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	buttons[key]=b
	return b


func _mode(key: String,title_text: String,detail: String) -> void:
	var card := _panel(_commands,Color("203441"))
	var b := _button(card,key,title_text+"  ›",true)
	b.custom_minimum_size.y=74
	b.add_theme_font_size_override("font_size",32)
	WorkshopUI.label(card,detail,23,WorkshopUI.MUTED)


func _reflow() -> void:
	var narrow := size.x<size.y
	_layout.vertical=narrow
	_title.add_theme_font_size_override("font_size",44 if narrow else 58)
	_hero.size_flags_stretch_ratio=0.8 if narrow else 1.0
	_support.columns=2
