class_name BattleFloorInput
extends RefCounted
## Geometry adapter only. All menus, reactions, attack confirmation and
## movement planning belong to BattleInput and BattleHud, on every board.
const POINT_MODES := ["floor_teleport","floor_leap","floor_bridge","floor_bridge_end","floor_bottle","floor_spell_point","floor_ring_teleport","floor_potion_teleport","floor_treasure_destination","floor_suggestion"]


static func append_spells(bi: BattleInput,f: Figure) -> void:
	var c:=bi.c
	if not c.can_act() or not CasterLoadout.is_caster(f.def.role) or ScenarioNull.muted(f) or Contact.in_combat(c.state.figures,f) or f.spell_effects.has("blinding_light"):
		return
	for target in c.state.figures:
		if LayeredLeap.eligible(c,target):
			bi.cast_options.append("leap")
			break
	if LayeredBridge.eligible(c):
		bi.cast_options.append("bridge")


static func handles_action(bi: BattleInput,key: String) -> bool:
	return bi.available.has(key) and (key in ["spell_teleport","spell_leap","spell_bridge","cancel_bridge","gear_rk_bottle_imp","gear_ring_teleportation","potion_teleportation"] or (key.begins_with("spell_") and (SummonActions.PLACEMENT.has(key.trim_prefix("spell_")) or TerrainMagic.FLOOR_SPELLS.has(key.trim_prefix("spell_")))))


static func action(bi: BattleInput,key: String) -> bool:
	match key:
		"cancel_bridge": return bi.c.cancel_floor_bridge()
		"spell_teleport":
			bi.mode="floor_teleport"
			bi.selected_spell="teleport"
		"spell_leap":
			bi.mode="floor_leap_target"
			bi.selected_spell="leap"
		"spell_bridge":
			bi.mode="floor_bridge"
			bi.selected_spell="bridge"
			bi.bridge_start=null
		"gear_rk_bottle_imp":
			bi.mode="floor_bottle"
			bi.selected_spell=""
		"gear_ring_teleportation":
			bi.mode="floor_ring_teleport"
			bi.selected_spell=""
		"potion_teleportation":
			bi.mode="floor_potion_teleport"
			bi.selected_spell=""
		_:
			bi.mode="floor_spell_point"
			bi.selected_spell=key.trim_prefix("spell_")
			bi.spell_rotated=false
	bi.available.assign(["potion_cancel"] if key.begins_with("gear_") or key.begins_with("potion_") else ["spell_cancel"])
	if bi.selected_spell in ["fog","wall"]:
		bi.available.append("rotate_spell")
	bi.preview()
	return false


static func _index(bi: BattleInput,f: Figure) -> int:
	var index:=bi.floor_layout.index_of(bi.floor_id)
	return index if index>=0 else bi.floor_layout.index_of(f.surface_id)


static func preview(bi: BattleInput,s: BattleInputPreview.State) -> bool:
	if bi.mode=="floor_leap_target":
		for t in bi.c.state.figures:
			if LayeredLeap.eligible(bi.c,t):
				bi.targets.append(t)
		s.radius=0.65
		s.hint="Select an ally, then select a landing floor."
		return true
	if bi.mode not in POINT_MODES:
		return false
	var f:=bi.c.state.active()
	if f==null:
		return true
	var layout:=bi.floor_layout
	var t:=bi.c.state.figure(bi.spell_first) if bi.mode in ["floor_leap","floor_suggestion"] else f
	if t==null:
		return true
	var index:=_index(bi,t)
	if index<0:
		return true
	var candidates: Dictionary={}
	if bi.mode=="floor_bottle":
		candidates=GearActions.bottle_floor_points(bi.c)
		s.hint="Place the imp within one inch."
	elif bi.mode in ["floor_spell_point","floor_teleport","floor_ring_teleport","floor_potion_teleport"]:
		var nodes: Array[Vector3i]=[]
		match bi.mode:
			"floor_ring_teleport": nodes=GearActions.teleport_floor_points(bi.c,index)
			"floor_potion_teleport": nodes=bi.c._potions.teleport_floor_points(index)
			_: nodes=SpellAvailability.floor_placement_points(bi.c._magic,bi.selected_spell,false,index,bi.spell_rotated)
		for n in nodes:
			candidates[n]=true
		s.hint="Choose a legal placement on this floor."
	elif bi.mode=="floor_suggestion":
		for n in SpellAvailability.floor_suggestion_points(bi.c._magic,t,false,index):
			candidates[n]=true
		s.hint="Choose a safe destination within 3 inches, or leave the figure where it is."
	elif bi.mode=="floor_treasure_destination":
		var token:=bi.c.state.treasure(bi.spell_first)
		for n in bi.c._magic.treasure_magic.floor_points(f,bi.selected_spell,token,false,index):
			candidates[n]=true
		s.hint="Choose the treasure's destination on this floor."
	elif bi.mode in ["floor_bridge","floor_bridge_end"]:
		candidates=LayeredBridgePicker.points(bi.c,layout,index,bi.bridge_start if bi.mode=="floor_bridge_end" else null)
		s.hint="Select first bridge endpoint." if bi.mode=="floor_bridge" else "Select a different floor and the second endpoint."
	else:
		var grid:=LayeredGrid.new(layout,t,bi.c.state.figures)
		var surface:=layout.surfaces[index]
		for x in range(ceili(surface.rect.position.x/MoveGrid.STEP),floori(surface.rect.end.x/MoveGrid.STEP)+1):
			for y in range(ceili(surface.rect.position.y/MoveGrid.STEP),floori(surface.rect.end.y/MoveGrid.STEP)+1):
				var n:=Vector3i(x,y,index)
				var valid:=LayeredMagic.can_teleport_with(bi.c,n,layout,grid) if bi.mode=="floor_teleport" else not LayeredLeap.path(bi.c,t,n,layout,grid).is_empty()
				if valid:
					candidates[n]=true
		s.hint="Choose a visible legal destination." if bi.mode=="floor_teleport" else "Choose a legal Leap landing for "+t.label()+"."
	for n: Vector3i in candidates:
		bi.floor_points[n]=layout.world(n)
	s.hint+=" Change floor to see other destinations."
	return true


