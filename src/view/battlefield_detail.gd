class_name BattlefieldDetail
extends RefCounted
## Readable tabletop dressing, distinct from rules geometry. Ground inlays
## follow the authored surface; no collision shapes or extra rules terrain.
const STONE := Color("8c999b")
const IRON := Color("515b60")
const WOOD := Color("806047")


static func build(root: Node3D,board: Board,scenario: String) -> void:
	# Mindscape is explicitly terrain-free. Other planar maps keep the
	# bridge, gaps and movement boundaries entirely unobstructed.
	if scenario=="red_king_mind":
		return
	for piece in board.pieces:
		if piece.kind.ground_surface and piece.cast_turn<0:
			profile(root,board,piece)
	if RealmScenery.special(scenario):
		return
	# Small inset street/courtyard details, never simulated as cover.
	# A fixed budget controls draw calls and generation cost.
	var count:=32 if GraphicsQuality.mode()==0 else 60
	var seed:=absi(hash(scenario))
	for i in count:
		var p:=Vector2(1.5+float(posmod(seed+i*137,997))/997.0*(board.size.x-3.0),1.5+float(posmod(seed+i*293,991))/991.0*(board.size.y-3.0))
		if not EnvironmentDressing.flat_ground(board,p,0.65) or board.over_void(p,0.65):
			continue
		if not EnvironmentDressing.near_edge_or_terrain(board,p):
			continue
		var y:=board.ground_height_at(p)+0.025
		var at:=Vector3(p.x,y,p.y)
		match scenario:
			"underground_library":
				inlay(root,at,Color("a18b6b"),i,true)
			"complex_temple","living_museum","mausoleum","red_king_back_into_fire":
				inlay(root,at,Color("a2957a"),i,false)
			"haunted_houses","red_king_squatter","red_king_investigations":
				boards(root,at,i)
			"worm_hunts":
				scar(root,at,i,Color("899ca5"))
			_:
				if i%3==0:
					drain(root,at,i)
				elif i%3==1:
					boards(root,at,i)
				else:
					scar(root,at,i,Color("89989f"))


static func _quad(root: Node3D,points: PackedVector3Array,tint: Color) -> void:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in [0,1,2,0,2,3,2,1,0,3,2,0]:
		surface.add_vertex(points[i])
	surface.generate_normals()
	var node:=MiniatureFactory.mesh(root,surface.commit(),Vector3.ZERO,tint)
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func profile(root: Node3D,board: Board,p: TerrainPiece) -> void:
	var r:=p.rect
	if p.ramp:
		# Dark horizontal tread edges sit flush to the *continuous* legal
		# slope. No fictitious step lip or obstacle is introduced.
		var length:=r.size.y if p.ramp_rotated else r.size.x
		var width:=r.size.x if p.ramp_rotated else r.size.y
		var steps:=maxi(2,roundi(length/(0.48 if p.kind.stairs else 1.1)))
		for i in range(1,steps):
			var u:=length*float(i)/steps
			var a:=r.position+(Vector2(0.08,u-0.035) if p.ramp_rotated else Vector2(u-0.035,0.08))
			var b:=r.position+(Vector2(width-0.08,u+0.035) if p.ramp_rotated else Vector2(u+0.035,width-0.08))
			_surface_rect(root,board,Rect2(a,b-a),Color("53646b") if p.kind.stairs else Color("909c9b"))
		# Pale edge inlay guides the eye from the upper to the lower road.
		for side: float in [0.06,width-0.12]:
			var start:=r.position+(Vector2(side,0.07) if p.ramp_rotated else Vector2(0.07,side))
			var extent:=Vector2(0.06,length-0.14) if p.ramp_rotated else Vector2(length-0.14,0.06)
			_surface_rect(root,board,Rect2(start,extent),Color("b3ad92"))
	else:
		# Surface perimeter gives elevated terraces and ditch floors an
		# explicit silhouette even at a distant mobile camera.
		for side in 4:
			var start:=r.position
			var extent:=Vector2(r.size.x-0.12,0.055) if side%2==0 else Vector2(0.055,r.size.y-0.12)
			start+=Vector2(0.06,0.06)
			if side==1:
				start.x=r.end.x-0.115
			elif side==2:
				start.y=r.end.y-0.115
			_surface_rect(root,board,Rect2(start,extent),Color("b3b4ac") if p.surface_height(r.get_center())>0 else Color("70858e"))


static func _surface_rect(root: Node3D,board: Board,r: Rect2,tint: Color) -> void:
	var pts:=PackedVector3Array()
	for at: Vector2 in [r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]:
		if board.over_void(at):
			return
		pts.append(TableSpace.to_world(at,board.ground_height_at(at)+0.034))
	_quad(root,pts,tint)


