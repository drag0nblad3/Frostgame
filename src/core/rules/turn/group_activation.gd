class_name GroupActivation
extends RefCounted
## Explicit early-phase group declaration, movement pass, and second-action pass (p. 43).

enum { NONE, MOVEMENT, SECOND }

var stage := NONE
var side := -1
var members: Array[int] = []
var pending: Array[int] = []


func in_progress() -> bool:
	return stage != NONE


func movement_pass() -> bool:
	return stage == MOVEMENT


func can_begin(s: GameState, owner: int) -> bool:
	if in_progress() or s.phase not in [Phase.WIZARD, Phase.APPRENTICE]:
		return false
	if not s.early.leaders.has(owner) or s.early.closed.get(owner, false):
		return false
	var leader := s.figure(s.early.leaders[owner])
	return leader.in_play() and not leader.activated and int(s.early.used[owner]) == 0 and s.early.waiting(s, owner).size() > 1


func begin(s: GameState, owner: int, ids: Array[int]) -> bool:
	if not can_begin(s, owner) or ids.size() < 2 or ids.size() > s.figure(s.early.leaders[owner]).early_limit() + 1 or not ids.has(s.early.leaders[owner]):
		return false
	var candidates := s.early.waiting(s, owner)
	var seen: Array[int] = []
	for id in ids:
		if seen.has(id) or not candidates.has(s.figure(id)) or s.figure(id).spell_effects.has("possess"):
			return false
		seen.append(id)
	side = owner
	members.assign(ids)
	pending.assign(ids)
	stage = MOVEMENT
	return true


func waiting(s: GameState) -> Array[Figure]:
	var out: Array[Figure] = []
	for id in pending:
		var f := s.figure(id)
		if f != null and f.in_play():
			out.append(f)
	return out


func start_member(s: GameState, f: Figure) -> void:
	f.actions_left = 0 if f.action_limit() == 0 or (stage == SECOND and f.action_limit() == 1 and f.moves_taken > 0) else 1
	if RedKingSquatter.failed_this_turn(s,f):
		f.actions_left=0
	if movement_pass():
		s.early.record_activation(s, f)
		f.moves_taken = 0
		f.acted = false
		f.non_moves = 0
		f.used_stored_action = false


## Returns true once the entire group has finished. Both passes allow any member order.
func finish_member(s: GameState, f: Figure) -> bool:
	pending.erase(f.id)
	if stage == SECOND:
		f.activated = true
	if not waiting(s).is_empty():
		return false
	if movement_pass():
		stage = SECOND
		pending.clear()
		for id in members:
			var member := s.figure(id)
			if member.in_play():
				pending.append(id)
		if not pending.is_empty():
			return false
	for id in members:
		s.figure(id).activated = true
	s.early.closed[side] = true
	stage = NONE
	side = -1
	members.clear()
	pending.clear()
	return true
