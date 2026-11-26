class_name LayeredBattle
extends RefCounted


static func create(db: FigureDb,terrain: TerrainDb,seed_value: int = 17,board_id: String = "stacked_gatehouse") -> GameController:
	var s := GameState.new()
	s.board=BoardLoader.load_id(board_id,terrain)
	var tower := board_id=="layered_silent_tower"
	if tower:
		s.scenario_special="silent_tower"
	s.side_names.assign(["Expedition","Rival"])
	s.creature_db=db
	s.spell_catalog=JsonFile.read("res://data/spells.json")
	s.side_schools={0:"illusionist",1:"illusionist"}
	s.spellbooks={0:{"teleport":10,"leap":12,"bridge":14},1:{"teleport":10,"leap":12,"bridge":14}}
	var layout := FloorLayout.from_dict(s.board.floor_layout)
	var deployment: Array = [[0,"wizard","street",Vector2(3,3)],[0,"thug","stairs",Vector2(2,8)],[0,"archer","street",Vector2(3,12)],[1,"wizard","street",Vector2(15,3)],[1,"thug","street",Vector2(10,8)],[1,"archer","street",Vector2(15,12)]]
	if tower:
		deployment=[[0,"wizard","street",Vector2(3,15)],[0,"thug","street",Vector2(3,18)],[0,"archer","street",Vector2(3,21)],[1,"wizard","street",Vector2(33,15)],[1,"thug","street",Vector2(33,18)],[1,"archer","street",Vector2(33,21)]]
	for entry: Array in deployment:
		var f := Figure.new(s.figures.size()+1,db.get_def(entry[1]),entry[0],entry[3],db.unarmed())
		f.surface_id=entry[2]
		f.elevation=layout.height(layout.node(f.surface_id,f.pos))
		s.figures.append(f)
	var loot: Array = [["street",Vector2(8,8)],["upper",Vector2(8,8)]]
	if tower:
		loot=[["tower_roof",Vector2(18,18)],["west_annex",Vector2(8.5,18)],["east_annex",Vector2(27.5,18)],["street",Vector2(18,6)],["street",Vector2(18,30)]]
	for entry: Array in loot:
		var t := TreasureToken.new(s.treasures.size(),entry[1])
		t.surface_id=entry[0]
		s.treasures.append(t)
	var c := GameController.new(s,Dice.new(seed_value))
	c.start_game()
	return c