static func inlay(root: Node3D,at: Vector3,tint: Color,seed: int,square: bool) -> void:
	# Broken stone mosaic, confined to a low, flat disc.
	for i in 6:
		var angle:=TAU*i/6.0+seed*0.2
		var offset:=Vector3(cos(angle)*0.23,0,sin(angle)*0.23)
		var tile:=MiniatureFactory.box(root,at+offset,Vector3(0.18,0.016,0.24),tint.darkened((i%3)*0.12))
		tile.rotation.y=angle if not square else 0.0


static func boards(root: Node3D,at: Vector3,seed: int) -> void:
	for i in 3:
		var board:=MiniatureFactory.box(root,at+Vector3(0,0,(i-1)*0.13),Vector3(0.72-float(i)*0.12,0.025,0.095),WOOD.lightened(i*0.09))
		board.rotation.y=0.32*sin(seed+i)


static func scar(root: Node3D,at: Vector3,seed: int,tint: Color) -> void:
	for i in 3:
		var stone:=MiniatureFactory.sphere(root,at+Vector3((i-1)*0.17,0,(i%2)*0.10),Vector3(0.36,0.035,0.14),tint.lightened(i*0.07))
		stone.rotation.y=seed*0.23+i*0.36


static func drain(root: Node3D,at: Vector3,seed: int) -> void:
	MiniatureFactory.cylinder(root,at,0.30,0.30,0.018,STONE)
	MiniatureFactory.cylinder(root,at+Vector3.UP*0.011,0.24,0.24,0.018,IRON.darkened(0.15))
	for i in 4:
		MiniatureFactory.box(root,at+Vector3((i-1.5)*0.10,0.025,0),Vector3(0.025,0.018,0.32),IRON.lightened(0.2))


## Varied objects within an existing rough-ground rectangle. These shapes
## deliberately stay below the terrain's 0.4-inch nominal height.
static func rubble(root: Node3D,p: TerrainPiece,scenario: String) -> void:
	var r:=p.rect
	var c:=r.get_center()
	var seed:=absi(hash(str(r.position)+scenario))
	var width:=minf(r.size.x,r.size.y)
	var variant:=posmod(seed,5)
	if scenario=="underground_library":
		variant=0
	elif scenario in ["complex_temple","living_museum","mausoleum","red_king_back_into_fire"]:
		variant=1
	elif scenario in ["haunted_houses","red_king_squatter","red_king_investigations"]:
		variant=2
	var scale:=minf(1.0,width/1.6)
	var origin:=Vector3(c.x,0,c.y)
	match variant:
		0: # Tumbled books and ledgers.
			for i in 5:
				var b:=MiniatureFactory.box(root,origin+Vector3((i%3-1)*0.24,0.065+(i/3)*0.05,(i%2-0.5)*0.35)*scale,Vector3(0.38,0.09,0.26)*scale,Color("917251").lerp(Color("50637b"),float(i%3)/2.0))
				b.rotation.y=seed*0.01+i*0.48
		1: # Broken columns, cylindrical drums and a toppled carved capital.
			var shaft:=MiniatureFactory.cylinder(root,origin+Vector3.UP*0.16*scale,0.13*scale,0.15*scale,0.8*scale,STONE)
			shaft.rotation.z=PI*0.5
			for side: float in [-1.0,1.0]:
				var cap:=MiniatureFactory.cylinder(root,origin+Vector3(side*0.34,0.17,0)*scale,0.18*scale,0.18*scale,0.10*scale,STONE.lightened(0.15))
				cap.rotation.z=PI*0.5
		2: # Split timbers and broken wheel.
			for i in 3:
				var beam:=MiniatureFactory.box(root,origin+Vector3(0,0.07+i*0.07,(i-1)*0.18)*scale,Vector3(0.83,0.09,0.12)*scale,WOOD.darkened(i*0.10))
				beam.rotation.y=i*0.7
			var ring:=TorusMesh.new()
			ring.inner_radius=0.20*scale
			ring.outer_radius=0.28*scale
			var wheel:=MiniatureFactory.mesh(root,ring,origin+Vector3(0.35,0.06,0.32)*scale,IRON)
			wheel.scale.y=0.4
		3: # Torn crates, dented metal and discarded sacks.
			for i in 3:
				var bag:=MiniatureFactory.sphere(root,origin+Vector3((i-1)*0.25,0.12,0.13*sin(i))*scale,Vector3(0.38,0.23,0.28)*scale,Color("968477").darkened(i*0.1))
				bag.rotation.y=i*0.6
			var lid:=MiniatureFactory.box(root,origin+Vector3(0,0.08,-0.30)*scale,Vector3(0.52,0.09,0.30)*scale,WOOD)
			lid.rotation.y=0.35
		_: # Fractured statue fragments among the stone.
			MiniatureFactory.sphere(root,origin+Vector3(-0.24,0.15,0)*scale,Vector3(0.31,0.30,0.32)*scale,STONE)
			var plinth:=MiniatureFactory.cylinder(root,origin+Vector3(0.20,0.10,0.16)*scale,0.22*scale,0.26*scale,0.17*scale,STONE.darkened(0.14))
			plinth.rotation.y=0.7
	# Low angular debris across each footprint; no decorative object's
	# center/extent extends outside its original rough-ground patch.
	var count:=clampi(roundi(r.get_area()*1.6),3,20)
	for i in count:
		var x:=lerpf(r.position.x+width*0.15,r.end.x-width*0.15,float(posmod(seed+i*37,97))/97.0)
		var z:=lerpf(r.position.y+width*0.15,r.end.y-width*0.15,float(posmod(seed+i*61,89))/89.0)
		var s:=minf(0.32,width*0.18)
		var stone:=MiniatureFactory.sphere(root,Vector3(x,0.075,z),Vector3(s*(1.0+0.2*(i%2)),0.12,s*0.86),STONE.darkened(float(i%5)*0.08))
		stone.rotation.y=i*0.63


