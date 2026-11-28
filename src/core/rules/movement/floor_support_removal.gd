class_name FloorSupportRemoval
extends RefCounted
## One disappearing-support pipeline for bridges, walls and hanging figures.

static func removed(surface: String,id: String) -> bool:
	return surface==id or surface.begins_with("climb:"+id+":")


## Derived climb IDs may disappear when architecture changes. Reconcile
## only occupied missing routes, without touching surviving hanging figures.
static func reconcile(c: GameController,before: FloorLayout) -> void:
	var after:=c.state.board.floor_geometry()
	var lost: Array[String]=[]
	for f in c.state.figures:
		if f.in_play() and f.surface_id.begins_with("climb:auto:") and before.index_of(f.surface_id)>=0 and after.index_of(f.surface_id)<0 and not lost.has(f.surface_id):
			lost.append(f.surface_id)
	for token in c.state.treasures:
		if token.on_ground() and token.surface_id.begins_with("climb:auto:") and before.index_of(token.surface_id)>=0 and after.index_of(token.surface_id)<0 and not lost.has(token.surface_id):
			lost.append(token.surface_id)
	for id in lost:
		resolve(c,before,id)


static func resolve(c: GameController,before: FloorLayout,id: String) -> void:
	var s:=c.state
	for p in s.board.pieces.duplicate():
		if removed(p.surface_id,id):
			c._magic.terrain.remove(p)
	var layout:=s.board.floor_geometry()
	for f in s.figures:
		if not f.in_play() or not removed(f.surface_id,id):
			continue
		var n: Variant=LayeredFall.landing(layout,LayeredGrid.new(layout,f,s.figures),f.pos,f.elevation+0.002)
		if n==null:
			# No legal lower support. Do not leave a dropped token floating.
			for token_id in f.carried_treasures():
				c._loot.lose(s.treasure(token_id))
			c._hurt(f,f.health,f,false)
			continue
		var old:=f.elevation
		f.pos=layout.point(n)
		f.surface_id=layout.surface_id(n)
		f.elevation=layout.height(n)
		c.emit("terrain_fall",{"id":f.id})
		LayeredFall.apply(c,f,old-f.elevation,f)
		if f.in_play():
			ScenarioNull.enter(c,f)
			c._magic.terrain.trigger_landing(f)
	for token in s.treasures:
		if not token.on_ground() or not removed(token.surface_id,id):
			continue
		var index:=before.index_of(token.surface_id)
		if index<0:
			c._loot.lose(token)
			continue
		var above:=before.surfaces[index].height_at(token.pos)
		var n: Variant=LayeredFall.treasure_landing(s,token.pos,above+0.002)
		if n==null:
			c._loot.lose(token)
		else:
			c._loot.relocate_ground(token,layout.point(n),layout.surface_id(n))
