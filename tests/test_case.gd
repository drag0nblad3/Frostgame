class_name TestCase
extends RefCounted
## Base class for tests. Methods named test_* are run by tests/run_tests.gd.

var failures: Array[String] = []
var _current := ""


func check(cond: bool, msg: String = "") -> void:
	if not cond:
		failures.append("%s: %s" % [_current, msg])


func check_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		failures.append("%s: %s expected %s, got %s" % [_current, msg, expected, actual])


## Shared fixtures --------------------------------------------------------

static var _db: FigureDb
static var _terrain: TerrainDb


func db() -> FigureDb:
	if _db == null:
		_db = FigureDb.load_files()
	return _db


func terrain() -> TerrainDb:
	if _terrain == null:
		_terrain = TerrainDb.load_file()
	return _terrain


## Board of the given size; pieces as [kind, x, y, w, h].
func make_board(pieces: Array = [], size: Vector2 = Vector2(36, 36)) -> Board:
	var list := []
	for p: Array in pieces:
		list.append({"kind": p[0], "rect": [p[1], p[2], p[3], p[4]]})
	return BoardLoader.from_dict({"size": [size.x, size.y], "pieces": list}, terrain())


func fig(type: String, side: int, at: Vector2, id: int = 0) -> Figure:
	return Figure.new(id, db().get_def(type), side, at, db().unarmed())


## Two-sided game on `board` with these figures (ids assigned in order).
func make_game(board: Board, figs: Array[Figure], dice: Dice) -> GameController:
	var s := GameState.new()
	s.board = board
	s.side_names.assign(["Blue", "Red"])
	for i in figs.size():
		figs[i].id = i + 1
		s.figures.append(figs[i])
	return GameController.new(s, dice)
