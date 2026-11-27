class_name ExteriorProfile
extends RefCounted
## Art-only district plans. No scenario or board state is ever mutated.
const KINDS := ["city","hall","tower","gate","market","stall","crate","wall","tree","debris","quay","bridge","warehouse","graveyard","crypt","obelisk","mausoleum","colonnade","basin","shrine","statue","plinth","gallery","ice","drift","ice_ridge","ruin","shelf","pillar","archive","cabin","fence","windmill","fortress","tall_tower","tent","brazier","palisade","watchtower","shard","memory","floating","burned_shrine","pyramid","tether","broken_bridge","ring"]
static var _data: Dictionary={}


static func all() -> Dictionary:
	if _data.is_empty():
		_data=JsonFile.read("res://data/exterior_profiles.json")
	return _data


static func get_profile(id: String) -> Dictionary:
	var data:=all()
	if id=="frozen_ruins":
		id="treasure_skirmish"
	return data.get(id,data.get("default",{}))


## A conservative 4-inch horizontal envelope around every motif is outside
## the playable rectangle, even when the near row is jittered.
static func plan(size: Vector2,scenario: String,quality: int,rings: int,side: int,cinematic: bool=false) -> Array[Dictionary]:
	var profile:=get_profile(scenario)
	var length:=size.x if side%2==0 else size.y
	var spacing:=float(profile.get("spacing",6.5))+(2.0 if quality==0 else 0.0)
	var near: Array=profile.get("sides",{}).get(str(side),profile.get("near",["tree"]))
	var far: Array=profile.get("far_sides",{}).get(str(side),profile.get("far",["city"]))
	var seed_offset:=posmod(hash(scenario),991)
	var out: Array[Dictionary]=[]
	for row in range(rings+1):
		var motifs:=near if row==0 else far
		var count:=maxi(2,floori(length/spacing)+(1 if row>1 and quality>0 else 0))
		var distance:=6.0 if row==0 else (12.0 if cinematic else 14.0)+(row-1)*12.0
		for i in count:
			var seed:=seed_offset+side*137+row*211+i*53
			var u:=(i+0.5)*length/count+sin(seed*1.7)*0.65
			var gap:=distance+cos(seed*2.1)*0.7
			var kind:=str(motifs[posmod(i+side+row,motifs.size())])
			if row==1 and i==count/2:
				kind=str(profile.get("landmark_sides",{}).get(str(side),profile.get("landmark",kind)))
			var at:=Vector2(u,-gap) if side==0 else (Vector2(size.x+gap,u) if side==1 else (Vector2(u,size.y+gap) if side==2 else Vector2(-gap,u)))
			out.append({"kind":kind,"at":at,"seed":seed,"row":row})
	return out
