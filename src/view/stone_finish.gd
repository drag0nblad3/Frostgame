class_name StoneFinish
extends RefCounted
## Shared world-space materials for terrain; no per-brick draw calls.

const STONE := preload("res://src/view/materials/frozen_stone.gdshader")
const STONE_KINDS := ["ruin", "wall", "platform", "tower", "hut_wall", "null_annex", "null_walk", "null_lower", "null_middle", "null_upper"]


static func material(color: Color, ground: bool = false, arches: bool = false, origin: Vector2 = Vector2.ZERO) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = STONE
	mat.set_shader_parameter("stone_color", color)
	mat.set_shader_parameter("ground", ground)
	mat.set_shader_parameter("blind_arches", arches)
	mat.set_shader_parameter("footprint_origin", origin)
	return mat


static func floor_surface(board: Board, scenario: String = "") -> MeshInstance3D:
	var node := MeshInstance3D.new()
	if board.has_ground_profiles:
		node.mesh = GroundMesh.build(board)
	else:
		var slab := PlaneMesh.new()
		slab.size = board.size
		node.mesh = slab
		node.position = TableSpace.to_world(board.size * 0.5, 0.008)
	var palette := VisualPalette.for_scenario(board.id if scenario.is_empty() else scenario)
	var mat := material(Color(str(palette.get("floor", "687781"))), true)
	mat.set_shader_parameter("snow_amount", float(palette.get("snow", 0.86)))
	mat.set_shader_parameter("footprint_size",board.size)
	mat.set_shader_parameter("city_paving",scenario not in ["underground_library","worm_hunts","training_yard"] and board.id not in ["underground_library","worm_hunts","training_yard"])
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
