shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// World-space stonework: no stretched UVs, extra geometry or external texture assets.
uniform vec4 stone_color : source_color = vec4(0.39, 0.43, 0.48, 1.0);
uniform bool ground = false;
uniform bool frost_detail = true;
uniform bool realm_floor = false;
uniform float snow_amount : hint_range(0.0, 1.0) = 1.0;
uniform bool blind_arches = false;
uniform int facade_style = 0;
uniform vec2 footprint_origin = vec2(0.0);
uniform vec2 footprint_size = vec2(36.0);
uniform bool city_paving = false;
uniform bool battle_boundary = false;
uniform int exterior_style = 0;
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
	// Architectural finishes share geometry: weathered temple ashlar,
	// timber-and-stone infill, and dark tower bands.
	if (!ground && !top) {
		if (facade_style == 1) {
			float panel = step(0.18,fract(local_u*0.5))*step(0.12,fract(world_pos.y*0.42));
			rock = mix(rock,rock*0.90+vec3(0.10,0.07,0.035),panel*0.68);
		} else if (facade_style == 2) {
			float timber = 1.0-smoothstep(0.045,0.08,abs(fract(local_u*0.55)-0.5));
			timber = max(timber,1.0-smoothstep(0.028,0.055,abs(fract(world_pos.y*0.70)-0.5)));
			rock = mix(rock,vec3(0.22,0.15,0.10),timber*0.75);
		} else if (facade_style == 3) {
			float course = 1.0-smoothstep(0.06,0.12,abs(fract(world_pos.y*0.58)-0.5));
			rock = mix(rock,rock*0.56,course*0.8);
		}
	}
	// Frost accumulates in the joints and as narrow chips along exposed tops.
	// Keep the extra procedural samples off the Performance profile.
	if (frost_detail && !realm_floor) {
		float crystalline = noise2(p*3.4+vec2(12.0,5.0));
		float mortar_frost = (1.0-wide)*smoothstep(0.55,0.83,crystalline)*snow_amount;
		rock = mix(rock,vec3(0.52,0.64,0.69),mortar_frost*0.63);
		float flecks = smoothstep(0.77,0.91,chips);
		rock += vec3(0.040,0.052,0.060)*flecks;
		if (ground) {
			float bank = smoothstep(0.57,0.80,drift);
			ice = mix(ice,vec3(0.90,0.94,0.96),bank*0.62);
			rock = mix(rock,rock*0.70,smoothstep(0.52,0.80,drift)*0.10);
		} else if (!top) {
			float cap = smoothstep(building_height-0.34,building_height-0.05,world_pos.y);
			rock = mix(rock,vec3(0.69,0.79,0.84),cap*snow_amount*0.5);
		}
	}
	if (realm_floor && ground) {
		// Broken planes use subdued vein lines rather than ordinary city streets.
		float vein = abs(fract(horizontal.x*0.22+horizontal.y*0.17+noise2(horizontal*0.12)*0.45)-0.5);
		float seam = 1.0-smoothstep(0.008,0.024,vein);
		rock = mix(rock,stone_color.rgb*1.45,seam*0.45);
		snow = 0.0;
	}
	vec3 surface_color = mix(rock, ice, snow * 0.90);
	// Exterior material varies by district, blending in only outside the
	// marked playable rectangle. Interior rules and terrain art are unchanged.
	if (ground && top && exterior_style != 0) {
		vec2 outside = max(-horizontal,horizontal-footprint_size);
		float dist = max(outside.x,outside.y);
		float blend = smoothstep(0.15,3.1,dist);
		vec3 scenic = surface_color;
		float broad = noise2(horizontal*0.32);
		if (exterior_style == 1) {
			// Parallel frozen canal with dark banks; purely scenic.
			float channel = smoothstep(1.8,2.8,dist)*(1.0-smoothstep(6.6,7.3,dist));
			scenic = mix(surface_color,mix(vec3(0.12,0.25,0.34),vec3(0.36,0.57,0.66),broad),channel*0.96);
		} else if (exterior_style == 2) {
			scenic = mix(stone_color.rgb*0.72,ice,broad*snow_amount*0.95);
		} else if (exterior_style == 3) {
			float grout = min(abs(fract(horizontal.x*0.42)-0.5),abs(fract(horizontal.y*0.42)-0.5));
			scenic = stone_color.rgb*(0.78+0.35*broad)*mix(0.60,1.0,smoothstep(0.01,0.045,grout));
		} else if (exterior_style == 4) {
			float crack = abs(fract(horizontal.x*0.17+horizontal.y*0.29+broad*0.7)-0.5);
			scenic = mix(ice,vec3(0.38,0.58,0.70),broad*0.55);
			scenic *= 1.0-0.48*(1.0-smoothstep(0.012,0.035,crack));
		} else if (exterior_style == 5) {
			float seams = smoothstep(0.02,0.06,abs(fract(horizontal.x*1.8)-0.5));
			scenic = vec3(0.22,0.15,0.11)*(0.75+0.42*broad)*mix(0.54,1.0,seams);
		} else if (exterior_style == 6) {
			scenic = mix(stone_color.rgb*0.53,vec3(0.29,0.17,0.14),broad*0.8);
			scenic += vec3(0.12,0.045,0.012)*smoothstep(0.77,0.92,chips);
		} else {
			float vein = 1.0-smoothstep(0.009,0.035,abs(fract(horizontal.x*0.18-horizontal.y*0.23+broad)-0.5));
			scenic = mix(stone_color.rgb*0.35,stone_color.rgb*1.35,vein*0.65);
			if (exterior_style == 8) {
				scenic = mix(scenic,stone_color.rgb*0.12,smoothstep(5.0,23.0,dist)*0.94);
			}
		}
		surface_color = mix(surface_color,scenic,blend);
	}
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
	// Ice is an irregular sheen between drifts, not a new slippery rules area.
	float glazed = 0.0;
	if (ground && top && frost_detail && !realm_floor) {
		glazed = smoothstep(0.48,0.80,drift)*(1.0-smoothstep(0.48,0.90,snow))*snow_amount;
		float hairline = 1.0-smoothstep(0.012,0.036,abs(fract(horizontal.x*0.61+horizontal.y*0.43+drift*0.65)-0.5));
		surface_color = mix(surface_color,vec3(0.44,0.62,0.72),glazed*0.45);
		surface_color += vec3(0.085,0.12,0.14)*hairline*glazed;
	}
	ALBEDO = surface_color;
	ROUGHNESS = mix(mix(0.93,0.70,snow),0.34,glazed*0.82);
	SPECULAR = mix(0.21,0.52,max(snow*0.4,glazed));
}
