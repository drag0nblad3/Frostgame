class_name BodySight
extends RefCounted
## Core pp.57–58: sight to the head or torso, not the base or weapon tip.
## Use a deterministic proxy body on every geometry provider. The five aim
## samples deliberately omit legs and equipment; actual model meshes vary.
static func samples(origin: Vector3,target: Figure) -> PackedVector3Array:
	var center:=BattleSpace.center(target)
	var lateral:=Vector2(center.x-origin.x,center.z-origin.z).normalized().orthogonal()
	var large:=target.def.traits.has("large")
	var scale_factor:=1.5 if large else 1.0
	var wing:=Vector3(lateral.x,0,lateral.y)*0.3*scale_factor
	var torso:=center+Vector3.UP*1.0*scale_factor
	return PackedVector3Array([torso,center+Vector3.UP*1.5*scale_factor,torso+wing,torso-wing,center+Vector3.UP*0.65*scale_factor])

static func ray(board: Board,a: Vector3,b: Vector3,observer: Figure) -> bool:
	if not board.floor_layout.is_empty():
		return LineOfSight.floor_ray(board,board.floor_geometry(),a,b,observer)
	var from:=Vector2(a.x,a.z)
	var to:=Vector2(b.x,b.z)
	if BattleBoundary.blocks_segment(board.boundaries,from,to,"sight",observer):
		return false
	if board.darkness and a.distance_to(b)>12.0:
		return false
	if board.has_ground_profiles and board.ground_max>minf(a.y,b.y):
		var steps:=maxi(1,ceili(from.distance_to(to)*4.0))
		for i in range(1,steps):
			var t:=float(i)/steps
			if board.ground_height_at(from.lerp(to,t))>lerpf(a.y,b.y,t)+0.001:
				return false
	for p in board.pieces:
		if p.kind.id in ["red_king_portal","red_king_sinkhole_orb","reality_portal","reality_hoof"]:
			var center:=p.rect.get_center()
			if center.distance_to(Geometry2D.get_closest_point_to_segment(center,from,to))<=p.rect.size.x*0.5:
				return false
			continue
		if p.kind.ground_surface or not p.kind.blocks_los:
			continue
		var base:=board.ground_height_at(p.rect.get_center())
		var volume:=AABB(Vector3(p.rect.position.x,base,p.rect.position.y),Vector3(p.rect.size.x,p.kind.height,p.rect.size.y))
		if LayeredSight.intersects(a,b,volume):
			return false
	return true

static func fallback(board: Board,observer: Figure,feet: Vector3,target: Figure,result: LineOfSight.Result) -> LineOfSight.Result:
	if result.clear:
		return result
	var origin:=feet+Vector3.UP*(2.25 if observer.def.traits.has("large") else 1.5)
	for aim in samples(origin,target):
		if ray(board,origin,aim,observer):
			result.clear=true
			return result
	return result

## A contacted terrain piece is cover, not intervening terrain. Classify
## solid cover by sampled body obstruction; retain light soft-cover semantics.
static func cover(board: Board,observer: Figure,feet: Vector3,target: Figure,result: LineOfSight.Result) -> void:
	if not result.clear:
		return
	var origin:=feet+Vector3.UP*(2.25 if observer.def.traits.has("large") else 1.5)
	var from:=Vector2(feet.x,feet.z)
	var aims:=samples(origin,target)
	result.cover=0
	result.intervening=0
	for p in board.pieces:
		if p.kind.ground_surface or (p.kind.cover==0 and not p.kind.blocks_los):
			continue
		var base:=p.base_height if not board.floor_layout.is_empty() else board.ground_height_at(p.rect.get_center())
		var volume:=AABB(Vector3(p.rect.position.x,base,p.rect.position.y),Vector3(p.rect.size.x,p.kind.height,p.rect.size.y))
		var blocked:=0
		for aim in aims:
			if LayeredSight.intersects(origin,aim,volume):
				blocked+=1
		# Low terrain counts when the direct table footprint crosses it,
		# even when the ray passes over it (intervening terrain rule).
		var footprint:=Geom.clip(from,target.pos,p.rect).size()==2
		var target_contact:=Geom.point_rect_distance(target.pos,p.rect)<=Figure.BASE_RADIUS+0.01 and absf(target.elevation-base)<0.5
		var shooter_contact:=Geom.point_rect_distance(from,p.rect)<=Figure.BASE_RADIUS+0.01 and absf(feet.y-base)<0.5
		if target_contact and (blocked>0 or (footprint and p.kind.cover>0)):
			var classification:=TerrainKind.Cover.LIGHT
			if (p.kind.blocks_los or p.kind.cover==TerrainKind.Cover.HEAVY) and blocked>=4:
				classification=TerrainKind.Cover.HEAVY
			result.cover=maxi(result.cover,classification)
		elif not shooter_contact and (blocked>0 or (footprint and p.kind.cover>0 and absf(feet.y-base)<0.5 and absf(target.elevation-base)<0.5)):
			result.intervening+=1
