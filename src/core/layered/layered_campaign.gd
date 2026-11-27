class_name LayeredCampaign
extends RefCounted
## Builds a candidate layered campaign state using the standard roster loader.
## Not selected automatically: full campaign spell/gear support is incomplete.

static func build(data: Dictionary,roster: Dictionary,db: FigureDb,terrain: TerrainDb) -> GameState:
	var source := data.duplicate(true)
	source["board"]="layered_silent_tower"
	source["special"]="silent_tower"
	source["forced_combat"]=false
	source["random_encounters"]=false
	source["creatures"]=[]
	source["warbands"][0]=roster.duplicate(true)
	for side in source["warbands"].size():
		var index := 0
		for entry: Dictionary in source["warbands"][side]["figures"]:
			var x := 2.0+floori(index/10)*1.5
			entry["at"]=[x if side==0 else 36.0-x,8.0+float(index%10)*2.0]
			index+=1
	source["treasures"]=[[18,18],[8.5,18],[27.5,18],[18,6],[18,30]]
	source["central_treasure"]=0
	var s := ScenarioLoader.from_dict(source,db,terrain)
	for f in s.figures:
		f.surface_id="street"
		f.elevation=0.0
	var floors := ["tower_roof","west_annex","east_annex","street","street"]
	for t in s.treasures:
		t.surface_id=floors[t.id]
	return s
