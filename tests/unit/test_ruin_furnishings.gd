extends TestCase


func test_furnishings_use_existing_terrain_rules() -> void:
	var catalog:=terrain()
	for id in ["ruin_market_counter","ruin_altar","ruin_workbench","ruin_hearth"]:
		var k:=catalog.get_kind(id)
		check_eq(k.cover,TerrainKind.Cover.HEAVY,id)
		check_eq(k.move_mult,2.0,id)
		check_eq(k.height,1.0,id)
	for id in ["ruin_timber_wall","ruin_archive_shelf"]:
		var k:=catalog.get_kind(id)
		check(k.blocks_move and k.blocks_los,id)
	check_eq(catalog.get_kind("ruin_grave").cover,TerrainKind.Cover.LIGHT)


func test_furnishing_models_build() -> void:
	var catalog:=terrain()
	for id in ["ruin_market_counter","ruin_altar","ruin_workbench","ruin_hearth","ruin_timber_wall","ruin_archive_shelf","ruin_grave"]:
		var root:=Node3D.new()
		RuinFurnishing.build(root,TerrainPiece.new(catalog.get_kind(id),Rect2(3,4,2,0.8)))
		check(root.get_child_count()>0,id)
		root.free()
