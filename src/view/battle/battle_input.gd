class_name BattleInput
extends RefCounted
## Player intents and legal-target previews. All mutations go through GameController.

signal move_preview_changed(id: int,at: Vector3,active: bool)

var movement: BattleMovementOptions
var floor_layout: FloorLayout
var floor_id := ""
var floor_points := {}
var bridge_start: Variant=null

var move_plan := BattleMovePlan.new()
var attack_target := -1

var c: GameController
var hud: BattleHud
var camera: Camera3D
var markers: BattleMarkers
var mode := ""
var available: Array[String] = []
var reach: MoveReach
var targets: Array[Figure] = []
var tokens: Array[TreasureToken] = []
var nodes: Array[Vector2i] = []
var drops: Array[Vector2] = []
var group_selection: Array[int] = []
var cast_options: Array[String] = []
var item_options: Array[String] = []
var selected_spell := ""
var spell_ammo := false
var selected_potion := ""
var selected_drop := -1
var spell_rotated := false
var spell_extended := false
var spell_first := -1
var leap_air_offset:=0.0
var counter_index := 0
var counter_choices: Array[Dictionary] = []
var empower := 0
var transfer_target := -1
var transfer_amount := 1


func _init(controller: GameController, command_bar: BattleHud, cam: Camera3D, overlay: BattleMarkers) -> void:
	c = controller
	hud = command_bar
	camera = cam
	markers = overlay


func is_layered() -> bool:
	return not c.state.board.floor_layout.is_empty()


func select_floor(id: String) -> void:
	floor_id=id
	if move_plan.destination!=null:
		# Floor selection is a view change only; preserve the draft.
		BattleFloorInput.draw_points(self)
		move_plan.choose_node(self,move_plan.destination)
		move_plan.draw(self)
	elif attack_target>=0:
		preview()
		plan_attack(attack_target)
	else:
		preview()


func floor_target_at(screen: Vector2) -> Variant:
	return BattleFloorInput.pick(self,screen)


func lock(hint: String) -> void:
	move_plan.clear(self)
	attack_target=-1
	hud.set_actions([], "", hint)
	markers.clear()
	floor_points.clear()
	movement=null


func refresh() -> void:
	move_plan.clear(self)
	attack_target=-1
	movement=null
	floor_points.clear()
	if is_layered():
		floor_layout=c.state.board.floor_geometry()
		if floor_layout.index_of(floor_id)<0:
			floor_id=""
	BattleInputMenu.refresh(self)


func preview() -> void:
	BattleInputPreview.preview(self)


func action(key: String) -> bool:
	if key.begins_with("combat_weapon_"):
		return available.has(key) and BattleEquipmentAction.execute(c,"melee_choice",{"weapon":key.trim_prefix("combat_weapon_")})
	if key in ["core_collect","core_leave"]:
		return available.has(key) and BattleScenarioAction.execute(c,"core_choice",{"index":0 if key=="core_collect" else 1})
	if key=="move_confirm":
		return available.has(key) and move_plan.confirm(self)
	if key=="move_undo" and available.has(key):
		refresh()
		return false
	if key=="attack_cancel" and available.has(key):
		refresh()
		return false
	if key=="attack_confirm" and available.has(key):
		var target := attack_target
		attack_target=-1
		var ok := BattleAction.execute(c,mode,target)
		if not ok:
			refresh()
		return ok
	if is_layered() and BattleFloorInput.handles_action(self,key):
		return BattleFloorInput.action(self,key)
	return BattleInputActions.action(self, key)


func plan_attack(id: int) -> void:
	var f := c.state.active()
	var t := c.state.figure(id)
	if f==null or t==null:
		return
	var details := BattleAction.attack_preview(c,mode,id)
	if details.is_empty():
		return
	attack_target=id
	available.assign(["attack_confirm","attack_cancel"])
	var info := "%s · HP %d/%d · Fight %+d · Armour %d"%[t.label(),details["health"],details["max_health"],details["fight"],details["armour"]]
	if details.has("range"):
		info+="\nRange %.1f″ / %.0f″ · %s"%[details["range"],details["maximum_range"],details["weapon"]]
		info+=" · situational defence %+d"%details["defence_modifier"]
		if details["random_target"]:
			info+="\nShot into combat: the actual target is determined by a roll."
	else:
		info+="\nOpposed Fight rolls · weapon %s"%details["weapon"]
	info+="\nCosts %d action."%details["cost"]
	markers.show_world_plan(PackedVector3Array([TableSpace.to_world(t.pos,t.elevation)]))
	hud.set_actions(available,mode,info+"\nConfirm attack to roll, or tap another legal target.")


func plan_drag(screen: Vector2) -> void:
	if mode not in BattleMovePlan.MODES:
		return
	if is_layered():
		var node: Variant=floor_target_at(screen)
		if node!=null:
			move_plan.choose_node(self,node)
		return
	var hit: Variant=_surface_at(screen)
	if hit!=null:
		move_plan.choose(self,hit)


func tap(screen: Vector2) -> bool:
	return BattleInputTap.tap(self, screen)


func _figure_at(screen: Vector2) -> int:
	return BattleInputTap._figure_at(self, screen)


func _group_buttons() -> void:
	BattleInputMenu._group_buttons(self)


func _empower_buttons() -> void:
	BattleInputMenu._empower_buttons(self)


## Pick the nearest visible exposed surface rather than always intersecting ground.
func _surface_at(screen: Vector2) -> Variant:
	return BattleInputTap._surface_at(self, screen)

func _resist_buttons() -> void:
	BattleInputMenu._resist_buttons(self)


func _declared(ok: bool) -> bool:
	return BattleInputTap._declared(self, ok)


func _transfer_buttons() -> void:
	BattleInputMenu._transfer_buttons(self)


func _vampire_buttons(p: Dictionary,cast: bool,f: Figure) -> void:
	BattleInputMenu._vampire_buttons(self, p, cast, f)


func _vampire_hint(p: Dictionary,cast: bool) -> String:
	return BattleInputMenu._vampire_hint(self, p, cast)
