class_name BattleTraining
extends RefCounted
## Training lessons for BattleScene: start, confirm, advance and leave.


static func _confirm_training(bs: BattleScene) -> void:
	if bs._training_prompt == null:
		bs._training_prompt = AcceptDialog.new()
		bs._training_prompt.title = "Practice in the Training Yard"
		bs._training_prompt.dialog_text = "Four short lessons teach movement, treasure, combat and magic. Training replaces the current battle, but never changes your campaign. Save your battle first if needed."
		bs._training_prompt.exclusive = true
		bs._training_prompt.get_ok_button().text = "Start training"
		bs._training_prompt.confirmed.connect(func() -> void: bs._start_training(0))
		bs.add_child(bs._training_prompt)
	PhoneSafeArea.popup_dialog(bs._training_prompt,Vector2(500,240))


static func _start_training(bs: BattleScene, index: int) -> void:
	bs._training = index
	bs._training_complete = false
	bs._training_failed = false
	bs._campaign_battle = false
	bs.watch_mode = false
	bs._active_scenario_id = "training_yard"
	var s := TrainingLesson.build(index, bs._figures, bs._terrain)
	s.reaction_side = bs.player_side
	bs._rig.distance = 23.0
	bs._attach_battle(GameController.new(s, Dice.new(1)), true)


static func _next_training(bs: BattleScene) -> void:
	if bs._training < 0 or not bs._training_complete or not bs.player.idle():
		return
	if bs._training + 1 < TrainingLesson.NAMES.size():
		bs._start_training(bs._training + 1)
	else:
		bs._leave_training()
		bs.hud.notify("Training complete. You are ready for a skirmish!")


static func _leave_training(bs: BattleScene) -> void:
	if bs._training < 0 or not bs.player.idle():
		return
	bs._scenario_id = BattleScene.SCENARIO
	bs.hud.select_scenario(BattleScene.SCENARIO)
	bs.new_game(0)
