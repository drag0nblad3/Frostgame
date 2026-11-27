class_name TreasureMagic
extends RefCounted

var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func can_target(f: Figure, id: String, token: TreasureToken) -> bool:
	var s := c.state
	if token.ring_side!=f.ring_side or RedKingHill.guarded(s,token) or token.investigation or not token.unresolved() or token.frozen or ScenarioSites.treasure_protected(s, origin(token)):
		return false
	if id=="telekinesis" and not s.board.floor_layout.is_empty():
		var at:=origin_world(token)
		return token.on_ground() and not s.museum and (not token.central or token.ever_collected) and LineOfSight.floor_point_visible(s.board,s.board.floor_geometry(),f,at,16.0)
	if id == "telekinesis":
		return token.on_ground() and not s.museum and (not token.central or token.ever_collected) and Vector2(f.pos.distance_to(token.pos), f.elevation - s.board.height_at(token.pos)).length() <= 16.0 and WizardEye.visible(s.board, f, token.pos)
	if id == "fools_gold":
		var carrier := s.figure(token.carrier_id)
		return carrier != null and carrier.in_play() and IllusionRules.visible_to(s.figures, f, carrier) and LineOfSight.spell_visible(s.board,f,carrier)
	return false


func origin(token: TreasureToken) -> Vector2:
	var carrier := c.state.figure(token.carrier_id)
	return token.pos if carrier == null else carrier.pos


func origin_surface(token: TreasureToken) -> String:
	var carrier:=c.state.figure(token.carrier_id)
	return token.surface_id if carrier==null else carrier.surface_id


func origin_world(token: TreasureToken) -> Vector3:
	var carrier:=c.state.figure(token.carrier_id)
	if carrier!=null:
		return Vector3(carrier.pos.x,carrier.elevation,carrier.pos.y)
	var height:=c.state.board.height_at(token.pos)
	if not c.state.board.floor_layout.is_empty():
		var layout:=c.state.board.floor_geometry()
		var index:=layout.index_of(token.surface_id)
		if index>=0:
			height=layout.surfaces[index].height_at(token.pos)
	return Vector3(token.pos.x,height,token.pos.y)


func limit_for(f: Figure,id: String) -> float:
	return (3.0 if RedKingSinkhole.active(c.state) else 6.0) if id=="telekinesis" else (6.0 if SummonActions.illusion_staff(f) else 4.0)


func can_place_floor(f: Figure,id: String,token: TreasureToken,n: Vector3i) -> bool:
	if not can_target(f,id,token):
		return false
	var s:=c.state
	var layout:=s.board.floor_geometry()
	if not BattlePlacement.floor_open(s,n,null,TreasureRules.TOKEN_RADIUS,0.5) or ScenarioNull.field_at(s.board,layout.point(n)):
		return false
	var a:=origin_world(token)
	var b:=layout.world(n)
	if a.distance_to(b)>limit_for(f,id)+0.001 or not LineOfSight.floor_point_visible(s.board,layout,f,b):
		return false
	if id=="telekinesis":
		var steps:=maxi(2,ceili(a.distance_to(b)*4.0))
		for i in range(1,steps):
			var at:=a.lerp(b,float(i)/steps)
			if not LineOfSight.floor_point_visible(s.board,layout,f,at) or not layout.clearance(at,TreasureRules.TOKEN_RADIUS,0.5):
				return false
	return true


func floor_points(f: Figure,id: String,token: TreasureToken,first_only: bool=false,index: int=-1) -> Array[Vector3i]:
	var out: Array[Vector3i]=[]
	if not can_target(f,id,token):
		return out
	for n in BattlePlacement.nodes(c.state.board,origin(token),limit_for(f,id),index):
		if can_place_floor(f,id,token,n):
			out.append(n)
			if first_only:
				break
	return out


func apply_floor(f: Figure,id: String,token: TreasureToken,at: Vector2,surface: String,roll: int) -> void:
	var layout:=c.state.board.floor_geometry()
	var n:=layout.node(surface,at)
	if not can_place_floor(f,id,token,n):
		return
	if id=="fools_gold":
		var carrier:=c.state.figure(token.carrier_id)
		c._magic.resistance.attempt(carrier,roll,_drop_floor_result.bind(carrier,at,token.id,surface))
	else:
		c._loot.relocate_ground(token,at,surface)


func _drop_floor_result(success: bool,t: Figure,at: Vector2,token_id: int,surface: String) -> void:
	if not success and t.in_play() and t.carried_treasures().has(token_id):
		c._loot._drop(t,at,token_id,surface)


func can_place(f: Figure, id: String, token: TreasureToken, at: Vector2) -> bool:
	if not c.state.board.floor_layout.is_empty() or not can_target(f,id,token):
		return false
	var s := c.state
	var from := origin(token)
	var limit:=limit_for(f,id)
	if Vector2(from.distance_to(at), s.board.height_at(from) - s.board.height_at(at)).length() > limit + 0.001 or not s.board.can_stand(at, TreasureRules.TOKEN_RADIUS):
		return false
	if not WizardEye.visible(s.board, f, at):
		return false
	for t in s.figures:
		if t.in_play() and absf(t.elevation - s.board.height_at(at)) < 0.5 and t.pos.distance_to(at) < Figure.BASE_RADIUS + TreasureRules.TOKEN_RADIUS:
			return false
	if id == "telekinesis":
		for i in range(1, maxi(2, ceili(from.distance_to(at) * 4))):
			if not WizardEye.visible(s.board, f, from.lerp(at, float(i) / maxi(2, ceili(from.distance_to(at) * 4)))):
				return false
	return true


func points(f: Figure, id: String, token: TreasureToken, first_only: bool = false) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var center := MovePlanner.node_at(origin(token))
	var radius := 12 if id=="telekinesis" or SummonActions.illusion_staff(f) else 8
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var at := MoveGrid.to_pos(center + Vector2i(dx, dy))
			if can_place(f, id, token, at):
				out.append(at)
				if first_only:
					return out
	return out


func apply(f: Figure, id: String, token: TreasureToken, at: Vector2, roll: int) -> void:
	if id == "fools_gold":
		var t := c.state.figure(token.carrier_id)
		c._magic.resistance.attempt(t, roll, _drop_result.bind(t, at, token.id))
	else:
		ScenarioSites.discover(c, token.pos, f.side)
		c._loot.relocate_ground(token,at)


func _drop_result(success: bool, t: Figure, at: Vector2, token_id: int) -> void:
	if not success and t.in_play() and t.carried_treasures().has(token_id):
		c._loot._drop(t, at, token_id)
