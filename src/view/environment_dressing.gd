class_name EnvironmentDressing
extends RefCounted
## Deterministic art-only dressing. Tall objects outside the table; surface
## scatter flush to open ground or within existing rough terrain footprints.
const SNOW := Color("c5d3da")
const STONE := Color("75858d")
const DIRT := Color("746d62")


static func build(board: Board,scenario: String) -> Node3D:
	var root := Node3D.new()
	root.name="EnvironmentDressing"
	if RealmScenery.special(scenario):
		return root
	var seed := absi(hash(board.id))
	var indoor := scenario=="underground_library"
	var snow := not indoor and scenario not in ["worm_hunts","red_king_bridge","red_king_ringworld"]
	# Low, irregular patches near existing architecture, never across ramps.
	for i in (42 if GraphicsQuality.mode()==0 else 76):
		var x := 0.75+float(posmod(seed+i*73,997))/997.0*(board.size.x-1.5)
		var z := 0.75+float(posmod(seed+i*137,991))/991.0*(board.size.y-1.5)
		var at := Vector2(x,z)
		var radius := 0.29+float(i%4)*0.09
		if not flat_ground(board,at,radius):
			continue
		if not near_edge_or_terrain(board,at):
			continue
		var y := board.ground_height_at(at)+0.022
		if i%4==0 and snow:
			EnvironmentProps.frost(root,Vector3(x,y,z),radius,i)
		elif i%3==0:
			EnvironmentProps.paving(root,Vector3(x,y,z),radius,i,DIRT if indoor else STONE)
		elif snow:
			EnvironmentVegetation.ground_cover(root,Vector3(x,y,z),i)
		elif indoor:
			EnvironmentProps.paving(root,Vector3(x,y,z),radius,i,Color("73665a"))
	for i in board.pieces.size():
		var piece := board.pieces[i]
		if piece.ramp or piece.cast_turn>=0:
			continue
		if piece.kind.id=="rubble" and minf(piece.rect.size.x,piece.rect.size.y)>=1.3:
			var c := piece.rect.get_center()
			var at := Vector3(c.x,board.ground_height_at(c),c.y)
			EnvironmentProps.ruin_debris(root,at,scenario,i,minf(0.92,minf(piece.rect.size.x,piece.rect.size.y)*0.48))
		elif piece.kind.id in ["ruin","hut_wall","tower","null_lower","null_middle","null_upper","null_annex"]:
			DistrictArchitecture.relief(root,piece,i,scenario)
		elif piece.kind.id=="haunted_floor":
			# Worn interior floorboards stay low and out of hut entrances.
			var center := piece.rect.get_center()
			for j in 3:
				var at := Vector2(center.x+(j-1)*0.65,center.y+0.85)
				EnvironmentProps.paving(root,Vector3(at.x,0.065,at.y),0.27,j,Color("63584d"))
	if snow and GraphicsQuality.mode()>0:
		SnowBanks.decorate(root,board,scenario)
	MiniatureBatch.bake(root)
	return root


static func flat_ground(board: Board,at: Vector2,radius: float) -> bool:
	var y := board.ground_height_at(at)
	for offset in [Vector2.ZERO,Vector2(-radius,-radius),Vector2(radius,-radius),Vector2(-radius,radius),Vector2(radius,radius)]:
		var p: Vector2=at+offset
		if not board.contains(p,0.1) or absf(board.ground_height_at(p)-y)>0.012:
			return false
		for piece in board.pieces:
			if piece.rect.grow(radius*0.15).has_point(p):
				if piece.ramp or not piece.kind.ground_surface:
					return false
	return true


static func near_edge_or_terrain(board: Board,at: Vector2) -> bool:
	if minf(minf(at.x,board.size.x-at.x),minf(at.y,board.size.y-at.y))<2.3:
		return true
	for piece in board.pieces:
		if not piece.kind.ground_surface and piece.rect.grow(1.2).has_point(at):
			return true
	return false


static func outskirts_side(root: Node3D,board: Board,scenario: String,y: float,side: int) -> void:
	if scenario in ["underground_library","training_yard"]:
		return
	var length := board.size.x if side%2==0 else board.size.y
	for i in 6:
		var u := (i+0.5)*length/6.0
		var gap := 4.5+float(posmod(i*7+side,5))*0.4
		var at := Vector2(u,-gap) if side==0 else (Vector2(board.size.x+gap,u) if side==1 else (Vector2(u,board.size.y+gap) if side==2 else Vector2(-gap,u)))
		var pos := Vector3(at.x,y,at.y)
		var seed := i*23+side*11
		if i%3==0:
			EnvironmentVegetation.tree(root,pos,seed,scenario!="mausoleum" and (i+side)%3==0)
		elif i%3==1:
			EnvironmentProps.landmark(root,pos,scenario,seed)
		else:
			EnvironmentVegetation.shrub(root,pos,seed)
