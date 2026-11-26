shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// World-space stonework: no stretched UVs, extra geometry or external texture assets.
uniform vec4 stone_color : source_color = vec4(0.39, 0.43, 0.48, 1.0);
uniform bool ground = false;
uniform float snow_amount : hint_range(0.0, 1.0) = 1.0;
uniform bool blind_arches = false;
uniform vec2 footprint_origin = vec2(0.0);
uniform vec2 footprint_size = vec2(36.0);
uniform bool city_paving = false;
uniform bool battle_boundary = false;
uniform bool walkable_roof = false;
uniform float building_height = 4.0;
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
	snow *= snow_amount;
	vec3 ice = mix(vec3(0.52, 0.64, 0.72), vec3(0.84, 0.89, 0.92), noise2(horizontal * 2.2));
	if (ground) {
		rock = mix(rock, rock * 0.8 + vec3(0.11, 0.13, 0.14), 0.4);
		// Broad scoured snow, dirty thaw patches and irregular icy ruts.
		float erosion = smoothstep(0.40,0.72,noise2(horizontal*0.38 + vec2(9.0,3.0)));
		float ruts = noise2(horizontal*vec2(1.5,0.27));
		rock = mix(rock,rock*0.78+vec3(0.055,0.044,0.032),erosion*0.60);
		snow *= 1.0-erosion*0.38;
		ice = mix(ice,vec3(0.45,0.57,0.65),smoothstep(0.62,0.86,ruts)*0.44);
		if (city_paving) {
			// Crossing cobbled streets and weathered courtyards, flush to the ground.
			vec2 local = horizontal / footprint_size;
			float street_d = min(abs(local.x-0.35)*footprint_size.x,abs(local.y-0.62)*footprint_size.y);
			float street = 1.0-smoothstep(1.1,1.8,street_d+0.22*noise2(horizontal*0.7));
			float curb = smoothstep(1.15,1.30,street_d)*(1.0-smoothstep(1.50,1.65,street_d));
			rock = mix(rock,rock*0.72+vec3(0.025,0.033,0.044),street*0.75);
			rock = mix(rock,stone_color.rgb*1.15,curb*0.70);
			snow *= 1.0-street*0.45;
		}
	}
	if (walkable_roof && top && !ground) {
		// Visible pale edge treatment denotes an actual standing surface.
		vec2 local = horizontal-footprint_origin;
		vec2 bounds = min(local,footprint_size-local);
		float rim = 1.0-smoothstep(0.10,0.22,min(bounds.x,bounds.y));
		rock = mix(rock,vec3(0.63,0.71,0.72),rim*0.9);
		snow *= 1.0-rim*0.55;
	}
	if (blind_arches && !top && n.y > -0.2) {
		// Blind gothic recesses, filled with masonry rather than fake entrances.
		float x = abs(mod(local_u + 0.15, 2.15) - 1.075);
		float floor_y = mod(world_pos.y, 2.5);
		float peak = min(2.1,building_height-0.25);
		float arch_width = max(0.0,0.50-max(0.0,floor_y-peak+0.68)*0.74);
		float opening = (1.0-smoothstep(arch_width-0.035,arch_width+0.02,x))*smoothstep(0.42,0.49,floor_y)*(1.0-smoothstep(peak-0.02,peak+0.03,floor_y));
		float surround = (1.0-smoothstep(arch_width+0.08,arch_width+0.13,x))*smoothstep(0.32,0.39,floor_y)*(1.0-smoothstep(peak+0.07,peak+0.12,floor_y));
		float mullion = (1.0-smoothstep(0.024,0.048,x))*opening;
		rock = mix(rock,stone_color.rgb*1.18,surround*0.73);
		rock = mix(rock,rock*0.37,opening*0.90);
		rock = mix(rock,stone_color.rgb*0.82,mullion);
		float fracture = abs(fract(u*0.46+noise2(vec2(u,world_pos.y)*1.4)*0.30+world_pos.y*0.20)-0.5);
		float crack = (1.0-smoothstep(0.010,0.035,fracture))*smoothstep(0.54,0.72,noise2(vec2(u,world_pos.y)*0.54));
		rock *= 1.0-crack*0.62;
	}
	vec3 surface_color = mix(rock, ice, snow * 0.90);
	if (ground && battle_boundary && top) {
		// The playable extent is marked by a thin inlaid stone band, not a raised frame.
		vec2 p_edge = min(horizontal, footprint_size-horizontal);
		float boundary = min(p_edge.x,p_edge.y);
		float band = 1.0-smoothstep(0.035,0.10,abs(boundary));
		surface_color = mix(surface_color,vec3(0.37,0.40,0.43),band*0.78);
		// Subtle distinction outside the combat area without an abrupt material seam.
		float beyond = 1.0-smoothstep(-3.0,-0.15,boundary);
		surface_color *= 1.0-beyond*0.12;
	}
	ALBEDO = surface_color;
	ROUGHNESS = mix(0.93, 0.64, snow);
	SPECULAR = mix(0.21, 0.33, snow);
}
