extends SceneTree
## Capture actual dialogs using a temporary in-memory campaign and draft.
var _frames := 0
var _ready_to_capture := false
var _out := ""
var _dialog := ""


func _initialize() -> void:
	call_deferred("_setup")


func _setup() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if not args.is_empty() else "/tmp/interface.png"
	_dialog = args[1] if args.size() > 1 else "roster"
	root.gui_embed_subwindows = true
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	if _dialog=="guide":
		scene._open_guide()
		if not scene._guide.visible:
			quit(1)
			return
	elif _dialog=="commands":
		scene.hud._open_commands()
	elif _dialog=="graphics":
		scene._open_graphics()
	elif _dialog=="inspector":
		scene._open_inspector()
	elif _dialog=="briefing":
		scene._open_briefing(false)
	elif _dialog=="maps":
		scene.player.speed=30.0
		while not scene.player.idle():
			await process_frame
		scene._open_map_picker()
		if scene._picker==null or not scene._picker.visible:
			quit(1)
			return
	elif _dialog in ["campaign","equipment","rituals","base","chronicle"]:
		var draft := WarbandDraft.new(scene._figures)
		draft.choose_defaults()
		scene._campaign.start(draft.as_warband())
		scene._campaign.data["base"] = "tower"
		scene._campaign.data["resources"] = ["celestial_telescope","scriptorium","crystal_ball"]
		scene._campaign.data["games"] = 2
		scene._campaign.data["gold"] = 375
		scene._open_campaign()
		var sections := {"equipment":2,"rituals":3,"base":4,"chronicle":5}
		if sections.has(_dialog):
			scene._campaign_dialog._show_section(sections[_dialog])
		if not scene._campaign_dialog.visible:
			quit(1)
			return
	else:
		scene._open_roster()
		if _dialog=="spells":
			scene._setup.open_spells()
		elif _dialog=="recruits":
			scene._setup.inspect(scene._setup.draft.soldiers.size()+2)
		elif _dialog=="wizard":
			scene._setup.inspect(0)
		elif _dialog=="full-roster":
			while scene._setup.draft.can_hire("thug"):
				scene._setup.draft.hire("thug")
			scene._setup.show_overview()
		if not scene._setup.visible:
			quit(1)
			return
	_ready_to_capture = true


func _process(_delta: float) -> bool:
	if not _ready_to_capture:
		return false
	_frames += 1
	if _frames < 45:
		return false
	var img := root.get_texture().get_image()
	if img == null or img.save_png(_out) != OK:
		quit(1)
		return true
	print("Interface captured: ",_dialog," ",_out)
	return true
