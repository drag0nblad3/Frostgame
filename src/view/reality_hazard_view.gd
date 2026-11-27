class_name RealityHazardView
extends RefCounted
## Distinct, low-cost hazard geometry. Ground rings show exact rule footprints.

static func hoof(root: Node3D,p: TerrainPiece,b: Board) -> void:
	var at := p.rect.get_center()
	var h := b.ground_height_at(at)
	var r := p.rect.size.x*0.5
	var origin := TableSpace.to_world(at,h)
	var charred := Color("252026")
	var stone := Color("52353a")
	var ember := Color("ff9855")
	var base := CylinderMesh.new()
	base.top_radius=r
	base.bottom_radius=r
	base.height=0.14
	base.radial_segments=20
	_add(root,base,origin+Vector3.UP*0.07,charred)
	_ring(root,origin+Vector3.UP*0.16,r,ember)
	# Two massive, split toes with an upright scorched fetlock.
	for side: float in [-1.0,1.0]:
		var toe := MiniatureFactory.sphere(root,origin+Vector3(side*r*0.31,r*0.57,-r*0.12),Vector3(r*0.68,r*1.10,r*1.38),stone)
		toe.rotation.z=side*0.13
		toe.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var hoof_edge := MiniatureFactory.box(root,origin+Vector3(side*r*0.31,r*0.21,-r*0.32),Vector3(r*0.55,r*0.22,r*0.77),charred)
		hoof_edge.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var leg := CylinderMesh.new()
	leg.top_radius=r*0.52
	leg.bottom_radius=r*0.56
	leg.height=r*1.15
	leg.radial_segments=8
	_add(root,leg,origin+Vector3.UP*r*1.43,stone)
	# Small radial warning slashes remain within the circular footprint.
	for i in 8:
		var angle := TAU*float(i)/8.0
		var slash := BoxMesh.new()
		slash.size=Vector3(r*0.10,0.025,r*0.22)
		var mark := _add(root,slash,origin+Vector3(sin(angle)*r*0.83,0.16,cos(angle)*r*0.83),ember,true)
		mark.rotation.y=angle


static func worm(root: Node3D,p: TerrainPiece,b: Board) -> void:
	var at := p.rect.get_center()
	var origin := TableSpace.to_world(at,b.ground_height_at(at)+0.04)
	var r := p.rect.size.x*0.5
	_ring(root,origin,r,Color("d4b35f"))
	for i in 3:
		var mark := BoxMesh.new()
		mark.size=Vector3(r*0.18,0.025,r*1.05)
		var node := _add(root,mark,origin+Vector3.UP*0.02,Color("d4b35f"),true)
		node.rotation.y=TAU*float(i)/3.0


static func _ring(root: Node3D,at: Vector3,radius: float,color: Color) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius=radius*0.87
	ring.outer_radius=radius
	ring.rings=24
	ring.ring_segments=5
	_add(root,ring,at,color,true)


static func _add(root: Node3D,shape: Mesh,at: Vector3,color: Color,glow: bool=false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh=shape
	node.position=at
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=0.95
	if glow:
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	node.material_override=material
	root.add_child(node)
	return node
