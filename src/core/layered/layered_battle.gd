class_name LayeredBattle
extends RefCounted


static func create(db: FigureDb,terrain: TerrainDb,seed_value: int = 17,board_id: String = "stacked_gatehouse") -> GameController:
	var tower:=board_id=="layered_silent_tower"
	var spells:={"teleport":10,"leap":12,"bridge":14,"heal":12,"elemental_bolt":12,"elemental_shield":10}
	var source:={"board":board_id,"special":"silent_tower" if tower else "","central_treasure":0,"warbands":[{"name":"Expedition","school":"illusionist","spells":spells,"figures":[]},{"name":"Rival","school":"illusionist","spells":spells,"figures":[]}],"treasures":[]}
	var deployment: Array = [[0,"wizard","street",Vector2(3,3)],[0,"thug","stairs",Vector2(2,8)],[0,"archer","street",Vector2(3,12)],[1,"wizard","street",Vector2(15,3)],[1,"thug","street",Vector2(10,8)],[1,"archer","street",Vector2(15,12)]]
	if tower:
		deployment=[[0,"wizard","street",Vector2(3,15)],[0,"thug","street",Vector2(3,18)],[0,"archer","street",Vector2(3,21)],[1,"wizard","street",Vector2(33,15)],[1,"thug","street",Vector2(33,18)],[1,"archer","street",Vector2(33,21)]]
	for entry: Array in deployment:
		source["warbands"][entry[0]]["figures"].append({"type":entry[1],"at":[entry[3].x,entry[3].y,entry[2]]})
	var loot: Array = [["street",Vector2(8,8)],["upper",Vector2(8,8)]]
	if tower:
		loot=[["tower_roof",Vector2(18,18)],["west_annex",Vector2(8.5,18)],["east_annex",Vector2(27.5,18)],["street",Vector2(18,6)],["street",Vector2(18,30)]]
	for entry: Array in loot:
		source["treasures"].append([entry[1].x,entry[1].y,entry[0]])
	var s:=ScenarioLoader.from_dict(source,db,terrain)
	var c:=GameController.new(s,Dice.new(seed_value))
	c.start_game()
	return c
