class_name RedKingInvestigations
extends RefCounted
## Act I encounter. Deck, alarm, restrictions and skipped activations are plain checkpoint data.
const ID := "red_king_investigations"
const LOUD := ["blinding_light","crumble","destructive_sphere","draining_word","elemental_ball","elemental_bolt","glow","grenade","power_word","scatter_shot","wall"]


static func active(s: GameState) -> bool:
	return s.scenario_special==ID


static func prepare(c: GameController) -> void:
	if not active(c.state) or c.state.scenario_data.has("stand_deck"):
		return
	var cards := ["gold100","gold50","gold50","gold25","gold25","poison","skip"]
	for i in maxi(0,c.state.side_count()-2):
		cards.append_array(["gold50","gold25"])
	c.state.scenario_data["stand_deck"]=EventDeck.create(cards,c.dice)
	c.state.scenario_data["alarm"]=false
	c.state.scenario_data["reinforcements"]=0


static func raise_alarm(c: GameController,reason: String) -> void:
	if not active(c.state) or c.state.scenario_data.get("alarm",false):
		return
	c.state.scenario_data["alarm"]=true
	c.emit("investigation_alarm",{"reason":reason})


static func observe_event(c: GameController,type: String,data: Dictionary) -> void:
	if c.state.scenario_data.get("alarm",false):
		return
	if type=="cast_result" and data.get("success",false) and LOUD.has(data.get("spell","")):
		raise_alarm(c,"spell")
	elif type=="rune_exploded":
		raise_alarm(c,"rune")
	elif type=="damage":
		var f := c.state.figure(data["id"])
		if f!=null and f.in_play() and f.def.id=="blood_marked_berserker" and int(data["by"])!=f.id:
			raise_alarm(c,"wounded guard")


static func before_activation(c: GameController,f: Figure) -> void:
	if not active(c.state):
		return
	var skip: Dictionary=c.state.scenario_data.get("stand_skip",{})
	if skip.erase(f.id):
		f.magic_exhausted=true
		c.emit("investigation_skip",{"id":f.id})


static func activation(c: GameController,f: Figure) -> void:
	if not active(c.state) or f.def.id!="blood_marked_berserker" or not dormant(c.state,f):
		return
	for t in c.state.figures:
		if t.side>=0 and t.in_play() and IllusionRules.visible_to(c.state.figures,f,t) and LineOfSight.check_figures(c.state.board,f,t).clear:
			raise_alarm(c,"spotted warband")
			return
	f.actions_left=0


static func dormant(s: GameState,f: Figure) -> bool:
	return active(s) and f.def.id=="blood_marked_berserker" and not s.scenario_data.get("alarm",false) and s.turn<=3


static func can_investigate(c: GameController,token: TreasureToken) -> bool:
	var f := c.state.active()
	if not active(c.state) or not c.can_act() or f==null or f.side<0 or not token.investigation or not token.on_ground() or IllusionRules.phantom(f) or f.spell_effects.has("plane_walk"):
		return false
	if absf(f.elevation-c.state.board.height_at(token.pos))>=0.5 or f.pos.distance_to(token.pos)>Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS+0.01:
		return false
	for enemy in c.state.figures:
		if enemy.side!=f.side and enemy.in_play() and Shooting.distance(f,enemy)<=1.0:
			return false
	return true


static func investigate(c: GameController,f: Figure,token: TreasureToken) -> bool:
	if not can_investigate(c,token):
		return false
	prepare(c)
	var card: Variant=EventDeck.draw(c.state.scenario_data["stand_deck"])
	if card==null:
		return false
	c._spend(f)
	token.investigation=false
	var result := str(card)
	if result.begins_with("gold"):
		token.bonus_gold=int(result.trim_prefix("gold"))
	else:
		token.lost=true
	c.emit("stand_investigated",{"id":f.id,"treasure":token.id,"result":result,"gold":token.bonus_gold})
	c.emit("investigation_xp",{"side":f.side,"xp":10})
	if token.lost:
		var raw := c.dice.d20()
		var success := StatRoll.succeeds(raw,f.effective_will()+f.roll_penalty(),16)
		c.emit("stand_will",{"id":f.id,"roll":raw,"success":success})
		if not success:
			if result=="poison":
				c.poison(f)
			else:
				var skip: Dictionary=c.state.scenario_data.get("stand_skip",{})
				skip[f.id]=true
				c.state.scenario_data["stand_skip"]=skip
	else:
		c._loot.claim_free(f,token)
	return true


static func end_turn(c: GameController) -> void:
	var s := c.state
	if not active(s):
		return
	var was_alarm: bool=s.scenario_data.get("alarm",false)
	if s.turn==3:
		var exits := {}
		for side in s.side_count():
			# Fixed two-sided deployment: north starts at low y, south at high y.
			var vertical := "south" if side==0 else "north"
			exits[side]=[vertical,"west" if c.dice.pick(2)==0 else "east"]
		s.scenario_data["exit_edges"]=exits
		s.board.field_cache.clear()
		c.emit("investigation_routes",{"edges":exits})
		raise_alarm(c,"reality shift")
	if not was_alarm or int(s.scenario_data.get("reinforcements",0))>=6 or s.creature_db==null or not s.creature_db.available("blood_marked_berserker"):
		return
	var target := Vector2(18,13 if c.dice.pick(2)==0 else 23)
	var grid := MoveGrid.new(s.board,null,s.figures)
	var best: Variant=null
	var distance := INF
	var center := MovePlanner.node_at(target)
	for x in range(-5,6):
		for y in range(-5,6):
			var n := center+Vector2i(x,y)
			var d := MoveGrid.to_pos(n).distance_squared_to(target)
			if d<distance and grid.open(n):
				distance=d
				best=n
	if best!=null:
		c._encounters._spawn_at("blood_marked_berserker",MoveGrid.to_pos(best))
	s.scenario_data["reinforcements"]=int(s.scenario_data.get("reinforcements",0))+1


static func exit_allowed(s: GameState,at: Vector2,side: int) -> bool:
	var exits: Dictionary=s.scenario_data.get("exit_edges",{})
	if not exits.has(side):
		return true
	var edges: Array=exits[side]
	var margin := Figure.BASE_RADIUS+0.01
	return (edges.has("north") and at.y<=margin) or (edges.has("south") and at.y>=s.board.size.y-margin) or (edges.has("west") and at.x<=margin) or (edges.has("east") and at.x>=s.board.size.x-margin)


static func has_objectives(s: GameState) -> bool:
	for token in s.treasures:
		if token.unresolved():
			return true
	return false


static func finish_unsearched(c: GameController) -> void:
	for token in c.state.treasures:
		if token.unresolved():
			c._loot.lose(token)