static func visible(bi: BattleInput,id: String) -> bool:
	return bi.floor_id.is_empty() or id==bi.floor_id


static func draw_points(bi: BattleInput,s: BattleInputPreview.State=null) -> void:
	var world:=PackedVector3Array()
	var selected:=PackedVector3Array()
	var f:=bi.c.state.active()
	if not bi.floor_points.is_empty():
		var actor:=bi.c.state.figure(bi.spell_first) if bi.mode in ["floor_leap","floor_suggestion"] else f
		var index:=_index(bi,actor) if actor!=null else -1
		for n: Vector3i in bi.floor_points:
			if n.z==index:
				world.append(bi.floor_points[n])
	elif s!=null:
		for t in bi.targets:
			if not visible(bi,t.surface_id):
				continue
			var at:=TableSpace.to_world(t.pos,t.elevation)
			if bi.mode=="group_select" and bi.group_selection.has(t.id):
				selected.append(at)
			else:
				world.append(at)
		for token in bi.tokens:
			var surface:=bi.c._magic.treasure_magic.origin_surface(token)
			if visible(bi,surface):
				world.append(bi.c._magic.treasure_magic.origin_world(token))
		if bi.tokens.is_empty() and f!=null and visible(bi,f.surface_id):
			var index:=bi.floor_layout.index_of(f.surface_id)
			if index>=0:
				for at in s.points:
					world.append(TableSpace.to_world(at,bi.floor_layout.surfaces[index].height_at(at)))
	bi.markers.show_world_points(world,s.color if s!=null else Color(0.28,0.9,0.8),s.radius if s!=null else 0.17)
	if not selected.is_empty():
		bi.markers.show_world_points(selected,Color(1.0,0.78,0.15),0.85,true)


static func pick(bi: BattleInput,screen: Vector2) -> Variant:
	var f:=bi.c.state.active()
	if f==null:
		return null
	var index:=_index(bi,f)
	if bi.mode in ["floor_leap","floor_suggestion"] and bi.floor_id.is_empty():
		var t:=bi.c.state.figure(bi.spell_first)
		if t!=null:
			index=_index(bi,t)
	var best: Variant=null
	var distance:=28.0
	for n: Vector3i in bi.floor_points:
		if n.z!=index:
			continue
		var point: Vector3=bi.floor_points[n]
		if bi.camera.is_position_behind(point):
			continue
		var d:=bi.camera.unproject_position(point).distance_to(screen)
		if d<distance:
			best=n
			distance=d
	return best


static func surface_point(bi: BattleInput,screen: Vector2) -> Variant:
	var f:=bi.c.state.active()
	if f==null:
		return null
	var index:=_index(bi,f)
	if index<0:
		return null
	var surface:=bi.floor_layout.surfaces[index]
	var run:=surface.rect.size.y if surface.axis_y else surface.rect.size.x
	var slope:=(surface.end_level-surface.level)/run
	var normal:=Vector3(0,1,-slope) if surface.axis_y else Vector3(-slope,1,0)
	var plane:=Plane(normal.normalized(),TableSpace.to_world(surface.rect.position,surface.level))
	var hit: Variant=plane.intersects_ray(bi.camera.project_ray_origin(screen),bi.camera.project_ray_normal(screen))
	if hit==null:
		return null
	var at:=TableSpace.to_table(hit)
	return at if surface.contains(at) else null


static func tap(bi: BattleInput,screen: Vector2) -> bool:
	if bi.mode=="floor_leap_target":
		var id:=bi._figure_at(screen)
		if id<0:
			return false
		bi.spell_first=id
		bi.mode="floor_leap"
		bi.preview()
		return false
	var node: Variant=pick(bi,screen)
	if node==null:
		return false
	if bi.mode in BattleMovePlan.MODES:
		bi.move_plan.choose_node(bi,node)
		return false
	match bi.mode:
		"floor_teleport","floor_spell_point": return bi._declared(bi.c._magic.start_floor_at(bi.selected_spell,node,bi.spell_rotated))
		"floor_ring_teleport": return GearActions.teleport_on_floor(bi.c,node)
		"floor_potion_teleport": return bi.c._potions.teleport_on_floor(node)
		"floor_suggestion": return bi._declared(bi.c._magic.start_floor_suggestion(bi.spell_first,node))
		"floor_treasure_destination": return bi._declared(bi.c._magic.start_floor_treasure(bi.selected_spell,bi.spell_first,node))
		"floor_leap": return bi.c.leap_on_floor(bi.spell_first,node)
		"floor_bottle": return GearActions.bottle_on_floor(bi.c,node)
		"floor_bridge":
			bi.bridge_start=node
			bi.mode="floor_bridge_end"
			bi.preview()
		"floor_bridge_end": return bi.c.bridge_on_floors(bi.bridge_start,node)
	return false
