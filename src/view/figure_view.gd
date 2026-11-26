class_name FigureView
extends Node3D
## Procedural miniature, side-colored base, compact status label and active ring.

const SIDE_COLORS := [Color(0.25, 0.5, 0.95), Color(0.9, 0.3, 0.25), Color(0.3, 0.8, 0.4), Color(0.9, 0.8, 0.3)]
var figure_id := 0
var _plate: Label3D
var _model: Node3D
var _model_key := ""
var _base: MeshInstance3D
var _ring: MeshInstance3D
var _height := 1.6
var _facing := 0.0
var _health_track: MeshInstance3D
var _health_fill: MeshInstance3D
var _shield_ring: MeshInstance3D
var _model_rest_y := 0.12
var _moving := false
var _stride := 0.0


func setup(f: Figure, _side_name: String) -> void:
	figure_id = f.id
	set_process(false)
	_base = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = Figure.BASE_RADIUS
	cyl.bottom_radius = Figure.BASE_RADIUS
	cyl.height = 0.12
	_base.mesh = cyl
	_base.position.y = 0.06
	add_child(_base)
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.7
	_ring.mesh = torus
	_ring.material_override = BoardView._mat(Color(1, 0.95, 0.4), 0.3)
	_ring.position.y = 0.08
	_ring.visible = false
	add_child(_ring)
	var health_bar := BoxMesh.new()
	health_bar.size = Vector3(0.82, 0.045, 0.095)
	_health_track = MeshInstance3D.new()
	_health_track.mesh = health_bar
	_health_track.material_override = BoardView._mat(Color(0.09, 0.12, 0.16), 0.8)
	_health_track.position = Vector3(0, 0.10, 0.46)
	add_child(_health_track)
	_health_fill = MeshInstance3D.new()
	_health_fill.mesh = health_bar
	_health_fill.position = Vector3(0, 0.133, 0.46)
	add_child(_health_fill)
	_shield_ring = MeshInstance3D.new()
	var ward := TorusMesh.new()
	ward.inner_radius = 0.46
	ward.outer_radius = 0.51
	_shield_ring.mesh = ward
	var ward_mat := BoardView._mat(Color(0.23, 0.72, 0.98), 0.35)
	ward_mat.emission_enabled = true
	ward_mat.emission = Color(0.15, 0.52, 0.86)
	_shield_ring.material_override = ward_mat
	_shield_ring.position.y = 0.16
	add_child(_shield_ring)
	_plate = Label3D.new()
	_plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_plate.no_depth_test = true
	_plate.font_size = 44
	_plate.pixel_size = 0.009
	_plate.outline_size = 9
	add_child(_plate)
	position = TableSpace.to_world(f.pos, f.elevation)
	refresh(f)


func refresh(f: Figure) -> void:
	var color: Color = Color(0.65, 0.45, 0.75) if f.side < 0 else SIDE_COLORS[f.side % SIDE_COLORS.size()]
	_base.material_override = BoardView._mat(color.darkened(0.24), 0.6)
	var phantom := IllusionRules.phantom(f)
	var transparent := f.spell_effects.has("invisibility") or phantom
	var key := "%d:%s:%s:%s" % [f.side, f.melee.id if f.melee != null else "", f.ranged.id if f.ranged != null else "", transparent]
	if key != _model_key or _model == null:
		if _model != null:
			remove_child(_model)
			_model.queue_free()
		_model = MiniatureFactory.create(f, color)
		_model.position.y += 0.12
		_model_rest_y = _model.position.y
		_model.rotation.y = _facing
		add_child(_model)
		_model_key = key
		if transparent:
			MiniatureBatch.fade(_model)
	_height = 2.0 if f.def.traits.has("large") else (1.8 if f.def.role in ["wizard", "apprentice"] else 1.5)
	if f.def.traits.has("animal") and f.def.id != "white_gorilla":
		_height = 0.95 if not f.def.traits.has("large") else 1.3
	_plate.position.y = _height + 0.42
	var ratio := clampf(float(f.health) / maxf(1.0, float(f.def.health)), 0.0, 1.0)
	_health_fill.scale.x = maxf(0.01, ratio)
	_health_fill.position.x = -0.41 * (1.0 - ratio)
	_health_fill.material_override = BoardView._mat(Color(0.31, 0.75, 0.47) if ratio > 0.5 else Color(0.95, 0.49, 0.23), 0.7)
	_shield_ring.visible = f.elemental_shield > 0 or f.spell_effects.has("shield")
	var suffix := " · Illusion" if phantom else (" · Invisible" if transparent else "")
	var status := " · Loot" if f.treasure_id >= 0 else ""
	if f.poisoned:
		status += " · Poison"
	if ScenarioNull.muted(f):
		status += " · Null"
	if f.def.traits.has("immune_normal"):
		status += " · Magic only"
	_plate.text = "%s%s%s\n%d/%d" % [f.label(), suffix, status, f.health, f.def.health]
	_plate.modulate = Color(1, 1, 1) if f.health * 2 > f.def.health else Color(1, 0.6, 0.4)


func face_toward(at: Vector3) -> void:
	var dir := at - position
	if Vector2(dir.x, dir.z).length_squared() < 0.0001:
		return
	_facing = atan2(-dir.x, -dir.z)
	if _model != null:
		_model.rotation.y = _facing


func begin_move() -> void:
	_moving = true
	_stride = 0.0
	set_process(true)


func end_move() -> void:
	_moving = false
	set_process(false)
	if _model != null:
		_model.position.y = _model_rest_y
		_model.rotation.x = 0.0
		_model.rotation.z = 0.0
		MiniaturePose.arms(_model, 0.0, 0.0)


func _process(delta: float) -> void:
	if not _moving or _model == null:
		return
	_stride += delta * 19.0
	_model.position.y = _model_rest_y + absf(sin(_stride)) * 0.085
	_model.rotation.z = sin(_stride) * 0.035
	_model.rotation.x = -0.07
	MiniaturePose.arms(_model, sin(_stride) * 0.22, -sin(_stride) * 0.22)


func attack_pose(amount: float) -> void:
	if _model == null:
		return
	_model.rotation.x = -0.14 * amount
	MiniaturePose.arms(_model, -0.95 * amount, 0.28 * amount)


func shot_pose(amount: float) -> void:
	if _model == null:
		return
	_model.rotation.x = -0.06 * amount
	MiniaturePose.arms(_model, -0.18 * amount, 0.55 * amount)


func recoil_pose(amount: float) -> void:
	if _model != null:
		_model.rotation.x = 0.20 * amount
		MiniaturePose.arms(_model, 0.20 * amount, 0.40 * amount)


func set_active(on: bool) -> void:
	_ring.visible = on


func take_out() -> void:
	_plate.visible = false
	_ring.visible = false
	_health_fill.hide()
	_health_track.hide()
	_shield_ring.hide()
	var t := create_tween()
	t.tween_property(self, "rotation:z", PI * 0.5, 0.4)
	t.tween_property(self, "scale", Vector3(0.6, 0.6, 0.6), 0.3)
	t.tween_callback(func() -> void: visible = false)


func body_height() -> float:
	return _height * 0.65
