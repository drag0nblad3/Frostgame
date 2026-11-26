class_name LayeredBattle
extends RefCounted


static func create(db: FigureDb,terrain: TerrainDb,seed_value: int = 17) -> GameController:
	var s := GameState.new()
	s.board=BoardLoader.load_id("stacked_gatehouse",terrain)
	s.side_names.assign(["Expedition","Rival"])
	s.creature_db=db
	s.spell_catalog=JsonFile.read("res://data/spells.json")
	s.side_schools={0:"illusionist",1:"illusionist"}
	s.spellbooks={0:{"teleport":10,"leap":12},1:{"teleport":10,"leap":12}}
	var layout := FloorLayout.from_dict(s.board.floor_layout)
	for entry: Array in [[0,"wizard","street",Vector2(3,3)],[0,"thug","stairs",Vector2(2,8)],[0,"archer","street",Vector2(3,12)],[1,"wizard","street",Vector2(15,3)],[1,"thug","street",Vector2(10,8)],[1,"archer","street",Vector2(15,12)]]:
		var f := Figure.new(s.figures.size()+1,db.get_def(entry[1]),entry[0],entry[3],db.unarmed())
		f.surface_id=entry[2]
		f.elevation=layout.height(layout.node(f.surface_id,f.pos))
		s.figures.append(f)
	for id: String in ["street","upper"]:
		var t := TreasureToken.new(s.treasures.size(),Vector2(8,8))
		t.surface_id=id
		s.treasures.append(t)
	var c := GameController.new(s,Dice.new(seed_value))
	c.start_game()
	return c
