class_name FigureScreening
extends RefCounted
## Core p.58: figures between shooter and target provide intervening cover.
## A contact screen is light cover; actual miniature silhouettes vary.


static func apply(board:Board,from:Figure,at:Vector3,to:Figure,result:LineOfSight.Result) -> void:
	if not result.clear or from.battle_ref==null or board.reality_sphere or RealityCrackGeometry.cross_relation(board,Vector2(at.x,at.z),to.pos)!=0:
		return
	var state:GameState=from.battle_ref.get_ref()
	if state==null:
		return
	var a:=Vector2(at.x,at.z)
	var b:=to.pos
	var ray:=b-a
	if ray.length_squared()<0.001:
		return
	for other in state.figures:
		if other==from or other==to or not other.in_play() or other.ring_side!=from.ring_side or other.spell_effects.has("plane_walk"):
			continue
		var t:float=(other.pos-a).dot(ray)/ray.length_squared()
		if t<=0.0 or t>=1.0 or other.pos.distance_to(a+ray*t)>Figure.BASE_RADIUS:
			continue
		var height:=lerpf(at.y+1.5,to.elevation+1.0,t)
		if height<other.elevation or height>other.elevation+1.6:
			continue
		if other.pos.distance_to(b)<=2.0*Figure.BASE_RADIUS+0.01 and absf(other.elevation-to.elevation)<0.5:
			result.cover=maxi(result.cover,TerrainKind.Cover.LIGHT)
		elif other.pos.distance_to(a)>2.0*Figure.BASE_RADIUS+0.01 or absf(other.elevation-at.y)>=0.5:
			result.intervening+=1
