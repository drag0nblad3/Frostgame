extends TestCase


func test_tower_objectives_have_real_vertical_spacing() -> void:
	var s:=ScenarioLoader.load_id("silent_tower",db(),terrain())
	check(not s.scenario_data.has("support_errors"))
	var central:=s.treasures[0]
	check_eq(TreasureRules.token_height(s,central),10.0)
	for i in range(1,5):
		var t:=s.treasures[i]
		var a:=Vector3(t.pos.x,TreasureRules.token_height(s,t),t.pos.y)
		var distance:=a.distance_to(Vector3(central.pos.x,10,central.pos.y))
		check(distance>=6.0)
		if i<=2:
			check(distance<=8.0)
		else:
			check(TreasureRules.edge_distance(s.board,t.pos)>9.0)
		for j in range(1,i):
			var other:=s.treasures[j]
			check(a.distance_to(Vector3(other.pos.x,TreasureRules.token_height(s,other),other.pos.y))>=6.0)
	check(s.board.floor_geometry().solids.size()>30)


func test_tower_keeps_main_entry_and_roof_support() -> void:
	var s:=ScenarioLoader.load_id("silent_tower",db(),terrain())
	var l:=s.board.floor_geometry()
	check(l.errors.is_empty(),str(l.errors))
	for row in [["street",Vector2(18,15.5)],["tower_roof",Vector2(18,18)],["west_walk",Vector2(12,17.5)],["east_walk",Vector2(23,19.5)]]:
		check(l.standable(l.node(str(row[0]),row[1]),Figure.BASE_RADIUS,1.6),str(row))


func test_all_authored_tower_routes_are_connected() -> void:
	var s:=ScenarioLoader.load_id("silent_tower",db(),terrain())
	var l:=s.board.floor_geometry()
	var grid:=LayeredGrid.new(l)
	var start:=l.node("street",Vector2(18,8))
	var reached: Dictionary={start:true}
	var queue: Array[Vector3i]=[start]
	var index:=0
	while index<queue.size():
		var current:=queue[index]
		index+=1
		for edge in grid.neighbors(current):
			var n: Vector3i=edge["to"]
			if not reached.has(n):
				reached[n]=true
				queue.append(n)
	for row: Dictionary in s.board.floor_layout["links"]:
		var a: Array=row["from"]
		var b: Array=row["to"]
		var from:=l.node(str(a[0]),Vector2(a[1],a[2]))
		var to:=l.node(str(b[0]),Vector2(b[1],b[2]))
		check(reached.has(from) and reached.has(to),str(row))
		check(grid.neighbors(from).any(func(e: Dictionary)->bool: return e["to"]==to),str(row))
		check(grid.neighbors(to).any(func(e: Dictionary)->bool: return e["to"]==from),str(row))
	for row: Dictionary in s.board.floor_layout["climbs"]:
		var a: Array=row["from"]
		var b: Array=row["to"]
		check(reached.has(l.node(str(a[0]),Vector2(a[1],a[2]))),str(row))
		check(reached.has(l.node(str(b[0]),Vector2(b[1],b[2]))),str(row))
		var last:=l.node(str(a[0]),Vector2(a[1],a[2]))
		for i in range(1,ceili(l.height(l.node(str(b[0]),Vector2(b[1],b[2])))-l.height(last))+1):
			var next:=l.node("climb:"+str(row["id"])+":"+str(i),Vector2(a[1],a[2]))
			check(reached.has(next),str(row)+" climb step "+str(i))
			check(grid.neighbors(last).any(func(e: Dictionary)->bool:return e["to"]==next),str(row))
			last=next
	for t in s.treasures:
		var nearby:=false
		for n: Vector3i in reached:
			if l.surface_id(n)==t.surface_id and l.point(n).distance_to(t.pos)<=Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS+0.01:
				nearby=true
				break
		check(nearby,"Treasure access "+str(t.id))
	print("Tower route audit: ",reached.size()," reachable floor nodes.")
