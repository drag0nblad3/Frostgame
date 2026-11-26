class_name ClothSculpt
extends RefCounted
## Folded cloth geometry. Each garment is one low-poly mesh instead of flat plates.


static func cape(root: Node3D, color: Color, length: float, width: float = 0.35) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = []
	const FOLDS := 8
	for j in 4:
		var t := float(j) / 3.0
		for i in FOLDS + 1:
			var u := float(i) / float(FOLDS) * 2.0 - 1.0
			var w := lerpf(0.22, width, t)
			var y := 1.13 - length * t + 0.025 * sin(i * 2.2) * t
			var z := 0.16 + 0.17 * t + 0.04 * cos(i * PI) * (0.45 + t) - 0.09 * u * u
			points.append(Vector3(u * w, y, z))
	for j in 3:
		for i in FOLDS:
			var a := j * (FOLDS + 1) + i
			var b := a + FOLDS + 1
			for k: int in [a, b, a + 1, a + 1, b, b + 1]:
				surface.add_vertex(points[k])
	surface.generate_normals()
	var mesh := MiniatureFactory.mesh(root, surface.commit(), Vector3.ZERO, color)
	var mat: StandardMaterial3D = mesh.material_override
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Embroidered clasp and paired shoulders.
	for x: float in [-0.16, 0.16]:
		MiniatureFactory.sphere(root, Vector3(x, 1.14, -0.13), Vector3.ONE * 0.10, Color(0.76, 0.59, 0.27))


static func robe(root: Node3D, color: Color) -> void:
	var skirt := MiniatureFactory.cylinder(root, Vector3(0, 0.55, 0.0), 0.23, 0.37, 0.83, color)
	skirt.scale.z = 0.75
	for i in 10:
		var angle := TAU * i / 10.0
		var top := Vector3(cos(angle) * 0.21, 0.90, sin(angle) * 0.16)
		var hem := Vector3(cos(angle) * 0.34, 0.17, sin(angle) * 0.25)
		CreatureSculpt.limb(root, top, hem, 0.025, color.lightened(0.16), 0.6)
	var trim := MiniatureFactory.cylinder(root, Vector3(0, 0.17, 0), 0.362, 0.37, 0.055, Color(0.69, 0.54, 0.29))
	trim.scale.z = 0.75


static func hood(root: Node3D, color: Color) -> void:
	MiniatureFactory.sphere(root, Vector3(0, 1.37, 0.055), Vector3(0.45, 0.47, 0.43), color)
	var collar := MiniatureFactory.cylinder(root, Vector3(0, 1.14, 0.01), 0.18, 0.27, 0.17, color.lightened(0.08))
	collar.scale.z = 0.82
