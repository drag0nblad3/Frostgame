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
	if _dialog == "campaign":
		var draft := WarbandDraft.new(scene._figures)
		draft.choose_defaults()
		scene._campaign.start(draft.as_warband())
		scene._campaign.data["base"] = "tower"
		scene._campaign.data["resources"] = ["celestial_telescope","scriptorium","crystal_ball"]
		scene._campaign.data["games"] = 2
		scene._campaign.data["gold"] = 375
		scene._open_campaign()
		if not scene._campaign_dialog.visible:
			quit(1)
			return
	else:
		scene._open_roster()
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
