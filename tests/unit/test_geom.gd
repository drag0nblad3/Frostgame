extends TestCase


func test_segment_crosses_rect() -> void:
	var r := Rect2(4, 4, 2, 2)
	check(Geom.crosses(Vector2(0, 5), Vector2(10, 5), r), "straight through")
	check(not Geom.crosses(Vector2(0, 0), Vector2(10, 0), r), "passes below")
	check(not Geom.crosses(Vector2(0, 5), Vector2(3, 5), r), "stops short")


func test_length_inside() -> void:
	var r := Rect2(4, 4, 2, 2)
	check(is_equal_approx(Geom.length_inside(Vector2(0, 5), Vector2(10, 5), r), 2.0), "2\" inside")


func test_point_rect_distance() -> void:
	var r := Rect2(0, 0, 2, 2)
	check_eq(Geom.point_rect_distance(Vector2(1, 1), r), 0.0, "inside")
	check(is_equal_approx(Geom.point_rect_distance(Vector2(5, 1), r), 3.0), "3\" to the right")
