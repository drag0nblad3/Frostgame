extends SceneTree
## Exercise the actual full-screen workshop, including navigation and deployment.

var _scene: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene)
	_scene._open_roster()
	var setup: WarbandSetup=_scene._setup
	await process_frame
	if setup==null or not setup.draft.errors().is_empty() or not ModalInput.blocked():
		quit(1)
		return
	if setup._overview.lineup._models.size()!=4 or setup._overview._slots.get_child_count()!=10:
		printerr("Lineup missing initial warband or vacant slots")
		quit(1)
		return
	setup.inspect(0)
	await process_frame
	if setup._inspector.portrait._model==null or setup._inspector._selection.item_count!=10:
		printerr("Wizard dossier or visible schools missing")
		quit(1)
		return
	setup.open_spells()
	setup._spellbook.select_slot(6)
	if setup._spellbook._choices.item_count==0 or setup._spellbook._slots.get_child_count()!=8:
		quit(1)
		return
	ModalInput.close_top(root)
	if setup._page!=setup._inspector or not setup.visible:
		printerr("Back did not return to dossier")
		quit(1)
		return
	ModalInput.close_top(root)
	if setup._page!=setup._overview:
		quit(1)
		return
	setup.inspect(4)
	await process_frame
	if setup._inspector.portrait._model==null or setup._inspector._selection.item_count<8:
		quit(1)
		return
	setup._inspector._candidate="infantryman"
	setup._inspector._hire()
	if setup._overview.lineup._models.size()!=5:
		printerr("New recruit missing from stage")
		quit(1)
		return
	setup.draft.wizard_name="CI Wizard"
	setup.draft.school="witch"
	setup.draft.choose_defaults()
	setup._update()
	setup._confirm()
	var s: GameState=_scene.controller.state
	if s.side_names[0]!="CI Wizard" or s.spellbooks[0].size()!=8 or s.side_schools.get(0)!="witch" or s.side_figures(0).size()!=5:
		printerr("Roster deployment failed")
		quit(1)
		return
	print("Workshop smoke passed: stage, dossiers, spellbook, Back, hire, deploy")
	quit(0)
