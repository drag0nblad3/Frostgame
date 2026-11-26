class_name TabletopDetails
extends RefCounted
## Decorative snow, cobbles and stone detailing confined to existing terrain.


static func ground(board: Board) -> MultiMeshInstance3D:
	var tile := BoxMesh.new()
	tile.size = Vector3(0.93, 0.012, 0.93)
	var mat := BoardView._mat(Color.WHITE, 1.0)
	mat.vertex_color_use_as_albedo = true
	tile.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = tile
	var cols := floori(board.size.x)
	var rows := floori(board.size.y)
	mm.instance_count = cols * rows
	for x in cols:
		for y in rows:
			var i := y * cols + x
			var shade := float(posmod(x * 71 + y * 43 + x * y * 13, 19)) / 180.0
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(x + 0.5, 0.007, y + 0.5)))
			mm.set_instance_color(i, Color(0.66 + shade, 0.72 + shade, 0.80 + shade))
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


static func decorate(root: Node3D, piece: TerrainPiece) -> void:
	if piece.kind.id == "arcane_disc":
		var ring := TorusMesh.new()
		ring.inner_radius = 1.12
		ring.outer_radius = 1.38
		MiniatureFactory.mesh(root, ring, TableSpace.to_world(piece.rect.get_center(), 0.07), Color(0.89, 0.74, 0.29)).scale.y = 0.16
		for i in 8:
			var at := piece.rect.get_center() + Vector2.RIGHT.rotated(TAU * i / 8.0) * 0.85
			MiniatureFactory.box(root, TableSpace.to_world(at, 0.07), Vector3(0.14, 0.04, 0.14), Color(0.89, 0.74, 0.29))
		return
	if piece.kind.id not in ["ruin", "wall", "platform", "tower", "library_shelf", "dreams_well", "hut_wall", "null_annex", "null_walk", "null_lower", "null_middle", "null_upper", "temple_column"]:
		return
	var decor := Node3D.new()
	root.add_child(decor)
	var rect := piece.rect
	var center := rect.get_center()
	var h := piece.kind.height
	if piece.kind.id == "dreams_well":
		MiniatureFactory.cylinder(decor, TableSpace.to_world(center, h + 0.025), 1.12, 1.12, 0.05, Color(0.06, 0.16, 0.26))
		var rim := TorusMesh.new()
		rim.inner_radius = 1.08
		rim.outer_radius = 1.48
		var node := MiniatureFactory.mesh(decor, rim, TableSpace.to_world(center, h + 0.08), Color(0.64, 0.69, 0.72))
		node.scale.y = 0.55
		return
	if piece.kind.id == "library_shelf":
		for i in maxi(1, floori(rect.size.y / 0.75)):
			var z := rect.position.y + 0.38 + i * 0.75
			var shade := Color(0.52, 0.28, 0.19) if i % 2 == 0 else Color(0.20, 0.30, 0.39)
			for level in 3:
				MiniatureFactory.box(decor, Vector3(rect.position.x + 0.025, 0.42 + level * 0.72, z), Vector3(0.05, 0.44, 0.55), shade)
				MiniatureFactory.box(decor, Vector3(rect.end.x - 0.025, 0.42 + level * 0.72, z), Vector3(0.05, 0.44, 0.55), shade.darkened(0.13))
		return
	# Stone surfaces use StoneFinish's procedural snow and masonry shader.
