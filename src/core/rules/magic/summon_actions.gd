class_name SummonActions
extends RefCounted
## Shared placement and temporary allegiance rules. All choices go through SpellActions.
const PLACEMENT := ["animate_skull", "imp", "raise_zombie", "summon_demon", "illusionary_soldier"]
const CONTROL := {"control_animal": "animal", "control_construct": "construct", "control_demon": "demon", "control_undead": "undead", "mind_control": ""}

## The controller owns this helper; avoid a RefCounted ownership cycle.
var _controller_ref: WeakRef
var c: GameController:
	get:
		return _controller_ref.get_ref() as GameController


func _init(controller: GameController) -> void:
	_controller_ref=weakref(controller)


func controlled(f: Figure, id: String) -> Figure:
	for t in c.state.figures:
		if t.in_play() and t.controller_id == f.id and t.control_spell == id:
			return t
	return null


func summoned(f: Figure, id: String, whole_side: bool = false) -> Figure:
	for t in c.state.figures:
		if not t.in_play() or t.summon_spell != id:
			continue
		var owner := c.state.figure(t.summoned_by)
		if owner != null and (owner.id == f.id or (whole_side and owner.side == f.side)):
			return t
	return null


func can_control(f: Figure, t: Figure, id: String) -> bool:
	if t.def.traits.has("antithetical_magic") or (id=="mind_control" and t.def.traits.has("immune_mind_control")) or (id=="control_demon" and t.def.traits.has("immune_control_demon")):
		return false
	var existing := controlled(f, id)
	if (t.side == f.side and t.controller_id < 0 and t.summon_spell == "") or (existing != null and existing != t):
		return false
	if id == "mind_control":
		return t.def.role not in ["wizard", "apprentice"] and not t.def.traits.has("mindless") and not t.mind_locked()
	return t.is_demon() if id == "control_demon" else t.def.traits.has(CONTROL[id])


func _limit_allows(f: Figure,id: String) -> bool:
	var s:=c.state
	if s.creature_db==null:
		return false
	if id=="animate_skull" and count_summoned(c.state,f,id)>= (2 if skull_staff(f) else 1):
		return false
	if id=="raise_zombie" and count_summoned(c.state,f,id,true)>=(2 if skull_staff(f) else 1):
		return false
	if id=="illusionary_soldier" and count_summoned(s,f,id,true)>=(2 if illusion_staff_owner(s,f.side)!=null else 1):
		return false
	if id == "summon_demon" and controlled(f, "control_demon") != null:
		return false
	return true


func can_place(f: Figure,id: String,at: Vector2) -> bool:
	var s:=c.state
	if not _limit_allows(f,id) or ScenarioNull.field_at(s.board,at) or not s.board.can_stand(at,Figure.BASE_RADIUS):
		return false
	return _placement_at(f,id,at,s.board.height_at(at)) and LineOfSight.check(s.board,f.pos,at).clear


func _placement_at(f: Figure,id: String,at: Vector2,height: float) -> bool:
	var s:=c.state
	var dist:=f.pos.distance_to(at)
	var height_delta:=height-f.elevation
	if id == "animate_skull" and Vector2(dist, height_delta).length() > 6.001:
		return false
	if id in ["raise_zombie", "summon_demon", "illusionary_soldier"] and (dist > (1.25 if id == "raise_zombie" else 2.0) or absf(height_delta) >= 0.5):
		return false
	for t in s.figures:
		if not t.in_play():
			continue
		var d := Vector2(t.pos.distance_to(at),t.elevation-height).length()
		if d < Contact.OVERLAP or (id == "imp" and d < 4.0):
			return false
		if id in ["raise_zombie", "summon_demon", "illusionary_soldier"] and t.side != f.side and d <= Contact.CONTACT:
			return false
	return true


func can_place_floor(f: Figure,id: String,n: Vector3i) -> bool:
	var s:=c.state
	var layout:=s.board.floor_geometry()
	if not _limit_allows(f,id) or not BattlePlacement.floor_open(s,n) or ScenarioNull.field_at(s.board,layout.point(n)):
		return false
	return _placement_at(f,id,layout.point(n),layout.height(n)) and LineOfSight.floor_point_visible(s.board,layout,f,layout.world(n),s.board.size.length()+12.0 if id=="imp" else 6.0)


