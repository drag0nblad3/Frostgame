class_name RedKingRingworld
extends RefCounted
## Scenario twelve (Red King pp.57–60): two overlapping realities.
const ID := "red_king_ringworld"
const MARKERS := [Vector2(15,18),Vector2(5.1,6.1),Vector2(24.9,6.1),Vector2(5.1,29.9),Vector2(24.9,29.9)]


static func active(s: GameState) -> bool:
	return s!=null and s.scenario_special==ID


static func key_master(f: Figure) -> bool:
	return f!=null and f.def.id=="red_king_key_master"


static func setup(s: GameState) -> void:
	s.board.wrap_short_edges=true
	s.board.ringworld=true
	for token in s.treasures:
		token.ring_side=1 if token.id in [0,2,3] else 0
		token.central=true
	s.board.invalidate_terrain()


static func remaining(s: GameState) -> int:
	var count := 0
	for f in s.figures:
		if key_master(f) and f.in_play():
			count+=1
	return count
