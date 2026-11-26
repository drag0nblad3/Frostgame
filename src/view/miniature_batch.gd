class_name MiniatureBatch
extends RefCounted
## Bake static primitive details into a few vertex-colored meshes per moving part.
## Materials remain unique per model, so invisibility does not affect other figures.


static func bake(root: Node3D,painted: bool=false) -> void:
	painted=painted or root.has_meta("painted_miniature")
	var groups := {}
	for child in root.get_children():
		if not child is MeshInstance3D:
			if child is Node3D:
				bake(child,painted)
			continue
		var mi: MeshInstance3D = child
		var mat := mi.material_override as StandardMaterial3D
		if mat == null or mi.mesh == null:
			continue
		var key := "%s:%s:%s:%s:%s:%s" % [mat.roughness, mat.metallic, mat.cull_mode, mat.emission_enabled, mat.emission if mat.emission_enabled else Color.BLACK, mat.transparency]
		if not groups.has(key):
			var copy := mat.duplicate() as StandardMaterial3D
			copy.albedo_color = Color.WHITE
			copy.vertex_color_use_as_albedo = true
			copy.vertex_color_is_srgb = true
			groups[key] = {"mat": copy, "vertices": PackedVector3Array(), "normals": PackedVector3Array(), "colors": PackedColorArray(), "indices": PackedInt32Array()}
		var group: Dictionary = groups[key]
		for i in mi.mesh.get_surface_count():
			_append(group, mi.mesh.surface_get_arrays(i), mi.transform, mat.albedo_color,painted and not mat.emission_enabled)
		root.remove_child(mi)
		mi.free()
	for group: Dictionary in groups.values():
		if group["vertices"].is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = group["vertices"]
		arrays[Mesh.ARRAY_NORMAL] = group["normals"]
		arrays[Mesh.ARRAY_COLOR] = group["colors"]
		arrays[Mesh.ARRAY_INDEX] = group["indices"]
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var node := MeshInstance3D.new()
		node.mesh = mesh
		node.material_override = group["mat"]
		root.add_child(node)


static func _append(group: Dictionary, arrays: Array, at: Transform3D, color: Color,painted: bool=false) -> void:
	var vertices: PackedVector3Array = group["vertices"]
	var normals: PackedVector3Array = group["normals"]
	var colors: PackedColorArray = group["colors"]
	var indices: PackedInt32Array = group["indices"]
	# Release dictionary references during append so packed arrays do not
	# detach/copy their entire accumulated contents for each small primitive.
	for key in ["vertices","normals","colors","indices"]:
		group.erase(key)
	var source: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var source_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var offset := vertices.size()
	var normal_basis := at.basis.inverse().transposed()
	for i in source.size():
		vertices.append(at * source[i])
		var normal := (normal_basis * source_normals[i]).normalized()
		normals.append(normal)
		# Gentle hand-painted edge lighting and recess tone; no texture lookups.
		var tone := clampf(normal.y,-1.0,1.0)
		colors.append((color.lightened(0.12*tone) if tone>0 else color.darkened(-0.12*tone)) if painted else color)
	if arrays[Mesh.ARRAY_INDEX] == null or arrays[Mesh.ARRAY_INDEX].is_empty():
		for i in source.size():
			indices.append(offset + i)
	else:
		for i: int in arrays[Mesh.ARRAY_INDEX]:
			indices.append(offset + i)
	group["vertices"] = vertices
	group["normals"] = normals
	group["colors"] = colors
	group["indices"] = indices


static func fade(root: Node3D) -> void:
	for child in root.get_children():
		if child is MeshInstance3D:
			var mat := child.material_override as StandardMaterial3D
			if mat != null:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.albedo_color.a = 0.35
		elif child is Node3D:
			fade(child)
