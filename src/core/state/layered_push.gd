class_name LayeredPush
extends RefCounted


static func destination(c: GameController,own: bool) -> Variant:
	var s := c.state
	var winner := s.figure(s.push_winner)
	var loser := s.figure(s.push_loser)
	if winner==null or loser==null or not winner.in_play() or not loser.in_play():
		return null
	if own and Contact.enemies_of(s.figures,winner).size()>1:
		return null
	var f := winner if own else loser
	var other := loser if own else winner
	var layout := FloorLayout.from_dict(s.board.floor_layout)
	var index := layout.index_of(f.surface_id)
	if index<0:
		return null
	var surface := layout.surfaces[index]
	var at := f.pos+(f.pos-other.pos).normalized()
	var node := layout.node(f.surface_id,at)
	# Keep the movement lattice; only allow snapped destinations close to 1 inch.
	if absf(layout.point(node).distance_to(f.pos)-1.0)>0.26:
		return null
	at=layout.point(node)
	for i in range(1,5):
		var p := f.pos.lerp(at,float(i)/4.0)
		var h := surface.height_at(p)
		if not surface.contains(p,Figure.BASE_RADIUS) or not layout.clearance(Vector3(p.x,h,p.y),Figure.BASE_RADIUS,1.6):
			return null
		for t in s.figures:
			if t!=f and t.in_play() and absf(t.elevation-h)<0.5 and t.pos.distance_to(p)<Contact.OVERLAP:
				return null
	return node


static func apply(c: GameController,own: bool) -> bool:
	var node: Variant = destination(c,own)
	if node==null:
		return false
	var s := c.state
	var f := s.figure(s.push_winner if own else s.push_loser)
	var other := s.figure(s.push_loser if own else s.push_winner)
	var layout := FloorLayout.from_dict(s.board.floor_layout)
	var from := Vector3(f.pos.x,f.elevation,f.pos.y)
	f.pos=layout.point(node)
	f.elevation=layout.height(node)
	f.disengaged[other.id]=f.pos.distance_to(other.pos)
	other.disengaged[f.id]=f.disengaged[other.id]
	c._displacement.clear()
	c.emit("layered_move",{"id":f.id,"path":PackedVector3Array([from,layout.world(node)]),"surfaces":[f.surface_id,f.surface_id],"cost":0.0})
	return true
