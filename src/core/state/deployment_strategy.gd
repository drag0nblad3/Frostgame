class_name DeploymentStrategy
extends RefCounted
## Cheap setup heuristics: proximity to objectives, cover and caster support.
static func score(s: GameState,f: Figure,at: Vector2,height: float,caster: Variant,draft: Dictionary) -> float:
	var center:=s.board.size*0.5
	var nearest:=at.distance_to(center)
	for token in s.treasures:
		if token.on_ground() and not token.frozen:
			nearest=minf(nearest,at.distance_to(token.pos))
	var value:=-nearest*0.28
	var cover:=0.0
	for piece in s.board.pieces:
		if piece.kind.blocks_los and not piece.kind.ground_surface:
			var d:=Geom.point_rect_distance(at,piece.rect)
			cover=maxf(cover,maxf(0.0,3.0-d)*0.35)
	value+=cover*(1.25 if f.ranged!=null or f.def.role!="soldier" else 0.7)
	if caster!=null:
		var d:=at.distance_to(caster)
		value+=1.8 if d<=4.0 else -d*0.18
	if f.ranged!=null:
		value+=height*0.3
	for id: int in draft:
		var other:=s.figure(id)
		if other==null or other.side==f.side:
			continue
		var p: Dictionary=draft[id]
		var pos: Vector2=p["at"]
		if at.distance_to(pos)>26.0:
			continue
		var visible: bool
		if s.board.floor_layout.is_empty():
			visible=LineOfSight.check(s.board,at,pos).clear
		else:
			visible=LineOfSight.floor_ray(s.board,s.board.floor_geometry(),Vector3(at.x,height+1.5,at.y),Vector3(pos.x,float(p["height"])+1.0,pos.y),null,false)
		if visible:
			value-=2.5
	return value
