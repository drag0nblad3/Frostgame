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
			entry["at"]=[x if side==0 else 36.0-x,8.0+float(index%10)*2.0,"street"]
			index+=1
	source["treasures"]=[[18,18,"tower_roof"],[8.5,18,"west_annex"],[27.5,18,"east_annex"],[18,6,"street"],[18,30,"street"]]
	source["central_treasure"]=0
	return ScenarioLoader.from_dict(source,db,terrain)
