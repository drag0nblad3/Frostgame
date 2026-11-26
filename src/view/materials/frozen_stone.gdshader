shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// World-space stonework: no stretched UVs, extra geometry or external texture assets.
uniform vec4 stone_color : source_color = vec4(0.39, 0.43, 0.48, 1.0);
uniform bool ground = false;
uniform bool blind_arches = false;
uniform vec2 footprint_origin = vec2(0.0);
varying vec3 world_pos;
varying vec3 world_normal;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.,0.)), f.x),
		mix(hash21(i + vec2(0.,1.)), hash21(i + vec2(1.,1.)), f.x), f.y);
}
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
}
void fragment() {
	vec3 n = normalize(world_normal);
	vec2 horizontal = world_pos.xz;
	bool top = n.y > 0.5;
	float u = abs(n.x) > abs(n.z) ? world_pos.z : world_pos.x;
	float local_u = abs(n.x) > abs(n.z) ? world_pos.z - footprint_origin.y : world_pos.x - footprint_origin.x;
	vec2 p = top ? horizontal : vec2(u, world_pos.y);
	vec2 scale = top ? vec2(0.84, 1.12) : vec2(0.86, 1.58);
	vec2 brick = p * scale;
	brick.x += mod(floor(brick.y), 2.0) * 0.5;
	vec2 tile = floor(brick);
	vec2 grain = fract(brick);
	float edge = min(min(grain.x, 1.0-grain.x), min(grain.y, 1.0-grain.y));
	float wide = smoothstep(0.018, 0.053, edge);
	float chips = noise2(p * 7.4);
	float tone = 0.84 + 0.25 * hash21(tile) + 0.11 * chips;
	vec3 rock = stone_color.rgb * tone;
	rock *= mix(0.51, 1.0, wide);
	rock += vec3(0.045, 0.058, 0.065) * (1.0 - smoothstep(0.045, 0.12, min(grain.x, grain.y))) * wide;
	float drift = noise2(horizontal * 0.24) * 0.72 + noise2(horizontal * 1.3) * 0.28;
	float snow = top ? smoothstep(ground ? 0.34 : 0.20, ground ? 0.68 : 0.58, drift) : 0.0;
	vec3 ice = mix(vec3(0.52, 0.64, 0.72), vec3(0.84, 0.89, 0.92), noise2(horizontal * 2.2));
	if (ground) {
		rock = mix(rock, rock * 0.8 + vec3(0.11, 0.13, 0.14), 0.4);
	}
	if (blind_arches && !top && n.y > -0.2) {
		// Blind gothic recesses, filled with masonry rather than fake entrances.
		float x = abs(mod(local_u + 0.15, 2.15) - 1.075);
		float y = world_pos.y - 1.55;
		float dist = length(vec2(x * 1.4, max(0.0, y)));
		float opening = (1.0 - smoothstep(0.55, 0.60, dist)) * smoothstep(0.42, 0.49, world_pos.y);
		float arch_rim = smoothstep(0.55, 0.61, dist) * (1.0 - smoothstep(0.74, 0.80, dist)) * smoothstep(0.40, 0.50, world_pos.y);
		rock = mix(rock, rock * 0.46, opening * 0.87);
		rock = mix(rock, stone_color.rgb * 1.20, arch_rim * 0.8);
	}
	ALBEDO = mix(rock, ice, snow * 0.90);
	ROUGHNESS = mix(0.93, 0.64, snow);
	SPECULAR = mix(0.21, 0.33, snow);
}
