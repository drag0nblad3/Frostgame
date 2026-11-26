class_name TerrainDressing
extends RefCounted
## Distinct site details constrained to logical terrain footprints.


static func slab_frame(root: Node3D, board: Board) -> void:
	var center := board.size * 0.5
	MiniatureFactory.box(root, TableSpace.to_world(center, -0.65), Vector3(board.size.x + 0.5, 0.30, board.size.y + 0.5), Color(0.16, 0.19, 0.23))
	for side: float in [-1.0, 1.0]:
		MiniatureFactory.box(root, Vector3(center.x, -0.20, center.y + side * (center.y + 0.05)), Vector3(board.size.x, 0.18, 0.10), Color(0.44, 0.48, 0.49))
		MiniatureFactory.box(root, Vector3(center.x + side * (center.x + 0.05), -0.20, center.y), Vector3(0.10, 0.18, board.size.y), Color(0.44, 0.48, 0.49))


static func rubble(root: Node3D, p: TerrainPiece) -> void:
	var rect := p.rect
	var count := clampi(roundi(rect.get_area() * 2.0), 4, 24)
	for i in count:
		var x := rect.position.x + 0.25 + (rect.size.x - 0.5) * float(posmod(i * 37, 97)) / 97.0
		var z := rect.position.y + 0.25 + (rect.size.y - 0.5) * float(posmod(i * 61, 89)) / 89.0
		var shade := Color(0.38, 0.43, 0.48).lightened(float(i % 5) * 0.035)
		var m := MiniatureFactory.sphere(root, Vector3(x, 0.18, z), Vector3(0.32 + 0.12 * (i % 3), 0.27, 0.34), shade)
		m.rotation.y = i * 0.73


static func column(root: Node3D, p: TerrainPiece) -> void:
	var c := p.rect.get_center()
	var stone := Color(0.59, 0.64, 0.64)
	var r := minf(p.rect.size.x, p.rect.size.y) * 0.5
	MiniatureFactory.box(root, TableSpace.to_world(c, 0.12), Vector3(r * 2, 0.24, r * 2), stone.darkened(0.22))
	MiniatureFactory.cylinder(root, TableSpace.to_world(c, 1.48), r * 0.76, r * 0.84, 2.5, stone)
	for y: float in [0.36, 0.63, 2.36, 2.63]:
		MiniatureFactory.cylinder(root, TableSpace.to_world(c, y), r * 0.91, r * 0.91, 0.10, stone.darkened(0.20))
	var cap := MiniatureFactory.box(root, TableSpace.to_world(c, 2.83), Vector3(r * 2, 0.28, r * 2), stone.lightened(0.17))
	cap.rotation.y = 0.0
	for a in 4:
		var direction := Vector2.RIGHT.rotated(TAU * a / 4.0)
		var at := c + direction * r * 0.80
		var gem := MiniatureFactory.box(root, TableSpace.to_world(at, 2.05), Vector3(0.12, 0.23, 0.12), Color(0.30, 0.68, 0.85))
		var mat: StandardMaterial3D = gem.material_override
		mat.emission_enabled = true
		mat.emission = Color(0.12, 0.35, 0.51)


static func statue(root: Node3D, p: TerrainPiece) -> void:
	var model := Node3D.new()
	root.add_child(model)
	model.position = TableSpace.to_world(p.rect.get_center(), 0.13)
	MiniatureFactory.construct(model, Color(0.58, 0.70, 0.74), 0.96)
	for node in model.get_children():
		if node is MeshInstance3D:
			node.material_override = BoardView._mat(Color(0.62, 0.69, 0.72), 1.0)
	MiniatureFactory.box(root, TableSpace.to_world(p.rect.get_center(), 0.065), Vector3(p.rect.size.x, 0.13, p.rect.size.y), Color(0.34, 0.40, 0.46))


static func masonry(root: Node3D, p: TerrainPiece) -> void:
	var rect := p.rect
	var h := p.kind.height
	if p.kind.id not in ["ruin", "wall", "tower", "hut_wall", "null_lower", "null_middle", "null_upper", "null_annex"]:
		return
	var color := Color(0.29, 0.35, 0.41)
	for level in maxi(1, floori(h / 0.65)):
		var y := 0.34 + level * 0.65
		if y >= h - 0.15:
			break
		for x: float in [rect.position.x, rect.end.x]:
			var n := floori(rect.size.y / 1.2)
			for i in n:
				var z := rect.position.y + 0.45 + i * 1.2 + (0.35 if level % 2 else 0.0)
				if z < rect.end.y - 0.1:
					MiniatureFactory.box(root, Vector3(x, y, z), Vector3(0.025, 0.57, 0.04), color)
		for z: float in [rect.position.y, rect.end.y]:
			var n := floori(rect.size.x / 1.2)
			for i in n:
				var x := rect.position.x + 0.45 + i * 1.2 + (0.35 if level % 2 else 0.0)
				if x < rect.end.x - 0.1:
					MiniatureFactory.box(root, Vector3(x, y, z), Vector3(0.04, 0.57, 0.025), color)


static func chest(root: Node3D) -> void:
	var iron := Color(0.30, 0.24, 0.16)
	for x: float in [-0.22, 0.22]:
		MiniatureFactory.box(root, Vector3(x, 0.25, 0), Vector3(0.065, 0.035, 0.46), iron)
		MiniatureFactory.box(root, Vector3(x, 0, -0.23), Vector3(0.065, 0.48, 0.035), iron)
	MiniatureFactory.box(root, Vector3(0, 0.0, -0.26), Vector3(0.13, 0.17, 0.04), iron)
