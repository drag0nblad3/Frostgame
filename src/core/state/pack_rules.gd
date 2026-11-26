class_name PackRules
extends RefCounted
## Connected uncontrolled pack hunters share a randomly selected leader and
## pursuit direction. Individual moves use legal controller actions so reactions
## can interrupt the sequence without losing the remaining members.

static func members(s: GameState, first: Figure) -> Array[Figure]:
	var out: Array[Figure] = [first]
	if first.side >= 0 or not first.def.traits.has("pack_hunter"):
		return out
	var i := 0
	while i < out.size():
		var member := out[i]
		for other in s.figures:
			if other.side < 0 and other.in_play() and not other.activated and other.def.traits.has("pack_hunter") and not out.has(other) and Contact.figures_touch(member, other):
				out.append(other)
		i += 1
	return out


static func select(c: GameController, first: Figure) -> Figure:
	var s := c.state
	if s.phase != Phase.CREATURE:
		return first
	if not s.pack_queue.is_empty():
		if s.pack_queue.has(first.id):
			return first
		clear(s)
	var group := members(s, first)
	if group.size() < 2:
		return first
	var leader := group.pop_at(c.dice.pick(group.size())) as Figure
	s.pack_leader = leader.id
	s.pack_queue.append(leader.id)
	for member in group:
		s.pack_queue.append(member.id)
	c.emit("pack_start", {"id": leader.id, "members": s.pack_queue.duplicate()})
	return leader


static func clear(s: GameState) -> void:
	s.pack_queue.clear()
	s.pack_leader = -1
	s.pack_target = -1
	s.pack_heading = Vector2.ZERO


static func finish(s: GameState, f: Figure) -> void:
	if not s.pack_queue.has(f.id):
		return
	s.pack_queue.erase(f.id)
	if s.pack_queue.is_empty():
		clear(s)


static func pursuit(s: GameState, f: Figure) -> Figure:
	if f.id == s.pack_leader or not s.pack_queue.has(f.id):
		return null
	var t := s.figure(s.pack_target)
	if t != null and t.in_play() and t.side >= 0 and IllusionRules.visible_to(s.figures, f, t):
		return t
	return null


static func remember(s: GameState, f: Figure, t: Figure) -> void:
	if f.id == s.pack_leader:
		s.pack_target = t.id if t != null else -1


static func heading(c: GameController, f: Figure) -> Vector2:
	var s := c.state
	if s.pack_queue.has(f.id) and s.pack_heading != Vector2.ZERO:
		return s.pack_heading
	var direction := Vector2.RIGHT.rotated(TAU * c.dice.pick(20) / 20.0)
	if s.pack_queue.has(f.id):
		s.pack_heading = direction
	return direction
