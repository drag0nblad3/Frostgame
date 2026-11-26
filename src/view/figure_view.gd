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


func setup(f: Figure, _side_name: String) -> void:
	figure_id = f.id
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
		add_child(_model)
		_model_key = key
		if transparent:
			for child in _model.get_children():
				if child is MeshInstance3D:
					var material: StandardMaterial3D = child.material_override
					material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					material.albedo_color.a = 0.35
	_height = 2.0 if f.def.traits.has("large") else (1.8 if f.def.role in ["wizard", "apprentice"] else 1.5)
	_plate.position.y = _height + 0.42
	var suffix := " · Illusion" if phantom else (" · Invisible" if transparent else "")
	var status := " · Loot" if f.treasure_id >= 0 else ""
	if f.poisoned:
		status += " · Poison"
	_plate.text = "%s%s%s\n%d/%d" % [f.label(), suffix, status, f.health, f.def.health]
	_plate.modulate = Color(1, 1, 1) if f.health * 2 > f.def.health else Color(1, 0.6, 0.4)


func set_active(on: bool) -> void:
	_ring.visible = on


func take_out() -> void:
	_plate.visible = false
	_ring.visible = false
	var t := create_tween()
	t.tween_property(self, "rotation:z", PI * 0.5, 0.4)
	t.tween_property(self, "scale", Vector3(0.6, 0.6, 0.6), 0.3)
	t.tween_callback(func() -> void: visible = false)


func body_height() -> float:
	return _height * 0.65
