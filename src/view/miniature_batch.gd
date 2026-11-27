class_name MiniatureBatch
extends RefCounted
## Bake static primitive details into a few vertex-colored meshes per moving part.
## Baked materials are shared between models with identical settings so the
## renderer can batch them; fade() gives a model its own copies before changing them.

static var _shared := {}


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
		# Plain surfaces share one mesh per part whatever their roughness or metal:
		# MiniatureSurface reads those per vertex. Glowing, see-through or textured ones keep their own.
		var plain := MiniatureSurface.plain(mat)
		var key := "plain:%s" % mat.cull_mode if plain else "%s:%s:%s:%s:%s:%s" % [mat.roughness, mat.metallic, mat.cull_mode, mat.emission_enabled, mat.emission if mat.emission_enabled else Color.BLACK, mat.transparency]
		if not groups.has(key):
			var copy: Material
			if plain:
				copy = MiniatureSurface.material(mat.cull_mode)
			else:
				var standard := mat.duplicate() as StandardMaterial3D
				standard.albedo_color = Color.WHITE
				standard.vertex_color_use_as_albedo = true
				standard.vertex_color_is_srgb = true
				copy = standard
			groups[key] = {"mat": copy, "plain": plain, "vertices": PackedVector3Array(), "normals": PackedVector3Array(), "colors": PackedColorArray(), "pbr": PackedVector2Array(), "indices": PackedInt32Array()}
		var group: Dictionary = groups[key]
		group["surface"] = Vector2(mat.roughness, mat.metallic)
		for i in mi.mesh.get_surface_count():
			_append(group, mi.mesh.surface_get_arrays(i), mi.transform, mat.albedo_color,painted and not mat.emission_enabled)
		root.remove_child(mi)
		mi.free()
	for group: Dictionary in groups.values():
		if group["vertices"].is_empty():
			continue
		if not group["plain"]:
			group["mat"] = _share(group["mat"])
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = group["vertices"]
		arrays[Mesh.ARRAY_NORMAL] = group["normals"]
		arrays[Mesh.ARRAY_COLOR] = group["colors"]
		arrays[Mesh.ARRAY_INDEX] = group["indices"]
		if group["plain"]:
			arrays[Mesh.ARRAY_TEX_UV] = group["pbr"]
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
	var pbr: PackedVector2Array = group["pbr"]
	var surface: Vector2 = group["surface"]
	# Release dictionary references during append so packed arrays do not
	# detach/copy their entire accumulated contents for each small primitive.
	for key in ["vertices","normals","colors","indices","pbr"]:
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
		if group["plain"]:
			pbr.append(surface)
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
	group["pbr"] = pbr


static func fade(root: Node3D) -> void:
	for child in root.get_children():
		if child is MeshInstance3D:
			if child.material_override is ShaderMaterial and MiniatureSurface.owns(child.material_override):
				child.material_override = MiniatureSurface.faded(child.material_override, 0.35)
				continue
			var mat := child.material_override as StandardMaterial3D
			if mat != null:
				mat = mat.duplicate() as StandardMaterial3D
				child.material_override = mat
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.albedo_color.a = 0.35
		elif child is Node3D:
			fade(child)


## One material per distinct look. The key covers every setting the sculpt code changes.
static func _share(mat: StandardMaterial3D) -> StandardMaterial3D:
	var key := "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [mat.roughness, mat.metallic, mat.metallic_specular, mat.cull_mode,
		mat.emission_enabled, mat.emission, mat.emission_energy_multiplier, mat.transparency, mat.shading_mode,
		mat.specular_mode, mat.albedo_texture, mat.vertex_color_is_srgb]
	if not _shared.has(key):
		_shared[key] = mat
	return _shared[key]
