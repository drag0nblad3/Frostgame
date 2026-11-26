class_name EarlyPhase
extends RefCounted
## Wizard/apprentice phase eligibility snapshot and normal individual activations (pp. 40–43).
## Separate group activation (all movement before second actions) is a later rule.

const MAX_SOLDIERS := 3
const RANGE := 3.0

var leaders := {}
var eligible := {}
var used := {}
var closed := {}


func capture(s: GameState) -> void:
	leaders.clear()
	eligible.clear()
	used.clear()
	closed.clear()
	if s.phase not in [Phase.WIZARD, Phase.APPRENTICE]:
		return
	for side in s.side_count():
		var leader: Figure = null
		for f in s.side_figures(side):
			if Phase.of_figure(f) == s.phase and not f.activated:
				leader = f
				break
		if leader == null:
			continue
		leaders[side] = leader.id
		used[side] = 0
		var ids: Array[int] = []
		for soldier in s.side_figures(side):
			if soldier.activated or Phase.of_figure(soldier) != Phase.SOLDIER:
				continue
			var edge_distance := Shooting.distance(leader, soldier)
			if edge_distance <= RANGE and LineOfSight.check(s.board, leader.pos, soldier.pos).clear:
				ids.append(soldier.id)
		eligible[side] = ids


func waiting(s: GameState, side: int) -> Array[Figure]:
	var out: Array[Figure] = []
	if not leaders.has(side) or closed.get(side, false):
		return out
	var leader := s.figure(leaders[side])
	# If a rival removed the leader before its side started, it gets no early activations.
	if not leader.in_play() and not leader.activated:
		return out
	if leader.in_play() and not leader.activated and not s.is_fast(leader):
		out.append(leader)
	if int(used[side]) >= MAX_SOLDIERS:
		return out
	for id: int in eligible[side]:
		var f := s.figure(id)
		if f.in_play() and f.side == side and not f.activated and not s.is_fast(f):
			out.append(f)
	return out


func record_activation(s: GameState, f: Figure) -> void:
	if s.phase in [Phase.WIZARD, Phase.APPRENTICE] and Phase.of_figure(f) == Phase.SOLDIER:
		used[f.side] = int(used.get(f.side, 0)) + 1


func can_finish(s: GameState, side: int) -> bool:
	if s.phase not in [Phase.WIZARD, Phase.APPRENTICE] or not leaders.has(side) or closed.get(side, false):
		return false
	var leader := s.figure(leaders[side])
	return leader.activated and not waiting(s, side).is_empty()
