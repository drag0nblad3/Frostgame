class_name SpellVisuals
extends RefCounted
## Read-only presentation based on the actual spell and resolved origin.

const COLORS := {
	"elemental_bolt": Color(0.35,0.79,1.0),
	"elemental_ball": Color(1.0,0.51,0.19),
	"bone_dart": Color(0.92,0.88,0.67),
	"poison_dart": Color(0.52,0.90,0.24),
	"scatter_shot": Color(0.90,0.79,0.52),
	"fire_breath": Color(1.0,0.45,0.15),
	"heal": Color(0.50,0.98,0.60)
}


static func color_for(spell: String, state: GameState) -> Color:
	if COLORS.has(spell):
		return COLORS[spell]
	var info: Dictionary = state.spell_catalog.get(spell,{})
	return SchoolArt.glow(str(info.get("school","")))


static func projectile(spell: String, magic: bool, color: Color) -> Node3D:
	var root := Node3D.new()
	var orb := spell in ["elemental_bolt","elemental_ball","fire_breath"] or (magic and spell.is_empty())
	if orb:
		var size := 0.32 if spell == "elemental_ball" else 0.18
		_shine(MiniatureFactory.sphere(root,Vector3.ZERO,Vector3.ONE*size,color),color)
		for i in 4:
			var angle := TAU*i/4.0
			var a := Vector3(cos(angle)*size*0.40,sin(angle)*size*0.40,0.03)
			_shine(CreatureSculpt.limb(root,a,a+Vector3(0,0,0.36+0.09*i),size*0.19,color,0.08),color)
	else:
		var shaft := Color(0.52,0.36,0.21) if not magic else color
		CreatureSculpt.limb(root,Vector3(0,0,0.37),Vector3(0,0,-0.10),0.025,shaft,1.0)
		var tip := CreatureSculpt.limb(root,Vector3(0,0,-0.09),Vector3(0,0,-0.26),0.065,color,0.0)
		if magic:
			_shine(tip,color)
		for i in 3:
			var a := TAU*i/3.0
			var fin := MiniatureFactory.box(root,Vector3(cos(a)*0.034,sin(a)*0.034,0.30),Vector3(0.04,0.095,0.13),color)
			fin.rotation.z = a
	return root


static func _shine(m: MeshInstance3D,color: Color) -> void:
	var mat: StandardMaterial3D = m.material_override
	mat.emission_enabled = true
	mat.emission = color*0.8
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func sigil(root: Node3D, at: Vector3, color: Color, radius: float = 1.0) -> void:
	var node := Node3D.new()
	root.add_child(node)
	node.position = at
	var ring := TorusMesh.new()
	ring.inner_radius = 0.80
	ring.outer_radius = 0.84
	ring.rings = 28
	ring.ring_segments = 5
	var mat := BoardView._mat(color,0.3)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color*0.6
	for r: float in [1.0,0.75]:
		var m := MeshInstance3D.new()
		m.mesh = ring
		m.scale = Vector3(r,0.12,r)
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(m)
	var glyph := BoxMesh.new()
	glyph.size = Vector3(0.07,0.018,0.16)
	for i in 8:
		var angle := TAU*i/8.0
		var m := MeshInstance3D.new()
		m.mesh = glyph
		m.material_override = mat
		m.position = Vector3(cos(angle)*0.72,0.01,sin(angle)*0.72)
		m.rotation.y = -angle+PI*0.25
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(m)
	node.scale = Vector3(0.55,1,0.55)
	var t := node.create_tween().set_parallel(true)
	t.tween_property(node,"scale",Vector3(radius,1,radius),0.55)
	t.tween_property(node,"rotation:y",PI*0.3,0.65)
	t.tween_property(mat,"albedo_color:a",0.0,0.70).set_delay(0.15)
	t.chain().tween_callback(node.queue_free)
