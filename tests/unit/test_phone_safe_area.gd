extends TestCase


func test_notch_left_in_landscape() -> void:
	var rect := PhoneSafeArea.logical_rect(Vector2(1600,720),Rect2(0,0,2400,1080),Rect2(120,0,2280,1050),10)
	check(rect.position.is_equal_approx(Vector2(90,10)))
	check(rect.end.is_equal_approx(Vector2(1590,690)))


func test_notch_right_and_bottom_navigation() -> void:
	var rect := PhoneSafeArea.logical_rect(Vector2(1600,720),Rect2(0,0,2400,1080),Rect2(0,0,2280,1020),10)
	check(rect.position.is_equal_approx(Vector2(10,10)))
	check(rect.end.is_equal_approx(Vector2(1510,670)))


func test_portrait_cutout() -> void:
	var rect := PhoneSafeArea.logical_rect(Vector2(720,1600),Rect2(0,0,1080,2400),Rect2(0,90,1080,2220),10)
	check(rect.position.is_equal_approx(Vector2(10,70)))
	check(rect.end.is_equal_approx(Vector2(710,1530)))
