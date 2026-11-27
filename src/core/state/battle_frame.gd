class_name BattleFrame
extends RefCounted
## Small presentation snapshots, not executable saves. No RNG or rule queries.
const LIMIT := 256


static func capture(c: GameController) -> Dictionary:
	var s := c.state
	var figures: Array=[]
	var tokens: Array=[]
	var terrain: Array=[]
	var floors: Array=[]
	for f in s.figures:
		figures.append({"id":f.id,"name":f.label(),"side":f.side,"pos":f.pos,"height":f.elevation,"surface":f.surface_id,"health":f.health,"max_health":f.def.health,"in_play":f.in_play(),"ring":f.ring_side})
	for t in s.treasures:
		if t.on_ground():
			tokens.append({"id":t.id,"pos":t.pos,"surface":t.surface_id})
	for p in s.board.pieces:
		terrain.append({"rect":p.rect,"surface":p.surface_id,"solid":p.kind.blocks_move,"circular":p.circular})
	if not s.board.floor_layout.is_empty():
		for surface in s.board.floor_geometry().surfaces:
			if not surface.id.begins_with("climb:"):
				floors.append({"id":surface.id,"rect":surface.rect,"height":surface.level})
	return {"event_end":c.history.size(),"turn":s.turn,"active":s.active_id,"size":s.board.size,"figures":figures,"tokens":tokens,"terrain":terrain,"floors":floors,"voids":s.board.void_regions.duplicate()}


static func record(c: GameController) -> void:
	if not c.capture_frames:
		return
	var frame := capture(c)
	var history := c.replay_frames
	if not history.is_empty() and history[-1]["event_end"]==frame["event_end"]:
		history[-1]=frame
	else:
		history.append(frame)
	if history.size()>LIMIT:
		history.pop_front()


## Never show a future frame for an earlier event.
static func at_or_before(frames: Array[Dictionary],event_end: int) -> Dictionary:
	var lo := 0
	var hi := frames.size()
	while lo<hi:
		var mid := (lo+hi)>>1
		if int(frames[mid]["event_end"])<=event_end:
			lo=mid+1
		else:
			hi=mid
	return frames[lo-1] if lo>0 else {}
