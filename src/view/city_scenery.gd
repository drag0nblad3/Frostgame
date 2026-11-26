class_name CityScenery
extends RefCounted
## Noninteractive district beyond the battlefield. Roofs stay below table level
## in battle so no decorative geometry can hide the playable area.


static func build(board: Board, scenario: String, cinematic: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = "CityScenery"
	if scenario in ["underground_library", "training_yard"]:
		return root
	var palette := VisualPalette.for_scenario(scenario)
	var sky := Color(str(palette.get("sky","233849")))
	var center := board.size * 0.5
	var ground_y := -7.5
	var floor_color := sky.lerp(Color(0.59,0.69,0.75),0.40)
	MiniatureFactory.box(root,TableSpace.to_world(center,ground_y-0.15),Vector3(board.size.x+65,0.3,board.size.y+65),floor_color)
	# Two irregular rings of miniature districts. A clear moat of space
	# separates their roofs from the playable terrain border.
	for layer in 2:
		var distance := 7.0+layer*12.0
		for side in 4:
			var length := board.size.x if side % 2 == 0 else board.size.y
			var count := maxi(3, floori(length/5.5)+layer*2)
			for i in count:
				var seed := side*137+i*53+layer*211
				var offset := (float(i)+0.5)*length/count
				var at := Vector2(offset,-distance) if side == 0 else (Vector2(board.size.x+distance,offset) if side == 1 else (Vector2(offset,board.size.y+distance) if side == 2 else Vector2(-distance,offset)))
				at += Vector2(sin(seed*1.7),cos(seed*2.1))*1.1
				var tone := floor_color.lerp(sky,0.28+0.18*layer)
				var h := 2.8+float(posmod(seed,19))*0.14
				if cinematic and layer == 1:
					h += 2.0+float(posmod(seed,7))*0.35
				var w := 2.5+float(posmod(seed,5))*0.30
				var d := 2.8+float(posmod(seed,7))*0.21
				_building(root,at,ground_y,h,w,d,tone,seed)
	MiniatureBatch.bake(root)
	for child in root.get_children():
		if child is MeshInstance3D:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


static func _building(root: Node3D, at: Vector2, ground: float, h: float, w: float, d: float, tint: Color, seed: int) -> void:
	var c := TableSpace.to_world(at,ground+h*0.5)
	var stone := tint.darkened(float(posmod(seed,4))*0.07)
	var snow := tint.lightened(0.27)
	MiniatureFactory.box(root,c,Vector3(w,h,d),stone)
	# Distinct gables, stepped roofs and ruined turrets, in silhouette.
	match posmod(seed,3):
		0:
			var roof := PrismMesh.new()
			roof.size = Vector3(w+0.20,0.85,d+0.15)
			var gable := MiniatureFactory.mesh(root,roof,c+Vector3(0,h*0.5+0.35,0),snow)
			gable.rotation.y = 0.0
		1:
			MiniatureFactory.box(root,c+Vector3(0,h*0.5+0.04,0),Vector3(w+0.12,0.16,d+0.12),snow)
			for side: float in [-1.0,1.0]:
				for i in 3:
					if posmod(seed+i,4)==0:
						continue
					MiniatureFactory.box(root,c+Vector3((i-1)*w*0.35,h*0.5+0.28,side*d*0.45),Vector3(w*0.18,0.52,0.35),stone.lightened(0.12))
		_:
			MiniatureFactory.box(root,c+Vector3(0,h*0.5+0.08,0),Vector3(w,0.18,d),snow)
			MiniatureFactory.box(root,c+Vector3(w*0.25,h*0.5+0.38,d*0.20),Vector3(w*0.38,0.75,d*0.36),stone.darkened(0.12))
	# Windows are distant dark relief, not light sources or tactical targets.
	for side: float in [-1.0,1.0]:
		for i in 2:
			var y := ground+h*0.43+i*h*0.30
			for j in 2:
				MiniatureFactory.box(root,Vector3(at.x+(j-0.5)*w*0.48,y,at.y+side*d*0.5),Vector3(0.30,0.61,0.035),stone.darkened(0.28))
				MiniatureFactory.box(root,Vector3(at.x+side*w*0.5,y,at.y+(j-0.5)*d*0.48),Vector3(0.035,0.61,0.30),stone.darkened(0.28))
