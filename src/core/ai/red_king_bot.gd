class_name RedKingBot
extends RefCounted
## Select optional equipment through the same validated action interfaces as players.

static func prepare(c: GameController,f: Figure) -> bool:
	if not f.in_play() or FuryRules.target(c.state,f)!=null:
		return false
	if HolyLantern.can_toggle(c) and not HolyLantern.lit(f):
		for t in c.state.figures:
			if t.in_play() and t.side!=f.side and t.ring_side==f.ring_side and (t.is_demon() or t.is_undead()) and Shooting.distance(f,t)<=5.0:
				HolyLantern.toggle(c)
				break
	if GearActions.cape_ready(c) and (f.treasure_id>=0 or f.health<=4 or f.def.role in ["wizard","apprentice"]):
		var reach := GearActions.cape_reach(c)
		var best: Variant=null
		var score := 0.0
		for n: Vector2i in reach.nodes():
			var at := MoveGrid.to_pos(n)
			var danger := 0.0
			for t in c.state.figures:
				if t.in_play() and t.side!=f.side and t.ring_side==f.ring_side and at.distance_to(t.pos)<4.0:
					danger+=4.0-at.distance_to(t.pos)
			if danger>=3.0:
				continue
			var value := at.distance_to(f.pos)-danger*2.0
			if value>score:
				score=value
				best=n
		if best!=null and c.move_to(best,true):
			return true
	if f.treasure_id>=0 and RunForIt.ready(c,true) and not RedKingRingworld.active(c.state) and not RealityCracks.blocks_exit(c.state):
		var field := MovePlanner.exit_field(c.state,f.side)
		var here: float=field.get(MovePlanner.node_at(f.pos),INF)
		var best_normal := here
		for n: Vector2i in c.reach().nodes():
			best_normal=minf(best_normal,float(field.get(n,INF)))
		var reach := RunForIt.reach(c,true)
		var best: Variant=null
		var best_value := best_normal-1.0
		for n: Vector2i in reach.nodes():
			var value: float=field.get(n,INF)
			if value<best_value:
				best_value=value
				best=n
		if best!=null and RunForIt.apply(c,best,true):
			return true
	return false


static func special_shot(c: GameController,f: Figure,normal: Figure) -> bool:
	if not c.can_act() or f.ranged==null or (not MagicAmmo.ready(f) and not ActiveGear.ready(f,Shooting.WRAITH)):
		return false
	var best: Figure=null
	var wraith := false
	var score := 0.0
	for t in c.state.figures:
		if not t.in_play() or t.side==f.side or t.ring_side!=f.ring_side or RingworldBot.protected_key(c.state,f,t) or Contact.in_combat(c.state.figures,t):
			continue
		var ammo := c.can_shoot(t.id,false,true)
		var ray := normal==null and c.can_shoot(t.id,true,false)
		if not ammo and not ray:
			continue
		if normal!=null and not (t.def.traits.has("immune_normal") or RedKingTethers.pylon(t)):
			continue
		var value := MagicTactics.importance(t)*(1.0+4.0/maxf(1.0,t.health))
		if RedKingTethers.pylon(t) or RedKingRingworld.key_master(t):
			value+=4.0
		if value>score:
			best=t
			score=value
			wraith=not ammo
	return best!=null and c.shoot(best.id,wraith,not wraith)


static func mind(c: GameController,f: Figure) -> void:
	# A solo wizard may cast twice; avoid ending after the first successful action.
	for i in 3:
		if not f.in_play() or c.awaiting_reaction() or f.actions_left<=0:
			return
		if c.can_act() and MagicBot.play(c,f):
			continue
		if TreasureBot.play(c,f):
			continue
		if c.can_act() and Bot._fight_if_engaged(c,f):
			continue
		break
