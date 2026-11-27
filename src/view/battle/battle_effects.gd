class_name BattleEffects
extends RefCounted
## Small bounded visual-only effects; no gameplay RNG or collision.


static func burst(root: Node3D, at: Vector3, color: Color) -> void:
	var effect := Node3D.new()
	root.add_child(effect)
	effect.position = at
	var shape := BoxMesh.new()
	shape.size = Vector3(0.07, 0.07, 0.20)
	var mat := BoardView._mat(color, 0.3)
	mat.emission_enabled = true
	mat.emission = color
	var tween := effect.create_tween().set_parallel(true)
	var count := 5 if GraphicsQuality.mode()==0 else 9
	for i in count:
		var dir := Vector3(cos(TAU * i / count), 0.4 + float(i % 3) * 0.25, sin(TAU * i / count))
		var spark := MeshInstance3D.new()
		spark.mesh = shape
		spark.material_override = mat
		effect.add_child(spark)
		spark.look_at_from_position(effect.global_position, effect.global_position + dir)
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tween.tween_property(spark, "position", dir * 0.90, 0.25)
		tween.tween_property(spark, "scale", Vector3.ZERO, 0.30)
	tween.chain().tween_callback(effect.queue_free)


static func pulse(root: Node3D, at: Vector3, color: Color, radius: float = 0.9) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = 0.76
	ring.outer_radius = 0.84
	var node := MeshInstance3D.new()
	node.mesh = ring
	var mat := BoardView._mat(color, 0.3)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	node.material_override = mat
	root.add_child(node)
	node.position = at
	node.scale = Vector3(0.25, 0.12, 0.25)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var t := node.create_tween().set_parallel(true)
	t.tween_property(node, "scale", Vector3(radius, 0.12, radius), 0.55)
	t.tween_property(mat, "albedo_color:a", 0.0, 0.55)
	t.chain().tween_callback(node.queue_free)


static func impact(root: Node3D,at: Vector3,color: Color,damaging: bool,magic: bool=false) -> void:
	if damaging:
		burst(root,at,color)
		if magic:
			pulse(root,at,color.lightened(0.25),1.15)
	else:
		# A muted silver ricochet indicates no damage without inventing a hit.
		burst(root,at,Color("a8bdca"))
		pulse(root,at,Color("b8c7cf"),0.66)


static func clash(root: Node3D,at: Vector3,direction: Vector3,tied: bool) -> void:
	var effect := Node3D.new()
	root.add_child(effect)
	effect.position=at
	var tangent := Vector3(direction.z,0,-direction.x).normalized()
	if tangent.length_squared()<0.01:
		tangent=Vector3.RIGHT
	var tint := Color("e4dfe0") if tied else Color("ffd28a")
	var mat := BoardView._mat(tint,0.3)
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	var shape := BoxMesh.new()
	shape.size=Vector3(0.06,0.06,0.70)
	for i in 3:
		var streak := MeshInstance3D.new()
		streak.mesh=shape
		streak.material_override=mat
		streak.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		effect.add_child(streak)
		var offset := tangent*(i-1)*0.21
		streak.position=offset
		streak.look_at_from_position(at+offset,at+offset+tangent+Vector3.UP*(0.35+i*0.18))
	var t := effect.create_tween().set_parallel(true)
	t.tween_property(effect,"scale",Vector3.ONE*1.55,0.22)
	t.tween_property(mat,"albedo_color:a",0.0,0.30)
	t.chain().tween_callback(effect.queue_free)
	burst(root,at,tint)


static func restore(root: Node3D,at: Vector3) -> void:
	pulse(root,at,Color("70edaa"),1.05)
	var effect := Node3D.new()
	root.add_child(effect)
	effect.position=at
	var mat := BoardView._mat(Color("a6f3c4"),0.25)
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	var tween := effect.create_tween().set_parallel(true)
	for i in (4 if GraphicsQuality.mode()==0 else 7):
		var angle := TAU*i/7.0
		var node := MiniatureFactory.sphere(effect,Vector3(cos(angle)*0.55,0.12,sin(angle)*0.55),Vector3(0.10,0.19,0.10),Color.WHITE)
		node.material_override=mat
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tween.tween_property(node,"position:y",1.85,0.50)
	tween.tween_property(mat,"albedo_color:a",0.0,0.52)
	tween.chain().tween_callback(effect.queue_free)
