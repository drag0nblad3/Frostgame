class_name BotPreference
extends RefCounted
## Imperfect warband judgment, not altered rules or combat dice. Stable for a
## figure/turn/choice, so previews and replay never consume a random roll.
const SHOT_POSITIONS:=32

static func variation(s: GameState,f: Figure,choice: int,context: String) -> float:
	if f.side<0:
		return 0.0
	return float(posmod(hash([s.turn,f.id,choice,context]),2001))/1000.0-1.0


static func appeal(s: GameState,f: Figure,choice: int,context: String) -> float:
	return 1.0+0.22*variation(s,f,choice,context)


## Sample a finite number of reachable firing positions. The search need
## not exhaustively examine every half-inch cell to simulate a real player.
static func positions(s: GameState,f: Figure,nodes: Array) -> Array:
	if f.side<0 or nodes.size()<=SHOT_POSITIONS:
		return nodes
	var selected: Array=[]
	var phase:=0.5+0.49*variation(s,f,0,"firing_positions")
	for i in SHOT_POSITIONS:
		var index:=mini(nodes.size()-1,floori((i+phase)*float(nodes.size())/SHOT_POSITIONS))
		selected.append(nodes[index])
	return selected
