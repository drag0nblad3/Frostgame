class_name BattleDeployment
extends RefCounted
## Controller-owned setup transaction. A side finishes before the next deploys;
## undeployed opponents neither occupy candidate points nor influence AI choices.

var c: GameController
var human:=0
var order: Array[int]=[]
var rolls: Array[int]=[]
var zones: Dictionary={}
var placed: Dictionary={}
var active:=-1
var index:=0
var error:=""
var done:=false
var treasure_stage:=0
var treasure_candidates: Array[Dictionary]=[]


func _init(controller: GameController,human_side: int) -> void:
	c=controller
	human=human_side


func begin(manual_treasure: bool=false) -> void:
	if c.state.turn!=0 or DeploymentRules.kind(c.state)=="fixed":
		done=true
		return
	if MausoleumSetup.enabled(c.state):
		if manual_treasure and human>=0 and not c.state.scenario_data.get("mausoleum_treasures_ready",false):
			treasure_stage=4
			treasure_candidates=MausoleumSetup.options(c.state,4)
			return
		if not MausoleumSetup.prepare(c.state,c.dice):
			error="Unable to place the Mausoleum's additional treasures and guards."
			return
	if not StandardTreasurePlacement.prepare(c.state,c.dice):
		error="Unable to place five legal treasures on this battlefield."
		return
	if manual_treasure and human>=0 and StandardTreasurePlacement.enabled(c.state):
		treasure_stage=1
		treasure_candidates=StandardTreasurePlacement._candidates(c.state)
		return
	_begin_edges()


func _begin_edges() -> void:
	# Real games end by objectives, not the simulation's safety cap (core p.71).
	c.state.scenario_data["turn_limit"]=0
	if DeploymentRules.kind(c.state)=="veil":
		order.assign([0])
	else:
		var result:=Initiative.roll(c.dice,c.state.side_count())
		order.assign(result["order"])
		rolls.assign(result["rolls"])
	advance()


func treasure_options() -> Array[Dictionary]:
	if treasure_stage==4:
		return treasure_candidates
	return StandardTreasurePlacement.options(c.state,treasure_candidates,treasure_stage) if treasure_stage>0 else []


func place_treasure(p: Dictionary) -> bool:
	if treasure_stage==4:
		if not MausoleumSetup.choose(c.state,c.dice,p):
			error="Choose a legal treasure and adjacent guard position."
			return false
		error=""
		finish_treasure_setup()
		return true
	if treasure_stage==0 or not StandardTreasurePlacement.choose(c.state,c.dice,treasure_candidates,treasure_stage,p):
		error="That placement leaves no legal completion. Choose another point."
		return false
	error=""
	if treasure_stage==1:
		treasure_stage=3
	else:
		finish_treasure_setup()
	return true


func finish_treasure_setup() -> void:
	if treasure_stage==0:
		return
	if treasure_stage==4 and not MausoleumSetup.prepare(c.state,c.dice):
		error="Unable to place the additional treasures."
		return
	treasure_stage=0
	treasure_candidates.clear()
	_begin_edges()


func available() -> Array[int]:
	if treasure_stage>0 or order.is_empty() or index>=order.size():
		return []
	var previous:=int(zones.get(order[index-1],-1)) if index>0 else -1
	return DeploymentRules.choices(c.state,previous)


func advance() -> void:
	while index<order.size():
		active=order[index]
		if c.state.side_figures(active).is_empty():
			index+=1
			continue
		var options:=available()
		if active==human and options.size()>1:
			return
		if active==human and options.size()==1:
			if choose(options[0]):
				return
			return
		if not auto_choose():
			return
		index+=1
	done=true
	active=-1


func auto_choose() -> bool:
	var options:=available()
	# Rotate equal edge choices deterministically using the same game Dice.
	if options.size()>1:
		var start:=c.dice.pick(options.size())
		for i in start:
			options.append(options.pop_front())
	for choice in options:
		if choose(choice):
			return true
	error="No complete legal formation fits this deployment zone."
	return false


func _ignored() -> Array[int]:
	var out: Array[int]=[]
	for f in c.state.figures:
		if f.side>=0 and not placed.has(f.id):
			out.append(f.id)
	return out


func _wizard(side: int) -> Vector2:
	for f in c.state.figures:
		if f.side==side and f.def.role=="wizard" and placed.has(f.id):
			return f.pos
	return Vector2.INF


func choose(choice: int) -> bool:
	if done or active<0 or not available().has(choice) or zones.has(active):
		return false
	var units:=c.state.side_figures(active)
	units.sort_custom(func(a: Figure,b: Figure) -> bool:
		var rank_a:=0 if a.def.role=="wizard" else (1 if a.def.role=="apprentice" else 2)
		var rank_b:=0 if b.def.role=="wizard" else (1 if b.def.role=="apprentice" else 2)
		return rank_a<rank_b or (rank_a==rank_b and a.id<b.id))
	var original: Dictionary={}
	for f in units:
		original[f.id]={"at":f.pos,"height":f.elevation,"surface":f.surface_id}
		var points:=DeploymentRules.options(c.state,f,choice,_ignored(),_wizard(active))
		var p:=DeploymentStrategy.best(c.state,f,points,choice,placed)
		if p.is_empty():
			for id in original:
				_apply(c.state.figure(id),original[id])
				placed.erase(id)
			error="That zone cannot fit the whole warband. Choose another."
			return false
		_apply(f,p)
		placed[f.id]=true
	zones[active]=choice
	c.state.scenario_data["deployment_zones"]=zones.duplicate()
	error=""
	return true


func points(id: int) -> Array[Dictionary]:
	var f:=c.state.figure(id)
	if done or f==null or active!=human or f.side!=human or not zones.has(human):
		return []
	var options:=DeploymentRules.options(c.state,f,int(zones[human]),_ignored(),_wizard(human))
	if DeploymentRules.kind(c.state)=="ring" and f.def.role=="wizard":
		# Moving the wizard must keep all already placed followers in range.
		options=options.filter(func(p: Dictionary) -> bool:
			for other in c.state.side_figures(human):
				if other!=f and other.pos.distance_to(p["at"])>3.0:
					return false
			return true)
	return options


func move(id: int,point: Dictionary) -> bool:
	for legal_point in points(id):
		if legal_point==point:
			_apply(c.state.figure(id),point)
			return true
	return false


func confirm() -> bool:
	if active!=human or not zones.has(human) or done:
		return false
	index+=1
	advance()
	return done


func visible(f: Figure) -> bool:
	if treasure_stage==4 and f.side<0:
		return c.state.side_figures(-1).find(f)<4
	return f.side<0 or placed.has(f.id)


func _apply(f: Figure,p: Dictionary) -> void:
	f.pos=p["at"]
	f.elevation=float(p["height"])
	f.surface_id=str(p["surface"])
