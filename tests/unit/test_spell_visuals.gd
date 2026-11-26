extends TestCase


func test_projectile_variants_have_geometry() -> void:
	var s := GameState.new()
	for id: String in ["elemental_bolt","elemental_ball","bone_dart","poison_dart","scatter_shot",""]:
		var color := SpellVisuals.color_for(id,s)
		var p := SpellVisuals.projectile(id,not id.is_empty(),color)
		check(p.get_child_count()>1)
		p.free()
	check(SpellVisuals.color_for("poison_dart",s) != SpellVisuals.color_for("bone_dart",s))
