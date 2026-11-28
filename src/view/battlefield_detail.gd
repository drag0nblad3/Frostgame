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
	# Irregular clustered masonry, tile shards, splintered wood and snow.
	# Bounding radii are clamped before placement; height remains <= 0.4.
	var rng := RandomNumberGenerator.new()
	rng.seed=seed
	var count:=clampi(roundi(r.get_area()*2.0),4,26)
	var cluster:=c+Vector2(rng.randf_range(-0.18,0.18),rng.randf_range(-0.18,0.18))*width
	for i in count:
		var radius:=minf(width*0.16,rng.randf_range(0.07,0.23))
		var at:=cluster+Vector2(rng.randfn(0,width*0.27),rng.randfn(0,width*0.27))
		at.x=clampf(at.x,r.position.x+radius,r.end.x-radius)
		at.y=clampf(at.y,r.position.y+radius,r.end.y-radius)
		var height:=rng.randf_range(0.035,0.16)
		var tint:=STONE.lerp(Color("655b50"),rng.randf_range(0.0,0.55)).lightened(rng.randf_range(0.0,0.14))
		var pos:=TableSpace.to_world(at,height*0.5)
		var shard: MeshInstance3D
		match rng.randi_range(0,3):
			0:
				var wedge:=PrismMesh.new()
				wedge.size=Vector3(radius*1.5,height,radius*0.95)
				shard=MiniatureFactory.mesh(root,wedge,pos,tint)
			1:
				shard=MiniatureFactory.box(root,pos,Vector3(radius*1.4,height,radius*0.9),tint)
			2:
				shard=MiniatureFactory.sphere(root,pos,Vector3(radius*1.8,height,radius*1.0),tint)
			_:
				shard=MiniatureFactory.box(root,pos,Vector3(radius*1.7,height*0.55,radius*0.5),WOOD.darkened(0.18))
		shard.rotation.y=rng.randf_range(0,TAU)
		if i%4==0 and not RealmScenery.special(scenario):
			MiniatureFactory.sphere(root,pos+Vector3.UP*(height*0.5+0.008),Vector3(radius*1.25,0.022,radius*0.85),Color("c9d6d9"))


## Solid, sealed exterior relief: no fake doors or traversable holes.
static func facade(root: Node3D,p: TerrainPiece,scenario: String) -> void:
	if p.kind.id not in ["ruin","tower","hut_wall","null_annex","null_lower","null_middle","null_upper"] or p.ramp or p.circular or p.level!=null:
		return
	wall_relief(root,p.rect,p.kind.height,scenario)


## Shared architectural relief for exposed terrain and stacked solid volumes.
static func wall_relief(root: Node3D,r: Rect2,h: float,scenario: String) -> void:
	if h<1.7:
		return
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash(str(r.position)+str(r.size)+scenario)
	var style:=rng.randi_range(0,3)
	if scenario in ["mausoleum","complex_temple","living_museum","red_king_back_into_fire"]:
		style=1
	elif scenario in ["haunted_houses","red_king_squatter"]:
		style=2
	elif scenario=="silent_tower":
		style=3
	var color:=Color("a1aaab").lerp(Color("aa9279"),float(style)/4.0)
	for side in 4:
		var span:=r.size.x if side%2==0 else r.size.y
		if span<1.0:
			continue
		var center:=r.get_center()
		var position:=Vector3(center.x,0,r.position.y) if side==0 else (Vector3(r.end.x,0,center.y) if side==1 else (Vector3(center.x,0,r.end.y) if side==2 else Vector3(r.position.x,0,center.y)))
		var face:=Node3D.new()
		root.add_child(face)
		face.position=position
		face.rotation.y=-PI*0.5*side
		var bays:=clampi(floori(span/1.8),1,4)
		var bay:=span/float(bays)
		var floors:=clampi(floori(h/2.1),1,3)
		# Broken masonry courses and uneven corner quoins.
		for edge: float in [-1.0,1.0]:
			for i in range(clampi(floori(h/0.42),2,12)):
				if rng.randf()<0.18:
					continue
				var w:=minf(span*0.18,0.22 if i%2==0 else 0.34)
				var y:=0.22+i*0.42
				if y+0.12>h-0.08:
					continue
				MiniatureFactory.box(face,Vector3(edge*(span*0.5-w*0.55),y,-0.025),Vector3(w,0.23,0.055),color.darkened(rng.randf_range(0.10,0.32)))
		for floor_index in floors:
			var y0:=float(floor_index)*h/floors
			var fh:=h/floors
			for i in bays:
				var x:=(i+0.5)*bay-span*0.5
				var w:=minf(bay*0.31,0.43)
				var y:=y0+fh*0.50
				var rise:=minf(fh*0.28,0.60)
				if rng.randf()<0.14:
					continue
				if style==2:
					# Timber framing and infill, never a false door.
					MiniatureFactory.box(face,Vector3(x,y,-0.026),Vector3(0.10,rise*2.0,0.06),WOOD.darkened(0.14))
					var beam:=MiniatureFactory.box(face,Vector3(x,y,-0.030),Vector3(w*1.55,0.075,0.06),WOOD)
					beam.rotation.z=0.58 if (i+floor_index)%2==0 else -0.58
				elif style==3:
					# Narrow blocked lancet and layered lintel, in dark tower stone.
					MiniatureFactory.box(face,Vector3(x,y,-0.016),Vector3(w*0.65,rise*1.25,0.036),color.darkened(0.48))
					for s: float in [-1.0,1.0]:
						var stone:=MiniatureFactory.box(face,Vector3(x+s*w*0.31,y+rise*0.68,-0.032),Vector3(w*0.76,0.095,0.075),color)
						stone.rotation.z=-s*0.65
					MiniatureFactory.box(face,Vector3(x,y-rise*0.72,-0.035),Vector3(w*1.16,0.10,0.08),color)
				else:
					# Arched blind relief assembled from individual voussoirs.
					var radius:=w*0.83
					var spring:=y+rise*0.10
					var leg:=rise*0.85
					for s: float in [-1.0,1.0]:
						MiniatureFactory.box(face,Vector3(x+s*radius,spring-leg*0.5,-0.028),Vector3(0.13,leg,0.065),color.darkened(0.12))
						MiniatureFactory.box(face,Vector3(x+s*radius,spring-leg,-0.033),Vector3(0.22,0.095,0.075),color)
					for segment in 5:
						if style==0 and rng.randf()<0.12:
							continue
						var a:=PI*(segment+0.5)/5.0
						var block:=MiniatureFactory.box(face,Vector3(x+cos(a)*radius,spring+sin(a)*radius,-0.032),Vector3(radius*0.60,0.13,0.075),color.darkened(rng.randf_range(0.0,0.19)))
						block.rotation.z=a+PI*0.5
					if style==1:
						MiniatureFactory.box(face,Vector3(x,y-rise*0.66,-0.035),Vector3(w*2.1,0.10,0.08),color)
				# A few damaged sill fragments; asymmetrical, shallow relief.
				if rng.randf()<0.35:
					MiniatureFactory.box(face,Vector3(x+w*0.35,y-rise,-0.024),Vector3(w*0.65,0.08,0.06),color.darkened(0.25))
		MiniatureBatch.bake(face)
