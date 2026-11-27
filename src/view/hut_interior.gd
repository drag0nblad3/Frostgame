class_name HutInterior
extends RefCounted
## Low reliefs of abandoned monastic furnishings. Keep the doorway and
## treasure clear and use the actual authored entrance to orient the floor.


static func decorate(root: Node3D,p: TerrainPiece,seed: int) -> void:
	var center:=p.rect.get_center()
	var dir:=Vector2(0,-1)
	match p.entrance:
		"south": dir=Vector2.DOWN
		"east": dir=Vector2.RIGHT
		"west": dir=Vector2.LEFT
	var tangent:=Vector2(-dir.y,dir.x)
	var extent:=minf(p.rect.size.x,p.rect.size.y)*0.5
	var rear:=center-dir*(extent-0.42)
	var tint:=Color("63584d").lerp(Color("82847a"),float(seed%5)*0.20)
	for i in 4:
		var at:=rear+tangent*(float(i)-1.5)*0.38
		EnvironmentProps.paving(root,TableSpace.to_world(at,0.065),0.24,i+seed,tint)
	# Flattened remnants against side walls rather than blocking the central aisle.
	var side:=center+tangent*(extent-0.35)
	if seed%3==0:
		BattlefieldDetail.boards(root,TableSpace.to_world(side,0.065),seed)
	elif seed%3==1:
		BattlefieldDetail.inlay(root,TableSpace.to_world(side,0.065),Color("a18b65"),seed,false)
	else:
		BattlefieldDetail.scar(root,TableSpace.to_world(side,0.065),seed,Color("90948a"))
	var threshold:=center+dir*(extent-0.12)
	var strip:=MiniatureFactory.box(root,TableSpace.to_world(threshold,0.065),Vector3(1.4,0.03,0.12),Color("a39d87"))
	if absf(dir.x)>0.5:
		strip.rotation.y=PI*0.5
