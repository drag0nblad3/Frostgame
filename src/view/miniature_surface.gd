class_name MiniatureSurface
extends RefCounted
## One shared shader for plain painted miniature surfaces. Colour comes from
## vertex colours and roughness/metallic from UV (x, y), so parts that
## differ only in finish bake into a single mesh and draw call.

static var _materials := {}


## Surfaces that only differ in colour and finish can share this shader.
static func plain(mat: StandardMaterial3D) -> bool:
	return not mat.emission_enabled and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED \
		and mat.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL and mat.albedo_texture == null \
		and mat.specular_mode == BaseMaterial3D.SPECULAR_SCHLICK_GGX and is_equal_approx(mat.metallic_specular, 0.5)


static func material(cull: int, alpha := 1.0) -> ShaderMaterial:
	var key := Vector2(cull, alpha)
	if not _materials.has(key):
		var m := ShaderMaterial.new()
		m.shader = _shader(cull, alpha < 1.0)
		m.set_meta("miniature_surface", cull)
		if alpha < 1.0:
			m.set_shader_parameter("alpha", alpha)
		_materials[key] = m
	return _materials[key]


static func owns(mat: Material) -> bool:
	return mat.has_meta("miniature_surface")


static func faded(mat: ShaderMaterial, alpha: float) -> ShaderMaterial:
	return material(int(mat.get_meta("miniature_surface")), alpha)


static var _shaders := {}


static func _shader(cull: int, see_through: bool) -> Shader:
	var key := Vector2i(cull, int(see_through))
	if _shaders.has(key):
		return _shaders[key]
	var cull_mode: String = ["cull_back", "cull_front", "cull_disabled"][cull]
	var modes := cull_mode + ", diffuse_burley, specular_schlick_ggx"
	if see_through:
		modes += ", blend_mix, depth_draw_opaque"
	var code := """shader_type spatial;
render_mode %s;
uniform float alpha = 1.0;
void vertex() {
	// Same sRGB handling as StandardMaterial3D.vertex_color_is_srgb.
	if (!OUTPUT_IS_SRGB) {
		vec3 c = COLOR.rgb;
		COLOR.rgb = mix(pow((c + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)), c * (1.0 / 12.92), lessThan(c, vec3(0.04045)));
	}
}
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = UV.x;
	METALLIC = UV.y;
%s}
""" % [modes, "\tALPHA = alpha;\n" if see_through else ""]
	var shader := Shader.new()
	shader.code = code
	_shaders[key] = shader
	return shader
