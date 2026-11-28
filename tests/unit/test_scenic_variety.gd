extends TestCase


func test_plinth_seed_is_stable_and_varied() -> void:
	var a:=Node3D.new()
	var b:=Node3D.new()
	MiniaturePlinth.create(a,12)
	MiniaturePlinth.create(b,12)
	var ma:=a.get_node("ScenicTop").get_child(0) as MeshInstance3D
	var mb:=b.get_node("ScenicTop").get_child(0) as MeshInstance3D
	check_eq(ma.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],mb.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	var distinct:=false
	for id in range(13,19):
		var c:=Node3D.new()
		MiniaturePlinth.create(c,id)
		var mc:=c.get_node("ScenicTop").get_child(0) as MeshInstance3D
		var bounds:=mc.mesh.get_aabb()
		check(bounds.position.x>=-0.46 and bounds.end.x<=0.46)
		check(bounds.position.z>=-0.46 and bounds.end.z<=0.46)
		if mc.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]!=ma.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			distinct=true
		c.free()
	check(distinct)
	a.free()
	b.free()
