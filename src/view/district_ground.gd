class_name DistrictGround
extends RefCounted
## Continuous world-space paving outside the actual game board. Never fills
## the playable rectangle, so sunken courtyards and ramps remain intact.
const EXTENT := 42.0
const STREET_Y := 0.008


static func strips(size: Vector2) -> Array[Rect2]:
	var e := EXTENT
	return [
		Rect2(-e,-e,size.x+e*2.0,e),
		Rect2(-e,size.y,size.x+e*2.0,e),
		Rect2(-e,0,e,size.y),
		Rect2(size.x,0,e,size.y)
	]


static func build(board: Board,material: Material,scenario: String="") -> Node3D:
	var root := Node3D.new()
	root.name="DistrictGround"
	var exterior:=material as ShaderMaterial
	if exterior!=null:
		exterior=exterior.duplicate() as ShaderMaterial
		exterior.set_shader_parameter("exterior_style",int(ExteriorProfile.get_profile(scenario).get("ground",0)))
		material=exterior
	for rect in strips(board.size):
		var plane := PlaneMesh.new()
		plane.size=rect.size
		var node := MeshInstance3D.new()
		node.mesh=plane
		node.material_override=material
		node.position=TableSpace.to_world(rect.get_center(),STREET_Y)
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(node)
	return root
