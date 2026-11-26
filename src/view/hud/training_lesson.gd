class_name TrainingLesson
extends RefCounted
## Standalone practice encounters. All actions use normal game rules.

const NAMES := ["Move & collect", "Carry & escape", "Melee combat", "Cast a spell"]
const HINTS := [
	"Activate your wizard. Move onto or next to the gold chest, then use Collect and tap the chest.",
	"Your wizard already carries treasure. Choose Exit, then tap a highlighted edge to leave safely.",
	"Activate your wizard, Move into contact with the skeleton, then Fight. Both figures roll; compare the totals.",
	"Activate your wizard. Cast Strength on yourself, then resolve the roll. You can spend Health to empower it."
]


static func build(index: int, db: FigureDb, terrain: TerrainDb) -> GameState:
	var at := [9, 4]
	var treasures := [[9, 7], [15, 15]]
	var creatures: Array = []
	var spells := {}
	match index:
		1:
			at = [9, 2]
			treasures[0] = at
		2:
			creatures.append({"type": "skeleton", "at": [9, 7]})
		3:
			spells = {"strength": 12}
	var s := ScenarioLoader.from_dict({"board": "training_yard", "warbands": [{"name": "Student", "figures": [{"type": "wizard", "at": at}], "spells": spells}, {"name": "Sparring partner", "figures": [{"type": "thug", "at": [16, 16]}]}], "creatures": creatures, "treasures": treasures, "random_encounters": false, "forced_combat": false}, db, terrain)
	if index == 1:
		s.figure(1).treasure_id = 0
		s.treasure(0).carrier_id = 1
		s.treasure(0).ever_collected = true
	return s


static func completed(index: int, c: GameController) -> bool:
	for e in c.history:
		var d := e.data
		match index:
			0:
				if e.type == "treasure_pickup" and int(d["id"]) == 1:
					return true
			1:
				if e.type == "exit" and int(d["id"]) == 1 and c.state.secured_count(0) > 0:
					return true
			2:
				if e.type == "fight" and int(d["id"]) == 1:
					return true
			3:
				if e.type == "cast_result" and int(d["id"]) == 1 and d["spell"] == "strength" and d["success"]:
					return true
	return false
