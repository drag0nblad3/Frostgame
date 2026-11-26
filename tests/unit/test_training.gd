extends TestCase


func _practice(index: int) -> GameController:
	var s := TrainingLesson.build(index, db(), terrain())
	var c := GameController.new(s, LoadedDice.new([20, 1, 16, 1]))
	c.start_game()
	check(c.activate(1))
	return c


func test_training_move_and_collect() -> void:
	var c := _practice(0)
	check(c.move_to(MovePlanner.node_at(Vector2(9, 6.5))))
	check(c.pick_up(0))
	check(TrainingLesson.completed(0, c))


func test_training_escape() -> void:
	var c := _practice(1)
	check(c.exit_table(MovePlanner.node_at(Vector2(9, 0.5))))
	check(TrainingLesson.completed(1, c))


func test_training_fight() -> void:
	var c := _practice(2)
	check(c.move_to(MovePlanner.node_at(Vector2(9, 6))))
	check(c.fight(3))
	check(TrainingLesson.completed(2, c))


func test_training_cast() -> void:
	var c := _practice(3)
	check(c.start_cast("strength", 1))
	check(c.finish_cast(0))
	check(TrainingLesson.completed(3, c))
