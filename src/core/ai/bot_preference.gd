class_name BotPreference
extends RefCounted
## Imperfect warband judgment, not altered rules or combat dice. Stable for a
## figure/turn/choice, so previews and replay never consume a random roll.
const SHOT_POSITIONS:=32
## Independent enduring tendencies; no role, equipment or definition input.
static func trait_value(f: Figure,axis: String) -> float:
	if f.side<0:
		return 0.5
	var identity:=f.campaign_id if f.campaign_id>=0 else f.id
	return float(posmod(hash([identity,f.original_side,axis,"individual"]),1001))/1000.0

static func profile(f: Figure) -> Dictionary:
	return {"aggression":trait_value(f,"aggression"),"greed":trait_value(f,"greed"),"caution":trait_value(f,"caution"),"loyalty":trait_value(f,"loyalty"),"deliberation":trait_value(f,"deliberation")}

static func threat_appeal(f: Figure,t: Figure) -> float:
	if f.side<0:
		return 1.0
	return 1.0+(trait_value(f,"aggression")-0.5)*0.3*clampf(float(t.effective_fight())/5.0,0.0,1.0)+(trait_value(f,"greed")-0.5)*0.35*float(t.treasure_id>=0)

static func spell_appeal(f: Figure,id: String) -> float:
	if id in MagicTactics.ATTACKS:
		return 0.9+0.2*trait_value(f,"aggression")
	if id=="heal" or id in MagicTactics.BUFFS:
		return 0.9+0.2*trait_value(f,"loyalty")
	return 1.0

## A strongly aggressive figure may engage a visible nearby opponent instead
## of pursuing distant loot. Mandatory scenario moves and carriers exempt.
static func prefers_combat(s: GameState,f: Figure) -> bool:
	if f.side<0 or f.treasure_id>=0 or not (s.board.id in ["frozen_ruins","sunken_streets","worm_hunts","genie_in_the_bottle"]):
		return false
	if not s.treasures.any(func(t: TreasureToken) -> bool:return t.on_ground()):
		return false
	var urge:=trait_value(f,"aggression")-trait_value(f,"greed")-0.3*trait_value(f,"caution")+0.15*variation(s,f,0,"initiative")
	if urge<0.35:
		return false
	for other in s.figures:
		if other.in_play() and other.side!=f.side and other.ring_side==f.ring_side and Shooting.distance(f,other)<=5.0 and BotTargets.can_harm(f,other,f.melee) and IllusionRules.visible_to(s.figures,f,other) and LineOfSight.check_figures(s.board,f,other).clear:
			return true
	return false


static func variation(s: GameState,f: Figure,choice: int,context: String) -> float:
	if f.side<0:
		return 0.0
	return float(posmod(hash([s.turn,f.id,choice,context]),2001))/1000.0-1.0


static func appeal(s: GameState,f: Figure,choice: int,context: String) -> float:
	return 1.0+(0.12+0.2*(1.0-trait_value(f,"deliberation")))*variation(s,f,choice,context)


## Sample a finite number of reachable firing positions. The search need
## not exhaustively examine every half-inch cell to simulate a real player.
static func positions(s: GameState,f: Figure,nodes: Array) -> Array:
	var budget:=roundi(lerpf(20.0,float(SHOT_POSITIONS),trait_value(f,"deliberation")))
	if f.side<0 or nodes.size()<=budget:
		return nodes
	var selected: Array=[]
	var phase:=0.5+0.49*variation(s,f,0,"firing_positions")
	for i in budget:
		var index:=mini(nodes.size()-1,floori((i+phase)*float(nodes.size())/budget))
		selected.append(nodes[index])
	return selected
