extends TestCase


func test_projectile_variants_have_geometry() -> void:
	var s := GameState.new()
	for id: String in ["elemental_bolt","elemental_ball","bone_dart","poison_dart","scatter_shot",""]:
		var color := SpellVisuals.color_for(id,s)
		var p := SpellVisuals.projectile(id,not id.is_empty(),color)
		check(p.get_child_count()>1)
		p.free()
	check(SpellVisuals.color_for("poison_dart",s) != SpellVisuals.color_for("bone_dart",s))


func test_facade_variants_follow_terrain_and_site() -> void:
	var kind := TerrainKind.new()
	kind.id="ruin"
	var p := TerrainPiece.new(kind,Rect2(0,0,3,3))
	check_eq(RuinedFacade.style(p,"complex_temple"),1)
	check_eq(RuinedFacade.style(p,"haunted_houses"),2)
	check_eq(RuinedFacade.style(p,"silent_tower"),3)
	check_eq(RuinedFacade.style(p,"treasure_skirmish"),0)


func test_school_motifs_distinct_and_bounded() -> void:
	var seen: Dictionary={}
	for school: String in CombatVfx.SCHOOLS:
		var kind:=CombatVfx.motif("",school)
		seen[kind]=true
		var node:=CombatVfx.motif_geometry(kind,Color.WHITE)
		check(node.get_child_count()>1 and node.get_child_count()<=25,school)
		for child in node.get_children():
			check(child is MeshInstance3D and child.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,school)
		node.free()
	check_eq(seen.size(),10)
	check_eq(CombatVfx.motif("elemental_shield","elementalist"),"ward")
	check_eq(CombatVfx.motif("teleport","illusionist"),"portal")


func test_weapon_trails_have_distinct_geometry() -> void:
	var light:=CombatVfx.weapon_arc("dagger")
	var heavy:=CombatVfx.weapon_arc("two_handed")
	check_eq(light.get_surface_count(),1)
	check_eq(heavy.get_surface_count(),1)
	check(light.get_aabb().size!=heavy.get_aabb().size)
