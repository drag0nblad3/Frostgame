class_name SinkholeView
extends RefCounted
## Compact dark sphere with thin violet accretion rings; no dynamic lights.
static func build(root: Node3D,p: TerrainPiece) -> void:
	var center := TableSpace.to_world(p.rect.get_center(),1.5)
	var orb := SphereMesh.new()
	orb.radius=1.5
	orb.height=3.0
	orb.radial_segments=32
	orb.rings=16
	var black := StandardMaterial3D.new()
	black.albedo_color=Color(0.009,0.006,0.025)
	black.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	_add(root,orb,center,black)
	for i in 3:
		var ring := TorusMesh.new()
		ring.inner_radius=1.51+0.12*i
		ring.outer_radius=1.55+0.12*i
		ring.rings=32
		ring.ring_segments=6
		var mat := StandardMaterial3D.new()
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color=Color(0.49,0.19,0.84).lerp(Color(0.12,0.07,0.33),float(i)/3.0)
		var rim := _add(root,ring,center,mat)
		rim.rotation=Vector3(0.38+i*0.2,i*0.7,0.45-i*0.17)


static func _add(root: Node3D,mesh: Mesh,at: Vector3,mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh=mesh
	node.position=at
	node.material_override=mat
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(node)
	return node
