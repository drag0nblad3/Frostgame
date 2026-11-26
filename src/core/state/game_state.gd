class_name GameState
extends RefCounted
## Everything about a game in progress. Only GameController changes it.

const MAX_TURNS := 12

var board: Board
var figures: Array[Figure] = []
var side_names: Array[String] = []
var turn := 0
var phase := Phase.WIZARD
var early := EarlyPhase.new()
var group := GroupActivation.new()
var push_winner := -1
var push_loser := -1
var forced_combat := false
# -2 means no human reaction owner (headless / watch).
var reaction_side := -2
var pending_intercept := {}
var random_encounters := false
var museum := false
var scenario_special := ""
var worm_spawned := false
var well_drinkers := {}
var reinforcement_points: Array[Vector2] = []
var creature_db: FigureDb
var spellbooks := {}
var spell_catalog := {}
var pending_cast := {}
var pending_resistance := {}
var pending_combat := {}
var storm_penalty := 0
var words: Array[Dictionary] = []
var fast_acts := {}
## Sides in initiative order this turn, and whose go it is within the phase.
var telescope_ready := {}
var pending_initiative := false
var order: Array[int] = []
var order_index := 0
var active_id := -1
var winner := -1
var over := false
## Optional rule, disabled by default (Second Edition p. 55).
var critical_hits := false
var treasures: Array[TreasureToken] = []


func treasure(id: int) -> TreasureToken:
	for token in treasures:
		if token.id == id:
			return token
	return null


func secured_count(side: int) -> int:
	var count := 0
	for token in treasures:
		if token.secured_by == side:
			count += 1
	return count


func side_count() -> int:
	return side_names.size()


func current_side() -> int:
	if phase == Phase.CREATURE:
		return -1
	if order.is_empty():
		return -1
	return order[order_index]


func figure(id: int) -> Figure:
	for f in figures:
		if f.id == id:
			return f
	return null


func active() -> Figure:
	return figure(active_id)


func side_figures(side: int) -> Array[Figure]:
	var out: Array[Figure] = []
	for f in figures:
		if f.side == side and f.in_play():
			out.append(f)
	return out


## Figures of `side` still waiting to activate in the current phase.
func waiting(side: int) -> Array[Figure]:
	if phase == Phase.CREATURE:
		var creatures: Array[Figure] = []
		for f in side_figures(-1):
			if not f.activated:
				creatures.append(f)
		creatures.sort_custom(func(a: Figure, b: Figure) -> bool: return a.health > b.health or (a.health == b.health and a.id < b.id))
		if creatures.size() > 1:
			creatures.resize(1)
		return creatures
	if group.in_progress() and group.side == side:
		return group.waiting(self)
	var out: Array[Figure] = []
	if phase in [Phase.WIZARD, Phase.APPRENTICE]:
		out.assign(early.waiting(self, side))
	else:
		for f in side_figures(side):
			if not f.activated and Phase.of_figure(f) == phase and not is_fast(f):
				out.append(f)
	for f in side_figures(side):
		if f.spell_effects.has("time_walk") and f.walk_phases.has(phase):
			out.append(f)
	if out.is_empty():
		for id: int in fast_acts.get(side, []):
			var f := figure(id)
			if f != null and f.in_play() and not f.activated:
				out.append(f)
	return out


func is_fast(f: Figure) -> bool:
	for ids: Array in fast_acts.values():
		if ids.has(f.id):
			return true
	return false


func queue_fast(f: Figure, side: int) -> void:
	if not fast_acts.has(side):
		fast_acts[side] = []
	fast_acts[side].append(f.id)
