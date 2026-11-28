class_name WaterTerrainArt
extends RefCounted
## Static, inexpensive pool art. Surface footprint matches the rule region.
## Dark open water and lighter broken ice distinguish deep and shallow areas.
static func build(root: Node3D,board: Board,p: TerrainPiece) -> void:
	var deep:=p.kind.id=="deep_water"
	var rect:=p.rect
	var center:=rect.get_center()
	var level:=board.ground_height_at(center) if p.surface_id.is_empty() else 0.0
	var y:=level+(0.055 if deep else 0.025)
	var water:=MeshInstance3D.new()
	var plane:=PlaneMesh.new()
	plane.size=rect.size
	water.mesh=plane
	water.position=TableSpace.to_world(center,y)
	var mat:=BoardView._mat(Color("234a60") if deep else Color("679ba7"),0.30)
	mat.metallic=0.15
	water.material_override=mat
	water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(water)
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash(rect)
	for i in clampi(roundi(rect.get_area()*0.75),3,18):
		var width:=minf(rect.size.x*0.45,rng.randf_range(0.25,0.95))
		var at:=rect.position+Vector2(rng.randf_range(width*0.5,rect.size.x-width*0.5),rng.randf_range(0.06,rect.size.y-0.06))
		var ripple:=MiniatureFactory.box(root,TableSpace.to_world(at,y+0.008),Vector3(width,0.012,0.035),Color("54869c") if deep else Color("b4d6da"))
		ripple.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MiniatureBatch.bake(root)
