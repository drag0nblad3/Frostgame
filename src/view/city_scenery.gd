class_name CityScenery
extends RefCounted
## Noninteractive city on the same street level as the playable battlefield.
## Foreground districts are hidden only during low-angle outside camera views.


static func baked_path(board: Board,scenario: String,cinematic: bool=false) -> String:
	return BakedVisuals.DIR+"city/v4_%s_%s_%d_%s.scn"%[scenario,str(board.size).sha256_text().substr(0,12),GraphicsQuality.mode(),"title" if cinematic else "battle"]


static func load_baked(board: Board,scenario: String,cinematic: bool=false) -> Node3D:
	return BakedVisuals.load_scene(baked_path(board,scenario,cinematic))


static func build(board: Board, scenario: String, cinematic: bool = false) -> Node3D:
	var baked := load_baked(board,scenario,cinematic)
	return baked if baked!=null else build_procedural(board,scenario,cinematic)


static func build_procedural(board: Board, scenario: String, cinematic: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = "CityScenery"
	for side in 4:
		root.add_child(build_district(board,scenario,cinematic,side))
	return root


## Build one district independently so the battle can spread the work over frames.
static func build_district(board: Board,scenario: String,cinematic: bool,side: int) -> Node3D:
	var palette := VisualPalette.for_scenario(scenario)
	var sky := Color(str(palette.get("sky","233849")))
	var ground_y := 0.008
	var floor_color := Color(str(palette.get("floor","687781"))).lerp(sky,0.18)
	var district := Node3D.new()
	district.name="District%d"%side
	for entry in ExteriorProfile.plan(board.size,scenario,GraphicsQuality.mode(),GraphicsQuality.city_rings(),side,cinematic):
		var at: Vector2=entry["at"]
		var row:=int(entry["row"])
		var seed:=int(entry["seed"])
		var kind:=str(entry["kind"])
		var tone:=floor_color.lerp(sky,clampf(0.12+0.16*row,0.0,0.6))
		if kind=="city":
			var h:=2.8+float(posmod(seed,19))*0.14+(1.4 if cinematic and row>1 else 0.0)
			var w:=2.5+float(posmod(seed,5))*0.30
			var d:=2.8+float(posmod(seed,7))*0.21
			_building(district,at,ground_y,h,w,d,tone,seed)
			if GraphicsQuality.mode()>0:
				DistrictArchitecture.finish(district,at,ground_y,h,w,d,tone,seed)
		else:
			ExteriorMotifs.build(district,kind,Vector3(at.x,ground_y,at.y),tone,side,seed)
	MiniatureBatch.bake(district)
	_no_shadows(district)
	return district


static func _no_shadows(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			child.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_no_shadows(child)


static func _building(root: Node3D, at: Vector2, ground: float, h: float, w: float, d: float, tint: Color, seed: int) -> void:
	var c := TableSpace.to_world(at,ground+h*0.5)
	var stone := tint.darkened(float(posmod(seed,4))*0.07)
	var snow := tint.lightened(0.27)
	MiniatureFactory.box(root,c,Vector3(w,h,d),stone)
	# Distinct gables, stepped roofs and ruined turrets, in silhouette.
	match posmod(seed,5):
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
		2:
			# Crooked stepped gables over a narrow guild house.
			for i in 4:
				var step_width:=w*(1.0-float(i)*0.20)
				MiniatureFactory.box(root,c+Vector3(0,h*0.5+0.13+i*0.19,0),Vector3(step_width,0.24,d*0.82),snow.darkened(i*0.04))
		3:
			# An octagonal stair turret and collapsed side roof.
			var turret:=CylinderMesh.new()
			turret.top_radius=w*0.24
			turret.bottom_radius=w*0.29
			turret.height=h*0.85
			turret.radial_segments=8
			MiniatureFactory.mesh(root,turret,c+Vector3(w*0.39,h*0.16,d*0.25),stone.lightened(0.09))
			var cap:=CylinderMesh.new()
			cap.top_radius=0.025
			cap.bottom_radius=w*0.31
			cap.height=0.80
			cap.radial_segments=8
			MiniatureFactory.mesh(root,cap,c+Vector3(w*0.39,h*0.585+0.39,d*0.25),snow)
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


static func update_foreground(root: Node3D,camera: Vector3,size: Vector2) -> void:
	var center := Vector3(size.x*0.5,0,size.y*0.5)
	var offset := camera-center
	var low := camera.y < Vector2(offset.x,offset.z).length()*0.62
	for side in 4:
		var district := root.get_node_or_null("District%d"%side) as Node3D
		if district==null:
			continue
		var near := (side==0 and camera.z<0) or (side==1 and camera.x>size.x) or (side==2 and camera.z>size.y) or (side==3 and camera.x<0)
		district.visible=not (low and near)
