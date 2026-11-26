class_name BattleSnapshot
extends RefCounted
## Local, versioned checkpoint. No objects or suspended callbacks are deserialized.
const VERSION := 1
const PATH := "user://frostgame_battle_v1.dat"
const STATE := ["side_names", "side_schools", "turn", "phase", "push_winner", "push_loser", "forced_combat", "reaction_side", "random_encounters", "museum", "scenario_special", "scenario_data", "worm_spawned", "well_drinkers", "discovered_huts", "disc_travellers", "lamp_token", "genie_id", "genie_kills", "tower_visitors", "column_fighters", "reinforcement_points", "spellbooks", "spell_catalog", "storm_penalty", "words", "fast_acts", "pack_queue", "pack_leader", "pack_target", "pack_heading", "telescope_ready", "pending_initiative", "order", "order_index", "active_id", "winner", "over", "critical_hits"]
const EARLY := ["leaders", "eligible", "used", "closed"]
const GROUP := ["stage", "side", "members", "pending"]
const TOKEN := ["id", "pos", "surface_id", "carrier_id", "secured_by", "lost", "ever_collected", "central", "frozen"]


static func can_save(c: GameController) -> bool:
	if c == null or c.state.over:
		return false
	var s := c.state
	return s.pending_intercept.is_empty() and s.pending_cast.is_empty() and s.pending_resistance.is_empty() and s.pending_combat.is_empty() and c._magic.shatter.first.is_empty() and c._magic.shatter.next.is_empty() and not c._magic.shatter.resolving


static func pack(obj: Object, fields: Array) -> Dictionary:
	var out := {}
	for key: String in fields:
		var value: Variant = obj.get(key)
		if value is Array or value is Dictionary:
			value = value.duplicate(true)
		out[key] = value
	return out


static func restore(obj: Object, values: Dictionary, fields: Array) -> void:
	for key: String in fields:
		if not values.has(key):
			continue
		var current: Variant = obj.get(key)
		if current is Array:
			current.assign(values[key])
			obj.set(key, current)
		else:
			obj.set(key, values[key])


static func plain(value: Variant) -> bool:
	if value is Object or value is Callable or value is Signal or value is RID:
		return false
	if value is Array:
		for child in value:
			if not plain(child):
				return false
	if value is Dictionary:
		for key in value:
			if not plain(key) or not plain(value[key]):
				return false
	return true


static func capture(c: GameController, meta: Dictionary = {}) -> Dictionary:
	if not can_save(c):
		return {}
	var s := c.state
	var saved_meta := meta.duplicate(true)
	saved_meta["expansions"]=s.content_profile.enabled.duplicate()
	var out := {"version": VERSION, "meta": saved_meta, "state": pack(s, STATE), "early": pack(s.early, EARLY), "group": pack(s.group, GROUP), "board": BattleSnapshotParts.board_data(s.board), "figures": [], "treasures": [], "history": [], "rng": c.dice._rng.state}
	for figure in s.figures:
		out["figures"].append(BattleSnapshotParts.figure_data(figure))
	for token in s.treasures:
		out["treasures"].append(pack(token, TOKEN))
	for event in c.history:
		if plain(event.data):
			out["history"].append({"type": event.type, "data": event.data.duplicate(true)})
	return out if plain(out) else {}


static func rebuild(d: Dictionary, db: FigureDb) -> GameController:
	if d.get("version", -1) != VERSION:
		return null
	for key: String in ["state", "early", "group", "board", "figures", "treasures", "history", "rng"]:
		if not d.has(key):
			return null
	var profile := ContentProfile.new(d.get("meta",{}).get("expansions",[]),db.content_profile.packs)
	if not profile.errors().is_empty() or not db.content_profile.same(profile.enabled):
		return null
	var s := GameState.new()
	s.content_profile=profile
	s.creature_db = db
	s.board = BattleSnapshotParts.make_board(d["board"])
	restore(s, d["state"], STATE)
	restore(s.early, d["early"], EARLY)
	restore(s.group, d["group"], GROUP)
	for entry: Dictionary in d["figures"]:
		var figure := BattleSnapshotParts.make_figure(entry, db)
		if figure == null:
			return null
		s.figures.append(figure)
	for entry: Dictionary in d["treasures"]:
		var token := TreasureToken.new(entry["id"], entry["pos"])
		restore(token, entry, TOKEN)
		s.treasures.append(token)
	var dice := Dice.new(1)
	dice._rng.state = int(d["rng"])
	var c := GameController.new(s, dice)
	for entry: Dictionary in d["history"]:
		c.history.append(GameEvent.new(entry["type"], entry["data"]))
	return c


static func save(c: GameController, meta: Dictionary = {}, path: String = "") -> bool:
	if path.is_empty():
		path=WarbandSlots.path_for(PATH)
	var data := capture(c, meta)
	if data.is_empty():
		return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_var(data, false)
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path) == OK


static func read(path: String = "") -> Dictionary:
	if path.is_empty():
		path=WarbandSlots.path_for(PATH)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 32 * 1024 * 1024:
		return {}
	var data: Variant = file.get_var(false)
	if not data is Dictionary or data.get("version", -1) != VERSION or not plain(data):
		return {}
	return data