## Solid, sealed exterior relief: no fake doors or traversable holes.
static func facade(root: Node3D,p: TerrainPiece,scenario: String) -> void:
	if p.kind.id!="ruin" or p.ramp or p.circular or p.level!=null:
		return
	wall_relief(root,p.rect,p.kind.height,scenario)


## Shared architectural relief for exposed terrain and stacked solid volumes.
static func wall_relief(root: Node3D,r: Rect2,h: float,scenario: String) -> void:
	if h<1.7:
		return
	var seed:=absi(hash(str(r.position)+scenario))
	var style:=seed%4
	if scenario in ["mausoleum","complex_temple","living_museum","red_king_back_into_fire"]:
		style=1
	var color:=Color("a1aaab").lerp(Color("aa9279"),float(style)/4.0)
	for side in 4:
		var span:=r.size.x if side%2==0 else r.size.y
		if span<1.6:
			continue
		var position:=Vector3(r.get_center().x,h*0.56,r.position.y-0.025) if side==0 else (Vector3(r.end.x+0.025,h*0.56,r.get_center().y) if side==1 else (Vector3(r.get_center().x,h*0.56,r.end.y+0.025) if side==2 else Vector3(r.position.x-0.025,h*0.56,r.get_center().y)))
		var face:=Node3D.new()
		root.add_child(face)
		face.position=position
		face.rotation.y=PI*0.5*side
		if style==0:
			# Sealed rose-window stone tracery.
			var ring:=TorusMesh.new()
			ring.inner_radius=0.35
			ring.outer_radius=0.44
			var medallion:=MiniatureFactory.mesh(face,ring,Vector3.ZERO,color)
			medallion.rotation.x=PI*0.5
			medallion.scale.y=0.13
			for i in 4:
				var bar:=MiniatureFactory.box(face,Vector3.ZERO,Vector3(0.65,0.065,0.025),color.darkened(0.1))
				bar.rotation.z=i*PI/4.0
		elif style==1:
			# Circular relief and half columns against the solid facade.
			for x: float in [-0.52,0.52]:
				MiniatureFactory.cylinder(face,Vector3(x,0,0),0.10,0.10,1.25,color)
				MiniatureFactory.box(face,Vector3(x,0.60,0),Vector3(0.24,0.11,0.07),color.lightened(0.12))
			var crest:=MiniatureFactory.cylinder(face,Vector3.ZERO,0.28,0.28,0.045,color.darkened(0.15))
			crest.rotation.x=PI*0.5
		elif style==2:
			# Remnants of a timber cross-brace.
			for sign_value: float in [-1.0,1.0]:
				var brace:=MiniatureFactory.box(face,Vector3.ZERO,Vector3(1.05,0.13,0.035),WOOD)
				brace.rotation.z=sign_value*0.72
		else:
			# Dark carved shield plaques.
			var shield:=MiniatureFactory.sphere(face,Vector3.ZERO,Vector3(0.58,0.82,0.055),IRON)
			shield.rotation.z=0.10
			MiniatureFactory.box(face,Vector3(0,0,0.035),Vector3(0.07,0.66,0.025),color)
		MiniatureBatch.bake(face)
