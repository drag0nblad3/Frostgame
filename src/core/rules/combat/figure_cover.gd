class_name FigureCover
extends RefCounted
## Core p.58: figures intervening along a shot contribute +1, or light
## cover when touching the target. Figures touching the shooter are exempt.
## Use physical height, not projected overlap on a different storey.

static func apply(board: Board, shooter: Figure, target: Figure, origin: Vector3, los: LineOfSight.Result) -> void:
	if shooter.battle_ref==null:
		return
	var s: GameState=shooter.battle_ref.get_ref()
	if s==null or s.board!=board:
		return
	var from:=Vector2(origin.x,origin.z)
	var delta:=target.pos-from
	var length_squared:=delta.length_squared()
	if length_squared<0.001:
		return
	for f in s.figures:
		if f==shooter or f==target or not f.in_play() or f.ring_side!=target.ring_side:
			continue
		var along:=(f.pos-from).dot(delta)/length_squared
		if along<=0.0 or along>=1.0:
			continue
		var closest:=from+delta*along
		if closest.distance_to(f.pos)>Figure.BASE_RADIUS+0.001:
			continue
		var h:=lerpf(origin.y,target.elevation+1.0,along)
		var body:=2.4 if f.def.traits.has("large") else 1.6
		if h<f.elevation or h>f.elevation+body:
			continue
		var contact_distance:=2.0*Figure.BASE_RADIUS+0.01
		if from.is_equal_approx(shooter.pos) and absf(f.elevation-shooter.elevation)<0.5 and f.pos.distance_to(shooter.pos)<=contact_distance:
			continue
		if absf(f.elevation-target.elevation)<0.5 and f.pos.distance_to(target.pos)<=contact_distance:
			los.cover=maxi(los.cover,TerrainKind.Cover.LIGHT)
		else:
			los.intervening+=1
