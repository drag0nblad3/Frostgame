class_name FigureView
extends Node3D
## A placeholder model for one figure: coloured base, body, and a nameplate.

const SIDE_COLORS := [Color(0.25, 0.5, 0.95), Color(0.9, 0.3, 0.25), Color(0.3, 0.8, 0.4), Color(0.9, 0.8, 0.3)]

var figure_id := 0
var _plate: Label3D
var _body: MeshInstance3D
var _base: MeshInstance3D
var _ring: MeshInstance3D


func setup(f: Figure, side_name: String) -> void:
	figure_id = f.id
	var col: Color = Color(0.65, 0.45, 0.75) if f.side < 0 else SIDE_COLORS[f.side % SIDE_COLORS.size()]
	var base := MeshInstance3D.new()
	_base = base
	var cyl := CylinderMesh.new()
	cyl.top_radius = Figure.BASE_RADIUS
	cyl.bottom_radius = Figure.BASE_RADIUS
	cyl.height = 0.12
	base.mesh = cyl
	base.material_override = BoardView._mat(col.darkened(0.3), 0.6)
	base.position.y = 0.06
	add_child(base)
	_body = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	var tall := 1.8 if f.def.role == "wizard" else (1.6 if f.def.role == "apprentice" else 1.4)
	cap.radius = 0.28
	cap.height = tall
	_body.mesh = cap
	_body.material_override = BoardView._mat(col, 0.7)
	_body.position.y = 0.12 + tall * 0.5
	add_child(_body)
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
	_plate.font_size = 56
	_plate.pixel_size = 0.01
	_plate.outline_size = 10
	_plate.position.y = tall + 0.7
	add_child(_plate)
	position = TableSpace.to_world(f.pos, f.elevation)
	refresh(f)


func refresh(f: Figure) -> void:
	var col: Color = Color(0.65, 0.45, 0.75) if f.side < 0 else SIDE_COLORS[f.side % SIDE_COLORS.size()]
	_base.material_override = BoardView._mat(col.darkened(0.3), 0.6)
	_body.material_override = BoardView._mat(col, 0.7)
	_plate.text = "%s\n%d/%d" % [f.label(), f.health, f.def.health]
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
	return _body.position.y
