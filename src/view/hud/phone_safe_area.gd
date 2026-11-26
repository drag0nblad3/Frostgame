class_name PhoneSafeArea
extends MarginContainer
## UI margins in logical viewport coordinates, including display cutouts and system bars.
var padding := 10
var _elapsed := 0.0


func _ready() -> void:
	get_viewport().size_changed.connect(refresh)
	refresh()
	call_deferred("refresh")
	set_process(OS.has_feature("mobile"))


func _process(delta: float) -> void:
	_elapsed+=delta
	if _elapsed>=0.5:
		_elapsed=0.0
		refresh()


func refresh() -> void:
	if not is_inside_tree() or get_viewport()==null:
		return
	var bounds := safe_rect(get_viewport(),padding)
	var viewport := get_viewport().get_visible_rect().size
	var margins := Vector4(bounds.position.x,bounds.position.y,viewport.x-bounds.end.x,viewport.y-bounds.end.y)
	for i in 4:
		var edge: String=["left","top","right","bottom"][i]
		var value := ceili(margins[i])
		if get_theme_constant("margin_"+edge)!=value:
			add_theme_constant_override("margin_"+edge,value)


static func logical_rect(logical: Vector2,physical: Rect2,safe: Rect2,pad: float=0.0) -> Rect2:
	if physical.size.x<=0 or physical.size.y<=0:
		return Rect2(Vector2.ONE*pad,logical-Vector2.ONE*pad*2)
	var intersection := physical.intersection(safe)
	if intersection.size.x<=0 or intersection.size.y<=0:
		intersection=physical
	var ratio := logical/physical.size
	var pos := (intersection.position-physical.position)*ratio
	var extent := intersection.size*ratio
	return Rect2(pos+Vector2.ONE*pad,(extent-Vector2.ONE*pad*2).max(Vector2.ONE))


static func safe_rect(viewport: Viewport,pad: float=10.0) -> Rect2:
	var logical := viewport.get_visible_rect().size
	if not OS.has_feature("mobile"):
		return Rect2(Vector2.ONE*pad,(logical-Vector2.ONE*pad*2).max(Vector2.ONE))
	var physical := Rect2(Vector2(DisplayServer.window_get_position()),Vector2(DisplayServer.window_get_size()))
	var safe := Rect2(DisplayServer.get_display_safe_area())
	return logical_rect(logical,physical,safe,pad)


static func popup_dialog(dialog: Window,desired: Vector2=Vector2.ZERO) -> void:
	# Exclusive embedded window: Godot blocks interaction with the parent
	# window only when transient is also set.
	dialog.transient=true
	dialog.exclusive=true
	dialog.unresizable=true
	if dialog.theme==null:
		dialog.theme=BattleTheme.create()
	if dialog is AcceptDialog:
		dialog.get_ok_button().custom_minimum_size.y=56
		if dialog is ConfirmationDialog:
			dialog.get_cancel_button().custom_minimum_size.y=56
	ModalInput.register(dialog)
	var viewport := dialog.get_parent().get_viewport()
	var bounds := safe_rect(viewport,14)
	# Use the safe center even when a cutout is asymmetric. Contents use
	# bounded scroll containers; their minimum size must fit this rectangle.
	var requested := desired if desired!=Vector2.ZERO else Vector2(dialog.get_contents_minimum_size())
	var target := requested.max(Vector2(dialog.get_contents_minimum_size())).min(bounds.size)
	dialog.popup(Rect2i(Vector2i(bounds.get_center()-target*0.5),Vector2i(target)))
