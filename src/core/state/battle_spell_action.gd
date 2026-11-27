class_name BattleSpellAction
extends RefCounted
## Spell choices carry plain data rather than UI objects. Geometry selects
## the existing validator; the dispatcher never rolls during preview.


static func execute(c: GameController,key: String,args: Dictionary={}) -> bool:
	if not BattleSnapshot.plain(args):
		return false
	return BattleRecord.run(c,"spell_command",{"key":key,"args":args},func() -> bool: return _apply(c,key,args))


static func _apply(c: GameController,key: String,args: Dictionary) -> bool:
	var id := str(args.get("spell",""))
	var target := int(args.get("target",-1))
	var at: Variant=args.get("at")
	var layered := not c.state.board.floor_layout.is_empty()
	var rotated := bool(args.get("rotated",false))
	if key in ["place","move","treasure","bridge"]:
		if layered:
			if not _valid_node(c,at):
				return false
		elif not at is Vector2:
			return false
	match key:
		"place":
			return c._magic.start_floor_at(id,at,rotated) if layered else c._magic.start_at(id,at,rotated,bool(args.get("extended",false)))
		"move":
			if not layered:
				return c._magic.start_move(id,target,at)
			if id=="leap":
				return c.leap_on_floor(target,at)
			return id=="suggestion" and c._magic.start_floor_suggestion(target,at)
		"treasure":
			return c._magic.start_floor_treasure(id,target,at) if layered else c._magic.start_treasure(id,target,at)
		"bridge":
			var other: Variant=args.get("end")
			return layered and _valid_node(c,other) and c.bridge_on_floors(at,other)
		"swap": return c._magic.start_swap(target,int(args.get("second",-1)))
		"counter": return c._magic.start_counter(id,int(args.get("index",-1)))
		"cancel_control": return c._magic.cancel(target)
		"cancel_bridge": return c.cancel_floor_bridge() if layered else c._magic.terrain.cancel_bridge(c.state.active())
		"resist": return c._magic.resistance.answer(int(args.get("health",0)))
		"resist_fate": return c._magic.resistance.reroll_fate()
		"resist_amulet": return c._magic.resistance.use_amulet()
		"cast_fate": return c._magic.reroll_fate()
		"insure": return c._magic.insure()
		"golden_fang": return c._magic.toggle_golden_fang()
		"gem": return c._magic.toggle_gem(str(args.get("option","")))
		"single_shatter": return c._magic.single_shatter()
	return false


static func _valid_node(c: GameController,n: Variant) -> bool:
	return n is Vector3i and n.z>=0 and n.z<c.state.board.floor_geometry().surfaces.size()
