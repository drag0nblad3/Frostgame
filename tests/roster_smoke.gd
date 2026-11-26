extends SceneTree
## Headless construction and deployment of the actual roster editor.

var _scene: Node
var _started := false


func _initialize() -> void:
	_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
	if not _scene.has_method("_open_roster"):
		printerr("Battle scene script did not load")
		quit(1)
		return true
	_scene._open_roster()
	var setup: WarbandSetup = _scene._setup
	if setup == null or not setup.draft.errors().is_empty():
		quit(1)
		return true
	if setup._recruit_portrait._model == null or setup._recruit_info.text.is_empty():
		printerr("Recruitment preview unavailable")
		quit(1)
		return true
	setup.draft.wizard_name = "CI Wizard"
	setup.draft.school = "witch"
	setup.draft.choose_defaults()
	setup._rebuild_spells()
	setup._update()
	if not setup.draft.hire("infantryman"):
		quit(1)
		return true
	setup._confirm()
	var s: GameState = _scene.controller.state
	if s.side_names[0] != "CI Wizard" or s.spellbooks[0].size() != 8 or s.side_schools.get(0) != "witch" or s.side_figures(0).size() != 5:
		printerr("Roster deployment failed")
		quit(1)
		return true
	print("Roster smoke passed: creation, school, spells, hire, deployment")
	quit(0)
	return true
