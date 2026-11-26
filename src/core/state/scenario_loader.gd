class_name ScenarioLoader
extends RefCounted
## Builds a GameState from data/scenarios/<id>.json: a board id plus
## warbands, each a name and figures {"type", "at": [x, y]} in inches.

const DIR := "res://data/scenarios/"


static func load_id(scenario_id: String, figures: FigureDb, terrain: TerrainDb) -> GameState:
	return from_dict(JsonFile.read(DIR + scenario_id + ".json"), figures, terrain)


static func from_dict(d: Dictionary, figures: FigureDb, terrain: TerrainDb) -> GameState:
	var s := GameState.new()
	s.board = BoardLoader.load_id(d["board"], terrain)
	var next_id := 1
	var warbands: Array = d.get("warbands", [])
	for side in warbands.size():
		var wb: Dictionary = warbands[side]
		s.side_names.append(wb.get("name", "Warband %d" % (side + 1)))
		for entry: Dictionary in wb.get("figures", []):
			var at: Array = entry["at"]
			var def := figures.get_def(entry["type"])
			s.figures.append(Figure.new(next_id, def, side, Vector2(at[0], at[1]), figures.unarmed()))
			next_id += 1
	return s
