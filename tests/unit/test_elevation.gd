extends TestCase


func test_climb_cost_and_falling() -> void:
	var b := make_board()
	var k := TerrainKind.new()
	k.walkable_top = true
	k.height = 2.0
	k.blocks_move = true
	b.pieces.append(TerrainPiece.new(k, Rect2(10, 10, 3, 3)))
	check_eq(b.height_at(Vector2(11, 11)), 2.0)
	check(b.can_stand(Vector2(11, 11), 0.5))
	check_eq(b.climb_cost(Vector2(9.5, 11), Vector2(10, 11)), 4.0)
	check_eq(ElevationRules.fall_damage(2.9), 0)
	check_eq(ElevationRules.fall_damage(3.0), 4)
	check_eq(ElevationRules.fall_damage(5.0), 7)


func test_cross_height_is_not_contact() -> void:
	var a := fig("thug", 0, Vector2(10, 10))
	var b := fig("thug", 1, Vector2(11, 10))
	a.elevation = 4.0
	check(not Contact.figures_touch(a, b))
	check(Shooting.distance(a, b) > 3.0)
