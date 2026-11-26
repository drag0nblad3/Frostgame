class_name BoardLoader
extends RefCounted
## Builds a Board from data/boards/<id>.json:
## {"id", "name", "size": [w, h], "pieces": [{"kind", "rect": [x, y, w, h]}]}

const DIR := "res://data/boards/"


static func load_id(board_id: String, terrain: TerrainDb) -> Board:
	return from_dict(JsonFile.read(DIR + board_id + ".json"), terrain)


static func from_dict(d: Dictionary, terrain: TerrainDb) -> Board:
	var b := Board.new()
	b.id = d.get("id", "")
	b.name = d.get("name", b.id)
	var s: Array = d.get("size", [36, 36])
	b.size = Vector2(s[0], s[1])
	b.floor_layout = d.get("floor_layout",{}).duplicate(true)
	for p: Dictionary in d.get("pieces", []):
		var r: Array = p["rect"]
		var piece := TerrainPiece.new(terrain.get_kind(p["kind"]), Rect2(r[0], r[1], r[2], r[3]))
		piece.circular = piece.kind.id in ["arcane_disc","red_king_portal","red_king_sinkhole_orb"]
		piece.level = p.get("level",null)
		var profile: Dictionary = p.get("ramp",{})
		if not profile.is_empty():
			piece.ramp = true
			piece.ramp_rotated = profile.get("axis","x") == "y"
			piece.ramp_start = float(profile.get("start",0.0))
			piece.ramp_end = float(profile.get("end",0.0))
		b.pieces.append(piece)
	var boundaries: Array[Dictionary]=[]
	for entry: Dictionary in d.get("boundaries",[]):
		var a: Array=entry.get("a",[])
		var z: Array=entry.get("b",[])
		if a.size()!=2 or z.size()!=2:
			continue
		var line := entry.duplicate(true)
		line["a"]=Vector2(a[0],a[1])
		line["b"]=Vector2(z[0],z[1])
		if line["a"]!=line["b"]:
			boundaries.append(line)
	b.set_boundaries(boundaries)
	return b
