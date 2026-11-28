class_name Swimming
extends RefCounted
## Core p.51. Water is a real terrain hazard, not a visual overlay.
const EXEMPT := ["aquatic","amphibious","ethereal","flying"]
const LIGHT := ["archer","crossbowman","infantryman","man_at_arms","treasure_hunter","ranger","tracker"]
const HEAVY := ["knight","marksman","templar"]

static func immune(f: Figure) -> bool:
	if f==null:
		return false
	for trait_id: String in EXEMPT:
		if f.def.traits.has(trait_id):
			return true
	return false

static func depth(board: Board,at: Vector2,height: float) -> int:
	if board==null or not board.has_water:
		return 0
	var result:=0
	for p in board.pieces:
		if p.kind.id not in ["shallow_water","deep_water"] or not p.contains(at):
			continue
		var level:=p.base_height if not board.floor_layout.is_empty() else board.ground_height_at(at)
		if absf(height-level)<0.5:
			result=maxi(result,2 if p.kind.id=="deep_water" else 1)
	return result

static func figure_depth(f: Figure) -> int:
	if f.battle_ref==null:
		return 0
	var s: GameState=f.battle_ref.get_ref()
	return depth(s.board,f.pos,f.elevation) if s!=null else 0

static func modifier(f: Figure) -> int:
	var mod:=-5 if f.def.id in HEAVY else (-2 if f.def.id in LIGHT else 0)
	if f.def.shield:
		mod-=1
	if f.treasure_id>=0:
		mod-=2
	return mod

static func fight_penalty(f: Figure) -> int:
	return -2 if not immune(f) and figure_depth(f)==2 else 0

static func prevents_bow(f: Figure) -> bool:
	return f.ranged!=null and f.ranged.id in ["bow","crossbow"] and figure_depth(f)==2

static func avoids_deep(board: Board,f: Figure,at: Vector2,height: float) -> bool:
	return f!=null and f.side<0 and not immune(f) and depth(board,at,height)==2 and figure_depth(f)!=2

static func activate(c: GameController,f: Figure) -> void:
	if int(f.used_gear.get("swim_failed_turn",-1))==c.state.turn:
		f.actions_left=0
		return
	if not f.in_play() or immune(f) or figure_depth(f)!=2 or int(f.used_gear.get("swim_checked_turn",-1))==c.state.turn:
		return
	f.used_gear["swim_checked_turn"]=c.state.turn
	var raw:=c.dice.d20()
	var mod:=f.effective_will()+f.roll_penalty()+modifier(f)
	var success:=StatRoll.succeeds(raw,mod,5)
	c.emit("swimming_roll",{"id":f.id,"roll":raw,"modifier":mod,"success":success})
	if not success:
		f.used_gear["swim_failed_turn"]=c.state.turn
		f.actions_left=0
		c._hurt(f,maxi(0,5-raw-mini(mod,10)),f,true)
