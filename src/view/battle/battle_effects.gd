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
	for i in 6:
		var dir := Vector3(cos(TAU * i / 6.0), 0.4 + float(i % 3) * 0.25, sin(TAU * i / 6.0))
		var spark := MeshInstance3D.new()
		spark.mesh = shape
		spark.material_override = mat
		effect.add_child(spark)
		spark.look_at_from_position(effect.global_position, effect.global_position + dir)
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tween.tween_property(spark, "position", dir * 0.60, 0.25)
		tween.tween_property(spark, "scale", Vector3.ZERO, 0.30)
	tween.chain().tween_callback(effect.queue_free)
