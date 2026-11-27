class_name PortalView
extends RefCounted
## Three lightweight meshes per portal, with no dynamic lights or particles.
static func build(root: Node3D,p: TerrainPiece) -> void:
	var at := p.rect.get_center()
	var base := CylinderMesh.new()
	base.top_radius=0.96
	base.bottom_radius=1.0
	base.height=0.18
	base.radial_segments=20
	_mesh(root,base,TableSpace.to_world(at,0.09),Color("333742"),false)
	var ring := TorusMesh.new()
	ring.inner_radius=0.80
	ring.outer_radius=1.08
	ring.rings=24
	ring.ring_segments=8
	var rim := _mesh(root,ring,TableSpace.to_world(at,1.3),Color("ed6448"),true)
	rim.rotation.x=PI*0.5
	var disc := CylinderMesh.new()
	disc.top_radius=0.88
	disc.bottom_radius=0.88
	disc.height=0.07
	disc.radial_segments=24
	var veil := _mesh(root,disc,TableSpace.to_world(at,1.3),Color(0.63,0.18,0.62,0.72),true)
	veil.rotation.x=PI*0.5
	# Ground rim communicates the full gameplay footprint from overhead.
	var footprint := TorusMesh.new()
	footprint.inner_radius=p.rect.size.x*0.5-0.10
	footprint.outer_radius=p.rect.size.x*0.5
	footprint.rings=24
	footprint.ring_segments=5
	_mesh(root,footprint,TableSpace.to_world(at,0.035),Color("f48b55"),true)
	for i in 2:
		var arc := TorusMesh.new()
		arc.inner_radius=0.64-0.16*i
		arc.outer_radius=0.69-0.16*i
		arc.rings=20
		arc.ring_segments=5
		var swirl := _mesh(root,arc,TableSpace.to_world(at,1.3),Color("eab5f2"),true)
		swirl.rotation=Vector3(PI*0.5,0.3+0.5*i,0.4*i)


static func _mesh(root: Node3D,shape: Mesh,at: Vector3,tint: Color,glow: bool) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh=shape
	node.position=at
	var mat := StandardMaterial3D.new()
	mat.albedo_color=tint
	mat.roughness=0.9
	if glow:
		mat.emission_enabled=true
		mat.emission=Color(tint.r,tint.g,tint.b)
		mat.emission_energy_multiplier=0.8
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if tint.a<1.0:
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	node.material_override=mat
	root.add_child(node)
	return node