func floor_points(f: Figure,id: String,first_only: bool=false,index: int=-1) -> Array[Vector3i]:
	var out: Array[Vector3i]=[]
	if not _limit_allows(f,id):
		return out
	var radius:=6.0 if id=="animate_skull" else (c.state.board.size.length() if id=="imp" else 2.0)
	for n in BattlePlacement.nodes(c.state.board,f.pos,radius,index):
		if can_place_floor(f,id,n):
			out.append(n)
			if first_only:
				break
	return out


func points(f: Figure, id: String, first_only: bool = false) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var grid := MoveGrid.new(c.state.board)
	var reach := 6.0 if id == "animate_skull" else (2.0 if id != "imp" else c.state.board.size.length())
	var origin := MovePlanner.node_at(f.pos)
	var radius := ceili(reach / MoveGrid.STEP)
	for x in range(maxi(0, origin.x - radius), mini(grid.cols, origin.x + radius + 1)):
		for y in range(maxi(0, origin.y - radius), mini(grid.rows, origin.y + radius + 1)):
			var at := MoveGrid.to_pos(Vector2i(x, y))
			if can_place(f, id, at):
				out.append(at)
				if first_only:
					return out
	return out


func apply_control(f: Figure, t: Figure, id: String, roll: int) -> void:
	var bonus := 5 if id=="mind_control" and t.def.traits.has("blood_marked") else 0
	if id=="mind_control":
		bonus+=RedKingGear.puppet_penalty(f,t)
	c._magic.resistance.attempt(t, roll, _control_result.bind(f, t, id, roll),bonus)


func _control_result(success: bool, f: Figure, t: Figure, id: String, roll: int) -> void:
	if success or not t.in_play():
		return
	# Errata: temporary figures lose their original warband link, permanent figures retain it.
	if t.summoned_by >= 0 or t.summon_spell != "":
		t.original_side = -1
		t.summoned_by = -1
		t.summon_spell = ""
	if t.original_side == f.side:
		release(t)
		return
	t.controller_id = f.id
	t.control_spell = id
	t.control_roll = roll
	t.side = f.side
	c.emit("allegiance", {"id": t.id, "side": t.side})


func release(t: Figure) -> void:
	t.side = t.original_side
	t.controller_id = -1
	t.control_spell = ""
	t.control_roll = 0
	c.emit("allegiance", {"id": t.id, "side": t.side})


func cancelable(f: Figure, t: Figure) -> bool:
	return t.in_play() and ((t.controller_id == f.id and t.control_spell != "mind_control") or (t.summoned_by == f.id and t.summon_spell == "animate_skull"))


func cancel(f: Figure, t: Figure) -> void:
	if t.summon_spell == "animate_skull" and t.summoned_by == f.id:
		vanish(t)
	else:
		release(t)


func vanish(t: Figure) -> void:
	c._loot.drop_on_death(t)
	t.exited = true
	c.emit("exit", {"id": t.id})


func spawn(f: Figure, id: String, at: Vector2, roll: int, tn: int,golden_fang: bool=false,surface: String="",height: float=0.0) -> void:
	var type := id
	var side := -1
	match id:
		"imp":
			var old := summoned(f, id)
			if old != null:
				vanish(old)
		"illusionary_soldier":
			type = "thug"
			side = f.side
		"raise_zombie":
			type = "zombie"
			side = f.side
		"summon_demon":
			var margin := roll - tn
			type = "major_demon" if margin >= 13 else ("minor_demon" if margin >= 6 else "imp")
			side = f.side
		"animate_skull":
			type = "animated_skull"
	var t := c._encounters._spawn_at(type,at,side,f.ring_side,surface,height)
	if id=="animate_skull" and golden_fang and RedKingMaterials.spend_fang(f):
		t.used_gear["rk_golden_fang"]=true
		c.emit("gear_used",{"id":f.id,"target":t.id,"gear":RedKingMaterials.FANGS})
	if id in ["animate_skull","raise_zombie"] and skull_staff(f):
		t.used_gear["rk_skull_strong"]=true
	t.summoned_by = f.id
	t.summon_spell = id
	if id == "illusionary_soldier":
		c.emit("spell_effect", {"id": t.id, "spell": id})
	if id == "summon_demon":
		t.original_side = -1
		t.controller_id = f.id
		t.control_spell = "control_demon"
		t.control_roll = roll


