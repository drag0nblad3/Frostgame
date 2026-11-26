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
		var pose := child.transform
		root.remove_child(child)
		pivot.add_child(child)
		child.transform = _relative(root,pivot).affine_inverse()*pose


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


## Nested joints are authored in root-local coordinates, before entering the tree.
static func joint(root: Node3D,parent: Node3D,label: String,at: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.name=label
	pivot.position=_relative(root,parent).affine_inverse()*at
	parent.add_child(pivot)
	return pivot


static func _relative(root: Node3D,node: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var current := node
	while current!=root:
		result=current.transform*result
		current=current.get_parent() as Node3D
	return result


static func hand_parent(arm: Node3D) -> Node3D:
	if arm==null:
		return null
	var elbow := arm.get_node_or_null("Elbow") as Node3D
	return elbow if elbow!=null else arm


static func bend_arms(root: Node3D,right: float,left: float) -> void:
	for side in [false,true]:
		var path := "RightArm/Elbow" if side else "LeftArm/Elbow"
		var elbow := root.get_node_or_null(path) as Node3D
		if elbow!=null:
			elbow.rotation.x=right if side else left


static func bend_leg(root: Node3D,index: int,angle: float) -> void:
	var knee := root.get_node_or_null("Leg%d/Knee"%index) as Node3D
	if knee!=null:
		knee.rotation.x=angle
