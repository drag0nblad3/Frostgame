extends TestCase


func test_wraith_ignores_one_volume_not_two() -> void:
	var b:=make_board([],Vector2(20,16))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0}],"solids":[[9,0,4,1,3,6]]}
	var f:=fig("archer",0,Vector2(5,7))
	var t:=fig("thug",1,Vector2(13,7))
	f.surface_id="street"
	t.surface_id="street"
	check(Shooting.floor_wraith_line(b,f,t)!=null)
	b.floor_layout["solids"].append([11,0,4,1,3,6])
	check(Shooting.floor_wraith_line(b,f,t)==null)
