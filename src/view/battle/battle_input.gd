class_name BattleInput
extends RefCounted
## Player intents and legal-target previews. All mutations go through GameController.

signal move_preview_changed(id: int,at: Vector2,active: bool)

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


func lock(hint: String) -> void:
	move_plan.clear(self)
	attack_target=-1
	hud.set_actions([], "", hint)
	markers.clear()


func refresh() -> void:
	move_plan.clear(self)
	attack_target=-1
	BattleInputMenu.refresh(self)


func preview() -> void:
	BattleInputPreview.preview(self)


func action(key: String) -> bool:
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
		var ok := c.fight(target) if mode=="fight" else c.shoot(target)
		if not ok:
			refresh()
		return ok
	return BattleInputActions.action(self, key)


func plan_attack(id: int) -> void:
	var f := c.state.active()
	var t := c.state.figure(id)
	if f==null or t==null:
		return
	if not (c.can_fight(id) if mode=="fight" else c.can_shoot(id)):
		return
	attack_target=id
	available.assign(["attack_confirm","attack_cancel"])
	var info := "%s · HP %d/%d · Fight %+d · Armour %d"%[t.label(),t.health,t.def.health,t.effective_fight(),t.effective_armour()]
	if mode=="shoot":
		info+="\nRange %.1f″ / %.0f″ · %s"%[Shooting.distance(f,t),f.ranged.range_in,f.ranged.name]
		var los := LineOfSight.check_figures(c.state.board,f,t)
		info+=" · cover/intervening %+d"%Shooting.target_mod(los)
	else:
		info+="\nOpposed Fight rolls · weapon %s"%f.melee.name
	markers.show_move_plan(PackedVector2Array([t.pos]))
	hud.set_actions(available,mode,info+"\nConfirm attack to roll, or tap another legal target.")


func plan_drag(screen: Vector2) -> void:
	if mode not in BattleMovePlan.MODES:
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
