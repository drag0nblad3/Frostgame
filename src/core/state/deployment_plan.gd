class_name DeploymentPlan
extends RefCounted
## Deterministic draft. Only GameController commits it.
var state: GameState
var scenario: String
var human: int
var rolls: Array[int]=[]
var winner:=0
var edge: Array[int]=[0,2]
var placements: Dictionary={}
var error:=""
var candidates: Dictionary={}


func _init(s: GameState,id: String,side: int,dice: Dice) -> void:
	state=s
	scenario=id
	human=clampi(side,0,1)
	var options:=DeploymentRules.choices(scenario)
	if options.is_empty():
		return
	if options.size()>1:
		rolls=[dice.d20(),dice.d20()]
		while rolls[0]==rolls[1]:
			rolls=[dice.d20(),dice.d20()]
		winner=0 if rolls[0]>rolls[1] else 1
	else:
		winner=0
	for e in options:
		candidates[e]=DeploymentRules.points(state,scenario,e)
	choose(_best_edge(options))


func can_choose() -> bool:
	return winner==human and DeploymentRules.choices(scenario).size()>1


func choose(value: int) -> bool:
	if not DeploymentRules.choices(scenario).has(value):
		return false
	edge[winner]=value
	edge[1-winner]=DeploymentRules.rival(scenario,value)
	placements.clear()
	error=""
	_auto(winner)
	_auto(1-winner)
	return complete()


func _best_edge(options: Array[int]) -> int:
	var best:=options[0]
	var score:=-INF
	for candidate in options:
		var pts: Array=candidates[candidate]
		var value:=float(pts.size())*0.04
		var origin:=DeploymentRules.edge_point(state.board.size,candidate)
		if DeploymentRules.mode(scenario).begins_with("corner"):
			origin=Vector2.ZERO if candidate==0 else Vector2(state.board.size.x,0)
		for t in state.treasures:
			if t.on_ground() and not t.frozen:
				value+=12.0/maxf(2.0,origin.distance_to(t.pos))
		if value>score:
			best=candidate
			score=value
	return best


func _auto(side: int) -> void:
	var members:=state.side_figures(side)
	if members.is_empty():
		return
	var pts: Array=candidates.get(edge[side],[])
	var caster: Variant=null
	for f in members:
		var best: Dictionary={}
		var score:=-INF
		for at: Vector2 in pts:
			var legal:=DeploymentRules.legal(state,at,placements,f.id)
			if legal.is_empty():
				continue
			var value:=DeploymentStrategy.score(state,f,at,float(legal["height"]),caster,placements)
			if value>score:
				score=value
				best=legal
		if best.is_empty():
			error="No legal starting position for "+f.label()
			continue
		placements[f.id]=best
		if f.def.role=="wizard" or (caster==null and f.def.role=="apprentice"):
			caster=best["at"]


func move(id: int,at: Vector2) -> bool:
	var f:=state.figure(id)
	if f==null or f.side!=human or not DeploymentRules.zone(scenario,state.board.size,edge[human],at):
		return false
	var p:=DeploymentRules.legal(state,at,placements,id)
	if p.is_empty():
		return false
	placements[id]=p
	return true


func auto_human() -> void:
	for f in state.side_figures(human):
		placements.erase(f.id)
	error=""
	_auto(human)


func complete() -> bool:
	for f in state.figures:
		if f.side>=0 and f.in_play() and not placements.has(f.id):
			return false
	return true


func finalize() -> bool:
	if human==winner:
		for f in state.side_figures(1-human):
			placements.erase(f.id)
		_auto(1-human)
	return complete()
