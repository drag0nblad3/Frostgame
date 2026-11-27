class_name LayeredPush
extends RefCounted


static func destination(c: GameController,own: bool,distance: float=1.0) -> Variant:
	var s := c.state
	if not CombatDisplacement.distance_allowed(s,own,distance):
		return null
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
	var grid := LayeredGrid.new(layout,f,s.figures)
	var at := f.pos+(f.pos-other.pos).normalized()*distance
	var node := layout.node(f.surface_id,at)
	# Keep the movement lattice; only allow snapped destinations close to 1 inch.
	if absf(layout.point(node).distance_to(f.pos)-distance)>0.26:
		return null
	at=layout.point(node)
	var steps := maxi(4,ceili(f.pos.distance_to(at)*4.0))
	for i in range(1,steps+1):
		var p := f.pos.lerp(at,float(i)/steps)
		var h := surface.height_at(p)
		if not layout.clearance(Vector3(p.x,h,p.y),Figure.BASE_RADIUS,1.6):
			return null
		for t in s.figures:
			if t!=f and t.in_play() and absf(t.elevation-h)<0.5 and t.pos.distance_to(p)<Contact.OVERLAP:
				return null
	if layout.contains(node):
		return node if grid.open(node) else null
	# Step off the ledge at the displaced horizontal position, then fall.
	return LayeredFall.landing(layout,grid,at,f.elevation)


static func apply(c: GameController,own: bool,distance: float=1.0) -> bool:
	var node: Variant = destination(c,own,distance)
	if node==null:
		return false
	var s := c.state
	var f := s.figure(s.push_winner if own else s.push_loser)
	var other := s.figure(s.push_loser if own else s.push_winner)
	var layout := FloorLayout.from_dict(s.board.floor_layout)
	var from := Vector3(f.pos.x,f.elevation,f.pos.y)
	var old_surface := f.surface_id
	f.pos=layout.point(node)
	f.elevation=layout.height(node)
	f.surface_id=layout.surface_id(node)
	f.disengaged[other.id]=f.pos.distance_to(other.pos)
	other.disengaged[f.id]=f.disengaged[other.id]
	c._displacement.clear()
	var path := PackedVector3Array([from])
	if from.y>f.elevation+0.001:
		path.append(Vector3(f.pos.x,from.y,f.pos.y))
	path.append(layout.world(node))
	c.emit("layered_move",{"id":f.id,"path":path,"surfaces":[old_surface,f.surface_id],"cost":0.0})
	LayeredFall.apply(c,f,from.y-f.elevation,other)
	ScenarioNull.enter(c,f)
	return true
