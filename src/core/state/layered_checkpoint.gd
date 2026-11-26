class_name LayeredCheckpoint
extends RefCounted
## Independent experimental save slot, never overwrites a normal campaign battle.

const PATH := "user://frostgame_layered_v1.dat"


static func save(c: GameController,path: String="") -> bool:
	if path.is_empty():
		path=WarbandSlots.path_for(PATH)
	return c!=null and not c.state.board.floor_layout.is_empty() and BattleSnapshot.save(c,{"layered":true},path)


static func read(path: String="") -> Dictionary:
	if path.is_empty():
		path=WarbandSlots.path_for(PATH)
	var data := BattleSnapshot.read(path)
	if not data.get("meta",{}).get("layered",false) or data.get("board",{}).get("floor_layout",{}).is_empty():
		return {}
	return data


static func load_battle(db: FigureDb,path: String="") -> GameController:
	var data := read(path)
	if data.is_empty():
		return null
	return BattleSnapshot.rebuild(data,db)
