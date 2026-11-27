extends BattleScene
## Compatibility launcher only. No alternate battle scene, HUD, input,
## animation loop, save command or bot scheduler.
func _ready() -> void:
	if not get_tree().root.has_meta("layered_board"):
		get_tree().root.set_meta("layered_board","stacked_gatehouse")
	super._ready()
