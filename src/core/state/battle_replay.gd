class_name BattleReplay
extends RefCounted
## Re-execute recorded commands from an independent checkpoint. Fail closed on
## unsupported actions, missing events or RNG divergence; never touch live play.


static func verify(checkpoint: Dictionary,db: FigureDb,commands: Array,events: Array) -> Dictionary:
	var c := BattleSnapshot.rebuild(checkpoint,db)
	if c==null:
		return {"ok":false,"reason":"Incompatible checkpoint","verified":0}
	var verified := 0
	for record: Dictionary in commands:
		var first := int(record.get("event_start",-1))
		var last := int(record.get("event_end",-1))
		if first!=c.history.size() or last<first or last>events.size() or c.dice._rng.state!=record.get("rng_before"):
			return {"ok":false,"reason":"Missing history or RNG mismatch","verified":verified}
		if not apply(c,str(record.get("key","")),record.get("args",{})):
			return {"ok":false,"reason":"Unsupported or rejected command: "+str(record.get("key","")),"verified":verified}
		if c.dice._rng.state!=record.get("rng_after") or c.history.size()!=last:
			return {"ok":false,"reason":"Command diverged","verified":verified}
		if BattleRecord.pack(c.history.slice(first,last))!=events.slice(first,last):
			return {"ok":false,"reason":"Event divergence","verified":verified}
		verified+=1
	if c.history.size()!=events.size():
		return {"ok":false,"reason":"Unrecorded trailing events","verified":verified}
	return {"ok":true,"verified":verified}


static func apply(c: GameController,key: String,args: Dictionary) -> bool:
	match key:
		"activate": return c.activate(args["id"])
		"movement": return c.commit_movement(args["mode"],args["node"])
		"move_to": return c.move_to(args["node"],args.get("cape",false))
		"move_on_floor": return c.move_on_floor(args["node"])
		"fight": return c.fight(args["target"])
		"shoot": return c.shoot(args["target"],args.get("wraith",false),args.get("ammo",false))
		"reload": return c.reload()
		"pick_up": return c.pick_up(args["id"])
		"drop_treasure": return c.drop_treasure(args["at"])
		"exit_table": return c.exit_table(args["node"])
		"exit_on_floor": return c.exit_on_floor(args["node"])
		"start_cast": return c.start_cast(args["spell"],args["target"],args.get("ammo",false))
		"finish_cast": return c.finish_cast(args["health"])
		"answer_intercept": return c.answer_intercept(args["accept"])
		"answer_initiative": return c.answer_initiative(args["use"])
		"answer_fate_combat": return c.answer_fate_combat(args["use"])
		"stay_in_combat": return c.stay_in_combat()
		"finish_early_phase": return c.finish_early_phase()
		"begin_group":
			var ids: Array[int]=[]
			ids.assign(args["ids"])
			return c.begin_group(ids)
		"resolve_push": return c.resolve_push(args["own"],args.get("distance",1.0))
		"answer_elemental_combat": return c.answer_elemental_combat(args["use"])
		"use_stored_action": return c.use_stored_action()
		"fight_hand": return c.fight_hand(args["id"])
		"select_melee": return c.select_melee(args["id"])
		"drink_well": return c.drink_well()
		"break_ice": return c.break_ice()
		"end_activation":
			if not c.can_end_activation():
				return false
			c.end_activation()
			return true
	return false
