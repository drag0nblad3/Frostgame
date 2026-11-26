class_name MiniaturePose
extends RefCounted
## Shoulder pivots preserve the original sculpture while allowing articulated poses.


static func arm(root: Node3D, right: bool) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "RightArm" if right else "LeftArm"
	pivot.position = Vector3(0.258 if right else -0.258, 1.12, 0)
	root.add_child(pivot)
	return pivot


static func attach(root: Node3D, pivot: Node3D, first: int) -> void:
	var children := root.get_children().slice(first)
	for child in children:
		if not child is MeshInstance3D:
			continue
		var pos: Vector3 = child.position
		root.remove_child(child)
		pivot.add_child(child)
		child.position = pos - pivot.position


static func arms(root: Node3D, right: float, left: float) -> void:
	var r := root.get_node_or_null("RightArm") as Node3D
	var l := root.get_node_or_null("LeftArm") as Node3D
	if r != null:
		r.rotation.x = right
	if l != null:
		l.rotation.x = left


static func leg(root: Node3D,index: int,at: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.name="Leg%d" % index
	pivot.position=at
	root.add_child(pivot)
	return pivot


static func legs(root: Node3D,angles: Array[float]) -> void:
	for i in angles.size():
		var pivot := root.get_node_or_null("Leg%d" % i) as Node3D
		if pivot!=null:
			pivot.rotation.x=angles[i]
