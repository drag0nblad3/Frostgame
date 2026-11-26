class_name ModalInput
extends RefCounted
## Track actual visible dialogs (including nested popups), independent of
## gameplay state. Weak references prevent scene changes retaining windows.
static var _windows: Array[WeakRef]=[]


static func register(window: Window) -> void:
	for i in range(_windows.size()-1,-1,-1):
		var other: Variant=_windows[i].get_ref()
		if not is_instance_valid(other) or other==window:
			_windows.remove_at(i)
	_windows.append(weakref(window))


static func top() -> Window:
	for i in range(_windows.size()-1,-1,-1):
		var window := _windows[i].get_ref() as Window
		if not is_instance_valid(window) or not window.is_inside_tree() or window.is_queued_for_deletion():
			_windows.remove_at(i)
			continue
		if window.visible:
			return window
	return null


static func blocked() -> bool:
	return top()!=null


static func _visible_popup(node: Node) -> PopupMenu:
	# Only invoked on Android Back, not on each frame.
	for child in node.get_children(true):
		if child is PopupMenu and child.visible:
			var nested := _visible_popup(child)
			return nested if nested!=null else child
		if child is Window and not child.visible:
			continue
		if child is MeshInstance3D or child is MultiMeshInstance3D or child is SubViewport:
			continue
		var found := _visible_popup(child)
		if found!=null:
			return found
	return null


static func close_top(root: Node) -> bool:
	var window := top()
	var popup := _visible_popup(window if window!=null else root)
	if popup!=null:
		popup.hide()
		return true
	if window!=null:
		# Same cancellation path as X; never emit confirmed or commit edits.
		window.close_requested.emit()
		if is_instance_valid(window) and not window.is_queued_for_deletion():
			window.hide()
		return true
	return false
