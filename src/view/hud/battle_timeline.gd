class_name BattleTimeline
extends RefCounted
## Read-only presentation snapshot built only while the controller is idle.
## This is an event timeline, not a reconstruction of historical board state.


static func build(s: GameState,events: Array[GameEvent]) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var turn := 0
	var phase := ""
	for event in events:
		if event.type=="turn_start":
			turn=int(event.data.get("turn",turn))
			phase=""
		elif event.type=="phase":
			phase=Phase.name_of(event.data["phase"])
		var line := Explainer.text(s,event)
		var roll := RollSummary.describe(s,event)
		if line.is_empty() and event.type in ["activate","end_activation"]:
			line=Explainer.name_of(s,int(event.data["id"]))+(" begins activation." if event.type=="activate" else " ends activation.")
		if line.is_empty() and roll.is_empty():
			continue
		result.append({"turn":turn,"phase":phase,"type":event.type,"line":line,"roll":roll})
	return result


## Jump to the first recorded beat in a strictly earlier/later turn.
static func turn_jump(entries: Array[Dictionary],index: int,direction: int) -> int:
	if entries.is_empty():
		return 0
	index=clampi(index,0,entries.size()-1)
	var turn := int(entries[index]["turn"])
	if direction>0:
		for i in range(index+1,entries.size()):
			if int(entries[i]["turn"])>turn:
				return i
	else:
		for i in range(index-1,-1,-1):
			if int(entries[i]["turn"])<turn:
				while i>0 and entries[i-1]["turn"]==entries[i]["turn"]:
					i-=1
				return i
	return index
