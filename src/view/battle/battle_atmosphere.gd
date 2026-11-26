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
	_sun.shadow_enabled = GraphicsQuality.mode()>0
	_sun.directional_shadow_max_distance = maxf(1.0,GraphicsQuality.shadow_distance())
	_sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL if GraphicsQuality.mode()<2 else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
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


func configure(board: Board, scenario: String = "") -> void:
	var palette := VisualPalette.for_scenario(board.id if scenario.is_empty() else scenario)
	var count := GraphicsQuality.snow_count(int(palette.get("flakes",96)))
	_sun.shadow_enabled=GraphicsQuality.mode()>0
	_sun.directional_shadow_max_distance=maxf(1.0,GraphicsQuality.shadow_distance())
	_sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL if GraphicsQuality.mode()<2 else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	_outdoors = count > 0
	_environment.background_color = Color(str(palette.get("sky", "233849")))
	_fill.light_color = Color(str(palette.get("fill", "9dc7ec")))
	_environment.ambient_light_color = _fill.light_color.lightened(0.32)
	_environment.ambient_light_energy = float(palette.get("ambient", 0.48))
	_sun.light_color = Color(str(palette.get("key", "f2dfbd")))
	_sun.light_energy = float(palette.get("energy", 1.25))
	_fill.light_energy = 0.35
	_snow.amount = maxi(1, count)
	_snow.position = TableSpace.to_world(board.size * 0.5, 8.5)
	_snow.emission_box_extents = Vector3(board.size.x * 0.52, 2.5, board.size.y * 0.52)
	_snow.restart()
	set_effects(enabled)


func set_effects(on: bool) -> void:
	enabled = on
	_snow.emitting = on and _outdoors
	_snow.visible = on and _outdoors
