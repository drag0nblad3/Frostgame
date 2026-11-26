class_name GroundMesh
extends RefCounted
## Ground cutouts and banks use the same authored profiles as movement.


static func build(board: Board) -> ArrayMesh:
	var xs: Array[float] = [0.0,board.size.x]
	var zs: Array[float] = [0.0,board.size.y]
	for p in board.pieces:
		if not p.kind.ground_surface:
			continue
		for x: float in [p.rect.position.x,p.rect.end.x]:
			if x>0.0 and x<board.size.x and not xs.has(x):
				xs.append(x)
		for z: float in [p.rect.position.y,p.rect.end.y]:
			if z>0.0 and z<board.size.y and not zs.has(z):
				zs.append(z)
	xs.sort()
	zs.sort()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(xs.size()-1):
		for j in range(zs.size()-1):
			var a := Vector2(xs[i],zs[j])
			var b := Vector2(xs[i+1],zs[j+1])
			var p := board.ground_piece_at((a+b)*0.5)
			var nw := _point(p,a)
			var ne := _point(p,Vector2(b.x,a.y))
			var se := _point(p,b)
			var sw := _point(p,Vector2(a.x,b.y))
			_quad(st,nw,ne,se,sw)
			if i+1<xs.size()-1:
				var right := board.ground_piece_at(Vector2((xs[i+1]+xs[i+2])*0.5,(a.y+b.y)*0.5))
				_bank(st,ne,se,_point(right,Vector2(b.x,a.y)),_point(right,b))
			if j+1<zs.size()-1:
				var down := board.ground_piece_at(Vector2((a.x+b.x)*0.5,(zs[j+1]+zs[j+2])*0.5))
				_bank(st,sw,se,_point(down,Vector2(a.x,b.y)),_point(down,b))
	st.generate_normals()
	return st.commit()


static func _point(p: TerrainPiece,at: Vector2) -> Vector3:
	return TableSpace.to_world(at,(p.surface_height(at) if p!=null else 0.0)+0.008)


static func _bank(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
	if absf(a.y-c.y)+absf(b.y-d.y)<0.001:
		return
	# Both faces are drawn because either side may be the high bank.
	_quad(st,a,c,d,b)
	_quad(st,b,d,c,a)


static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
	st.set_smooth_group(-1)
	for v: Vector3 in [a,b,c,a,c,d]:
		st.add_vertex(v)


static func bottom(board: Board) -> float:
	var low := 0.0
	for p in board.pieces:
		if p.kind.ground_surface:
			low = minf(low,minf(p.surface_height(p.rect.position),p.surface_height(p.rect.end)))
	return low
