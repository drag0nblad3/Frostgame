class_name TetherView
extends RefCounted
## A faceted stone anchor and luminous floating core.
static func build() -> Node3D:
	var root := Node3D.new()
	var stone := StandardMaterial3D.new()
	stone.albedo_color=Color(0.22,0.24,0.32)
	var base := CylinderMesh.new()
	base.top_radius=0.34
	base.bottom_radius=0.48
	base.height=0.4
	base.radial_segments=6
	_add(root,base,0.2,stone)
	var shaft := CylinderMesh.new()
	shaft.top_radius=0.28
	shaft.bottom_radius=0.36
	shaft.height=1.8
	shaft.radial_segments=5
	_add(root,shaft,1.2,stone)
	var crystal := SphereMesh.new()
	crystal.radius=0.38
	crystal.height=0.95
	crystal.radial_segments=6
	crystal.rings=3
	var glow := StandardMaterial3D.new()
	glow.albedo_color=Color(0.56,0.79,1.0)
	glow.emission_enabled=true
	glow.emission=Color(0.3,0.55,0.9)
	_add(root,crystal,2.3,glow)
	return root


static func _add(root: Node3D,mesh: Mesh,y: float,mat: Material) -> void:
	var node := MeshInstance3D.new()
	node.mesh=mesh
	node.position.y=y
	node.material_override=mat
	root.add_child(node)
