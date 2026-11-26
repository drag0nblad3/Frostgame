class_name BattleSnapshotParts
extends RefCounted
## Encode live definitions, dynamic terrain and ID-based links without objects.
const FIGURE := ["id", "campaign_id", "injury_types", "familiar", "beauty_tests", "last_plane_attempt", "plane_attempts", "campaign_base", "original_side", "controller_id", "control_spell", "control_roll", "summoned_by", "prepared_demon_caster", "summon_spell", "side", "pos", "elevation", "surface_id", "health", "out_of_action", "exited", "treasure_id", "second_treasure_id", "shrunk_treasure_id", "disengaged", "spell_effects", "items", "elemental_shield", "poisoned", "poison_weapon", "empowerment_used", "used_gear", "next_cast_gear", "petrified_skip", "magic_exhausted", "last_time_walk", "walk_phases", "stored_action_turn", "used_stored_action", "non_moves", "activated", "actions_left", "moves_taken", "acted", "loaded", "destroyed_weapons"]
const DEFINITION := ["id", "name", "role", "move", "fight", "shoot", "armour", "will", "health", "cost", "specialist", "shield", "traits", "verify"]
const BOARD := ["id", "name", "size", "darkness", "floor_layout"]
const TERRAIN := ["rect", "circular", "eye_direction", "ramp", "ramp_rotated", "ramp_start", "ramp_end", "level", "cast_turn", "caster_id"]
const KIND := ["id", "name", "blocks_los", "blocks_move", "cover", "move_mult", "height", "walkable_top", "stairs", "ground_surface"]


static func figure_data(f: Figure) -> Dictionary:
	var out := BattleSnapshot.pack(f, FIGURE)
	var definition := BattleSnapshot.pack(f.def, DEFINITION)
	var weapons: Array[String] = []
	for w in f.def.weapons:
		weapons.append(w.id)
	definition["weapons"] = weapons
	out["definition"] = definition
	out["melee"] = f.melee.id if f.melee != null else ""
	out["ranged"] = f.ranged.id if f.ranged != null else ""
	return out


static func make_figure(d: Dictionary, db: FigureDb) -> Figure:
	var info: Dictionary = d["definition"]
	if not db.figures.has(info["id"]):
		return null
	var definition := FigureDef.from_dict(info["id"], info, db.weapons)
	var f := Figure.new(d["id"], definition, d["side"], d["pos"], db.unarmed())
	BattleSnapshot.restore(f, d, FIGURE)
	f.melee = db.weapons.get(d["melee"])
	f.ranged = db.weapons.get(d["ranged"])
	return f


static func board_data(board: Board) -> Dictionary:
	var out := BattleSnapshot.pack(board, BOARD)
	var pieces: Array = []
	for p in board.pieces:
		var row := BattleSnapshot.pack(p, TERRAIN)
		row["kind"] = BattleSnapshot.pack(p.kind, KIND)
		row["eye_host"] = board.pieces.find(p.eye_host)
		pieces.append(row)
	out["pieces"] = pieces
	return out


static func make_board(d: Dictionary) -> Board:
	var board := Board.new()
	BattleSnapshot.restore(board, d, BOARD)
	for entry: Dictionary in d["pieces"]:
		var kind := TerrainKind.new()
		BattleSnapshot.restore(kind, entry["kind"], KIND)
		var p := TerrainPiece.new(kind, entry["rect"])
		BattleSnapshot.restore(p, entry, TERRAIN)
		board.pieces.append(p)
	for i in board.pieces.size():
		var host := int(d["pieces"][i]["eye_host"])
		if host >= 0 and host < board.pieces.size():
			board.pieces[i].eye_host = board.pieces[host]
	board.invalidate_terrain()
	return board
