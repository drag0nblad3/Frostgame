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
	for p: Dictionary in d.get("pieces", []):
		var r: Array = p["rect"]
		var piece := TerrainPiece.new(terrain.get_kind(p["kind"]), Rect2(r[0], r[1], r[2], r[3]))
		piece.circular = piece.kind.id == "arcane_disc"
		b.pieces.append(piece)
	return b
