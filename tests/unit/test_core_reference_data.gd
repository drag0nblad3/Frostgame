extends TestCase
## Independent reference tuples, core printed pp. 30–31:
## Move, Fight, Shoot, Armour, Will, Health, retainer, specialist.
const SOLDIERS: Dictionary={
	"thug":[6,2,0,10,-1,10,0,false],
	"thief":[7,1,0,10,0,10,0,false],
	"war_hound":[8,1,0,10,-2,8,10,false],
	"infantryman":[6,3,0,11,0,10,50,false],
	"man_at_arms":[6,3,0,12,1,12,75,false],
	"apothecary":[6,1,0,10,3,12,75,false],
	"archer":[6,1,2,11,0,10,75,true],
	"crossbowman":[6,1,2,11,0,10,75,true],
	"treasure_hunter":[7,3,0,11,2,12,100,true],
	"tracker":[7,1,2,11,1,12,100,true],
	"knight":[5,4,0,13,1,12,125,true],
	"templar":[5,4,0,12,1,12,125,true],
	"ranger":[7,2,2,11,2,12,125,true],
	"barbarian":[6,4,0,10,3,14,125,true],
	"marksman":[5,2,2,12,1,12,125,true]
}

func test_soldier_reference_stats() -> void:
	var data: Dictionary=JsonFile.read("res://data/figures.json")
	for id in SOLDIERS:
		var row: Dictionary=data[id]
		var values: Array=[]
		for key in ["move","fight","shoot","armour","will","health","cost"]:
			values.append(int(row[key]))
		values.append(bool(row["specialist"]))
		check_eq(values,SOLDIERS[id],id)
