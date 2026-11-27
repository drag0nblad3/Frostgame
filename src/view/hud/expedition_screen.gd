class_name ExpeditionScreen
extends Window
## Full safe-area launch screen; input stays modal and Back cancels without writes.

var body: VBoxContainer
var heading: Label
var action: Button
var subtitle: Label


func _init() -> void:
	visible=false
	borderless=true
	unresizable=true
	transient=true
	exclusive=true


func build(title_text: String, action_text: String, run: Callable) -> void:
	theme=BattleTheme.create()
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel",BattleTheme.panel(Color("101d29"),Color("51636d"),0))
	add_child(panel)
	var col := WorkshopUI.column(panel)
	var top := HBoxContainer.new()
	col.add_child(top)
	WorkshopUI.button(top,"‹ Back",navigate_back)
	heading=WorkshopUI.label(top,title_text,30,WorkshopUI.GOLD)
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	subtitle=WorkshopUI.label(col,"",23,WorkshopUI.MUTED)
	body=WorkshopUI.column(col)
	action=WorkshopUI.button(col,action_text,run,true)
	action.custom_minimum_size.y=72
	close_requested.connect(navigate_back)
	get_parent().get_viewport().size_changed.connect(_fit)
	size_changed.connect(_reflow)


func show_screen() -> void:
	ModalInput.register(self)
	var bounds := PhoneSafeArea.safe_rect(get_parent().get_viewport(),4)
	popup(Rect2i(Vector2i(bounds.position),Vector2i(bounds.size)))
	_reflow()


func _fit() -> void:
	if visible:
		var bounds := PhoneSafeArea.safe_rect(get_parent().get_viewport(),4)
		position=Vector2i(bounds.position)
		size=Vector2i(bounds.size)


func _reflow() -> void:
	pass


func navigate_back() -> void:
	hide()
