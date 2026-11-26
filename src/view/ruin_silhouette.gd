class_name RuinSilhouette
extends RefCounted
## Snowy cornices and chipped architectural relief. All detail stays in bounds.


static func decorate(root: Node3D, p: TerrainPiece) -> void:
	var rect := p.rect
	var h := p.kind.height
	var stone := Color(0.30, 0.36, 0.41)
	var trim := Color(0.56, 0.62, 0.65)
	# Narrow cornices and buttress faces end at the logical terrain top.
	for y: float in [0.16, h - 0.26]:
		for side: float in [-1.0, 1.0]:
			MiniatureFactory.box(root, Vector3(rect.get_center().x, y, rect.get_center().y + side * (rect.size.y * 0.5 - 0.035)), Vector3(rect.size.x - 0.04, 0.20, 0.09), trim)
			MiniatureFactory.box(root, Vector3(rect.get_center().x + side * (rect.size.x * 0.5 - 0.035), y, rect.get_center().y), Vector3(0.09, 0.20, rect.size.y - 0.04), trim)
	if p.kind.id != "ruin":
		return
	for side: float in [-1.0, 1.0]:
		for i in maxi(1, floori(rect.size.x / 2.1)):
			var x := rect.position.x + 0.25 + i * 2.1
			if x >= rect.end.x - 0.12:
				break
			var z := rect.get_center().y + side * (rect.size.y * 0.5 - 0.025)
			MiniatureFactory.box(root, Vector3(x, h * 0.44, z), Vector3(0.20, h * 0.78, 0.075), stone)
		for i in maxi(1, floori(rect.size.y / 2.1)):
			var z := rect.position.y + 0.25 + i * 2.1
			if z >= rect.end.y - 0.12:
				break
			var x := rect.get_center().x + side * (rect.size.x * 0.5 - 0.025)
			MiniatureFactory.box(root, Vector3(x, h * 0.44, z), Vector3(0.075, h * 0.78, 0.20), stone)