func miscast_demon(f: Figure) -> void:
	var s := c.state
	var roll := c.dice.d20()
	var type := "imp" if roll <= 10 else ("minor_demon" if roll <= 17 else "major_demon")
	if not s.board.floor_layout.is_empty():
		var layout:=s.board.floor_geometry()
		for n in BattlePlacement.nodes(s.board,f.pos,1.25,layout.index_of(f.surface_id)):
			if not BattlePlacement.floor_open(s,n) or not is_equal_approx(layout.world(n).distance_to(Vector3(f.pos.x,f.elevation,f.pos.y)),1.0) or ScenarioNull.field_at(s.board,layout.point(n)):
				continue
			c._encounters._spawn_at(type,layout.point(n),-1,f.ring_side,layout.surface_id(n),layout.height(n))
			return
		return
	for i in 16:
		var at := f.pos + Vector2.RIGHT.rotated(TAU * i / 16.0)
		if not s.board.can_stand(at, Figure.BASE_RADIUS) or absf(s.board.height_at(at) - f.elevation) >= 0.5:
			continue
		var open := true
		for t in s.figures:
			if t.in_play() and t != f and t.pos.distance_to(at) < Contact.OVERLAP:
				open = false
		if open:
			c._encounters._spawn_at(type, at)
			return


static func skull_staff(f: Figure) -> bool:
	return f.def.role=="wizard" and ActiveGear.has(f,"gear_rk_skull_staff") and not MagicEquipment.suppressed(f) and not f.destroyed_weapons.has("staff")


static func count_summoned(s: GameState,f: Figure,id: String,whole_side: bool=false) -> int:
	var count := 0
	for t in s.figures:
		if not t.in_play() or t.summon_spell!=id:
			continue
		var owner := s.figure(t.summoned_by)
		if owner!=null and (owner==f or (whole_side and owner.side==f.side)):
			count+=1
	return count


static func skull_cast_modifier(f: Figure,id: String) -> int:
	if not skull_staff(f):
		return 0
	var result := 1 if id in ["animate_skull","raise_zombie"] else 0
	var s := RedKingVeil.of(f)
	if s!=null and (count_summoned(s,f,"animate_skull")>1 or count_summoned(s,f,"raise_zombie",true)>1):
		result-=2
	return result


const ILLUSION_STAFF := "gear_rk_staff_of_the_illusionist"


static func illusion_staff(f: Figure) -> bool:
	return f!=null and f.def.role=="wizard" and ActiveGear.has(f,ILLUSION_STAFF) and not MagicEquipment.suppressed(f) and not f.destroyed_weapons.has("staff")


static func illusion_staff_owner(s: GameState,side: int) -> Figure:
	for f in s.figures:
		if f.side==side and f.in_play() and illusion_staff(f):
			return f
	return null


static func illusion_will(f: Figure) -> int:
	var s := RedKingVeil.of(f)
	return -2 if s!=null and illusion_staff(f) and count_summoned(s,f,"illusionary_soldier",true)>1 else 0


func enforce_illusion_limit(owner: Figure) -> void:
	if owner.def.role!="wizard" or not ActiveGear.has(owner,ILLUSION_STAFF):
		return
	var copies: Array[Figure]=[]
	for t in c.state.figures:
		if t.in_play() and t.side==owner.side and t.summon_spell=="illusionary_soldier":
			copies.append(t)
	while copies.size()>1:
		var newest: Figure=copies.pop_back()
		vanish(newest)
