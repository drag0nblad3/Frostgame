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


func _init(controller: GameController, command_bar: BattleHud, cam: Camera3D, overlay: BattleMarkers) -> void:
	c = controller
	hud = command_bar
	camera = cam
	markers = overlay


func lock(hint: String) -> void:
	hud.set_actions([], "", hint)
	markers.clear()


func refresh() -> void:
	BattleInputMenu.refresh(self)


func preview() -> void:
	BattleInputPreview.preview(self)


func action(key: String) -> bool:
	return BattleInputActions.action(self, key)


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
