shader_type spatial;
render_mode diffuse_burley;
uniform vec4 base_color : source_color = vec4(0.04,0.22,0.30,1.0);
uniform vec4 glow_color : source_color = vec4(0.25,0.83,0.95,1.0);
uniform bool water = false;
varying vec3 local_pos;
void vertex() {
	local_pos = VERTEX;
}
void fragment() {
	vec2 p = local_pos.xz;
	float r = length(p);
	float theta = atan(p.y,p.x);
	float ripples = sin(r * 20.0 - TIME * 1.65 + sin(theta * 3.0) * 0.5);
	float wave = 0.5 + 0.5 * ripples;
	float ring = (1.0 - smoothstep(0.018,0.045,abs(r-1.05))) + (1.0 - smoothstep(0.012,0.033,abs(r-0.69)));
	float mark = (1.0 - smoothstep(0.035,0.08,abs(sin(theta*6.0)))) * smoothstep(0.73,0.77,r) * (1.0-smoothstep(0.93,0.98,r));
	float sigil = clamp(ring + mark,0.0,1.0);
	float pulse = 0.75 + 0.18*sin(TIME*1.4);
	ALBEDO = mix(base_color.rgb, glow_color.rgb, water ? wave * 0.40 : sigil * 0.85);
	EMISSION = glow_color.rgb * (water ? wave*0.12 : sigil*pulse*0.6);
	ROUGHNESS = water ? 0.24 : 0.52;
}
