class_name BattleInput
extends RefCounted
## Player intents and legal-target previews. All mutations go through GameController.

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
var move_destination: Variant=null
var move_drag := true
var move_visual: Callable
const MOVE_CONTROLS := ["move_confirm","move_reset","move_camera"]


func _init(controller: GameController, command_bar: BattleHud, cam: Camera3D, overlay: BattleMarkers) -> void:
	c = controller
	hud = command_bar
	camera = cam
	markers = overlay


func lock(hint: String) -> void:
	clear_move_preview()
	hud.set_actions([], "", hint)
	markers.clear()


func refresh() -> void:
	clear_move_preview()
	BattleInputMenu.refresh(self)


func preview() -> void:
	BattleInputPreview.preview(self)


func action(key: String) -> bool:
	if key in MOVE_CONTROLS:
		if mode!="move" or not available.has(key):
			return false
		match key:
			"move_confirm":
				if move_destination==null:
					return false
				var destination: Vector2i=move_destination
				clear_move_preview()
				var ok := c.move_to(destination)
				if not ok:
					refresh()
				return ok
			"move_reset":
				clear_move_preview()
				update_move_controls()
			"move_camera":
				move_drag=not move_drag
				update_move_controls()
		return false
	if key!="move" and available.has(key):
		clear_move_preview()
		for control in MOVE_CONTROLS:
			available.erase(control)
	return BattleInputActions.action(self,key)


## A draft is only a legal destination from the original rules-state position.
## No actions, RNG, visibility, movement hooks or reactions run until Confirm.
func plan_move(node: Vector2i) -> void:
	if mode!="move" or reach==null or not nodes.has(node) or move_destination==node:
		return
	move_destination=node
	markers.show_move_path(reach.path_to(node))
	if move_visual.is_valid():
		move_visual.call(MoveGrid.to_pos(node))
	update_move_controls()


func clear_move_preview() -> void:
	if move_destination!=null and move_visual.is_valid():
		move_visual.call(null)
	move_destination=null
	markers.clear_move_path()


func update_move_controls() -> void:
	var f := c.state.active()
	if f==null or mode!="move":
		return
	var allowance := MoveRules.allowance(f)
	var info := "Movement budget %.1f″ · Tap or drag a marked destination."%allowance
	if move_destination!=null and reach!=null:
		var cost := float(reach.cost[move_destination])
		info="Planned %.1f″ / %.1f″ · %.1f″ remaining · Not committed"%[cost,allowance,maxf(0.0,allowance-cost)]
	hud.set_move_controls(move_destination!=null,move_drag,info)


func drag_move(screen: Vector2) -> void:
	if mode!="move" or not move_drag or reach==null:
		return
	var hit: Variant=_surface_at(screen)
	if hit!=null:
		plan_move(MovePlanner.node_at(hit))


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
