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


static func floor_surface(board: Board) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var slab := PlaneMesh.new()
	slab.size = board.size
	node.mesh = slab
	node.position = TableSpace.to_world(board.size * 0.5, 0.008)
	node.material_override = material(Color(0.39, 0.38, 0.34) if board.id == "underground_library" else Color(0.47, 0.54, 0.60), true)
	if board.id == "underground_library":
		(node.material_override as ShaderMaterial).set_shader_parameter("snow_amount", 0.15)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
