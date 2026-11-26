class_name SiteArt
extends RefCounted
## Scenario-specific surface geometry; footprints remain those of the rules board.
const ARCANE := preload("res://src/view/materials/arcane_surface.gdshader")
const BRASS := Color(0.56, 0.43, 0.22)
const BOOKS := [Color(0.33,0.15,0.10), Color(0.18,0.29,0.27), Color(0.24,0.25,0.38), Color(0.47,0.35,0.20), Color(0.36,0.13,0.16)]


static func surface(root: Node3D, p: TerrainPiece, water: bool) -> void:
	var r := 1.09 if water else 1.39
	var m := MiniatureFactory.cylinder(root, TableSpace.to_world(p.rect.get_center(), p.kind.height + 0.032), r, r, 0.04, Color.WHITE)
	var mat := ShaderMaterial.new()
	mat.shader = ARCANE
	mat.set_shader_parameter("water", water)
	mat.set_shader_parameter("base_color", Color(0.035, 0.14, 0.23) if water else Color(0.12, 0.24, 0.31))
	mat.set_shader_parameter("glow_color", Color(0.31, 0.78, 0.96) if water else Color(1.0, 0.74, 0.26))
	m.material_override = mat
	if water:
		for i in 12:
			var angle := TAU * i / 12.0
			var at := p.rect.get_center() + Vector2.RIGHT.rotated(angle) * 1.27
			var block := MiniatureFactory.box(root, TableSpace.to_world(at, p.kind.height + 0.06), Vector3(0.25, 0.12, 0.32), Color(0.51, 0.59, 0.63).lightened(float(i % 3) * 0.04))
			block.rotation.y = -angle


static func shelf(root: Node3D, p: TerrainPiece) -> void:
	var rect := p.rect
	var h := p.kind.height
	var c := rect.get_center()
	var wood := Color(0.24, 0.15, 0.10)
	# Solid spine and actual shelf tiers, all within the original footprint.
	MiniatureFactory.box(root, TableSpace.to_world(c, h*0.5), Vector3(rect.size.x*0.50, h, rect.size.y), wood)
	for z: float in [rect.position.y+0.07, rect.end.y-0.07]:
		MiniatureFactory.box(root, Vector3(c.x, h*0.5, z), Vector3(rect.size.x, h, 0.14), wood.lightened(0.14))
	for level in 4:
		var y := 0.10 + level * (h-0.10)/3.0
		MiniatureFactory.box(root, Vector3(c.x, y, c.y), Vector3(rect.size.x, 0.13, rect.size.y), wood.lightened(0.18))
		if level == 3:
			continue
		for side: float in [-1.0,1.0]:
			var n := floori(rect.size.y / 0.38)
			for i in n:
				var shade: Color = BOOKS[posmod(i*3+level*2+int(side),BOOKS.size())]
				var tall := 0.43 + float(posmod(i*17+level,5))*0.035
				var z := rect.position.y + 0.20 + i*0.38
				var x := c.x + side * rect.size.x * 0.34
				var book := MiniatureFactory.box(root, Vector3(x, y+0.065+tall*0.5, z), Vector3(rect.size.x*0.25,tall,0.27),shade)
				book.rotation.x = 0.06 if i%7==0 else 0.0
			# Slim continuous brass shelf-edge strip.
			MiniatureFactory.box(root,Vector3(c.x+side*(rect.size.x*0.5-0.02),y+0.025,c.y),Vector3(0.025,0.04,rect.size.y-0.24),BRASS)


static func crypt(root: Node3D, p: TerrainPiece) -> void:
	var c := p.rect.get_center()
	var h := p.kind.height
	# Roof relief stays below the logical top of the central mausoleum.
	var dark := Color(0.18, 0.25, 0.29)
	var trim := Color(0.55, 0.63, 0.64)
	var w := p.rect.size.x * 0.65
	var d := p.rect.size.y * 0.65
	MiniatureFactory.box(root, TableSpace.to_world(c,h-0.11), Vector3(w,0.13,d), dark)
	MiniatureFactory.box(root, TableSpace.to_world(c,h-0.028), Vector3(w*0.72,0.045,d*0.68), trim)
	for i in 4:
		var at := c + Vector2.RIGHT.rotated(PI*0.25+TAU*i/4.0)*w*0.56
		MiniatureFactory.box(root,TableSpace.to_world(at,h-0.035),Vector3(0.35,0.06,0.35),BRASS)
