class_name BattleAtmosphere
extends Node3D
## One shadow-casting sun, gentle fill and a bounded decorative snow emitter.
## Indoor boards use a different palette and no snowfall. No gameplay influence.
var _sun: DirectionalLight3D
var _fill: DirectionalLight3D
var _environment: Environment
var _snow: CPUParticles3D
var _outdoors := true
var enabled := true


func _ready() -> void:
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-48, 37, 0)
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 65.0
	add_child(_sun)
	_fill = DirectionalLight3D.new()
	_fill.rotation_degrees = Vector3(-32, -142, 0)
	_fill.shadow_enabled = false
	add_child(_fill)
	var world := WorldEnvironment.new()
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_COLOR
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_energy = 0.47
	world.environment = _environment
	add_child(world)
	_snow = CPUParticles3D.new()
	_snow.amount = 96
	_snow.lifetime = 6.0
	_snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_snow.direction = Vector3(0.3, -1, 0.08)
	_snow.spread = 12.0
	_snow.gravity = Vector3(0.1, -0.08, 0)
	_snow.initial_velocity_min = 0.7
	_snow.initial_velocity_max = 1.4
	_snow.scale_amount_min = 0.65
	_snow.scale_amount_max = 1.5
	_snow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var flake := SphereMesh.new()
	flake.radius = 0.025
	flake.height = 0.05
	flake.radial_segments = 4
	flake.rings = 2
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.86, 0.94, 1.0)
	flake.material = material
	_snow.mesh = flake
	_snow.emitting = false
	add_child(_snow)


func configure(board: Board) -> void:
	_outdoors = board.id != "underground_library"
	var sky := Color(0.09, 0.14, 0.20)
	var key := Color(1.0, 0.90, 0.75)
	var fill := Color(0.57, 0.73, 1.0)
	match board.id:
		"underground_library":
			sky = Color(0.075, 0.065, 0.055)
			key = Color(1.0, 0.76, 0.49)
			fill = Color(0.58, 0.67, 0.83)
		"haunted_houses", "mausoleum":
			sky = Color(0.08, 0.12, 0.17)
			key = Color(0.80, 0.89, 1.0)
			fill = Color(0.53, 0.75, 0.71)
		"complex_temple", "the_keep", "dreams_well":
			sky = Color(0.095, 0.10, 0.19)
			key = Color(1.0, 0.87, 0.65)
			fill = Color(0.58, 0.69, 1.0)
		"silent_tower":
			sky = Color(0.07, 0.10, 0.16)
			key = Color(0.83, 0.89, 1.0)
			fill = Color(0.53, 0.65, 0.84)
	_environment.background_color = sky
	_environment.ambient_light_color = fill.lightened(0.42)
	_sun.light_color = key
	_sun.light_energy = 1.25 if _outdoors else 1.05
	_fill.light_color = fill
	_fill.light_energy = 0.42
	_snow.position = TableSpace.to_world(board.size * 0.5, 8.5)
	_snow.emission_box_extents = Vector3(board.size.x * 0.52, 2.5, board.size.y * 0.52)
	_snow.restart()
	set_effects(enabled)


func set_effects(on: bool) -> void:
	enabled = on
	_snow.emitting = on and _outdoors
	_snow.visible = on and _outdoors
