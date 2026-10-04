shader_type sky;

// -----------------------------------------------------------------------------
// SWORD ART ONLINE: AINCRAD ANIME SKY SHADER (GODOT 4 FORWARD+)
// Seamless anime celestial gradient, cel solar disc, and procedural wispy clouds
// -----------------------------------------------------------------------------

group_uniforms SkyGradients;
uniform vec4 sky_top_color : source_color = vec4(0.14, 0.44, 0.88, 1.0);       // Deep anime azure zenith
uniform vec4 sky_mid_color : source_color = vec4(0.36, 0.68, 0.96, 1.0);       // Vibrant anime sky blue
uniform vec4 sky_horizon_color : source_color = vec4(0.78, 0.91, 0.99, 1.0);   // Pastel cyan-white horizon
uniform vec4 ground_horizon_color : source_color = vec4(0.68, 0.76, 0.84, 1.0);// Ground horizon haze
uniform vec4 ground_bottom_color : source_color = vec4(0.28, 0.32, 0.38, 1.0); // Earth base tone

group_uniforms AnimeSun;
uniform vec4 sun_tint : source_color = vec4(1.0, 0.96, 0.84, 1.0);
uniform float sun_disk_size : hint_range(0.005, 0.1, 0.005) = 0.035;
uniform float sun_disk_softness : hint_range(0.001, 0.05, 0.001) = 0.008;
uniform float sun_halo_size : hint_range(0.05, 0.6, 0.01) = 0.32;
uniform float sun_halo_intensity : hint_range(0.0, 2.0, 0.05) = 0.45;

group_uniforms AnimeWisps;
uniform vec4 wisp_color : source_color = vec4(0.96, 0.98, 1.0, 0.65);
uniform float wisp_coverage : hint_range(0.0, 1.0, 0.05) = 0.35;
uniform float wisp_speed : hint_range(0.0, 0.05, 0.001) = 0.003;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100.0);
	for (int i = 0; i < 4; ++i) {
		v += a * noise(p);
		p = p * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

void sky() {
	float elevation = EYEDIR.y;
	vec3 sky_col;
	
	// Smooth seamless transition across astronomical horizon (-0.15 to +0.35)
	if (elevation >= -0.08) {
		float t_mid = smoothstep(-0.08, 0.28, elevation);
		float t_zenith = smoothstep(0.28, 0.95, elevation);
		vec3 lower_band = mix(sky_horizon_color.rgb, sky_mid_color.rgb, t_mid);
		sky_col = mix(lower_band, sky_top_color.rgb, t_zenith);
		
		// Wispy cirrus streaks high in the sky
		if (elevation > 0.02 && wisp_coverage > 0.01) {
			vec2 uv_cloud = EYEDIR.xz / (elevation + 0.15);
			uv_cloud += TIME * wisp_speed;
			float n = fbm(uv_cloud * 1.8);
			float streak = smoothstep(1.0 - wisp_coverage, 1.0, n);
			sky_col = mix(sky_col, wisp_color.rgb, streak * wisp_color.a * smoothstep(0.02, 0.22, elevation));
		}
	} else {
		float t_gnd = smoothstep(-0.08, -0.45, elevation);
		sky_col = mix(sky_horizon_color.rgb, ground_bottom_color.rgb, t_gnd);
	}
	
	// Anime Sun disc & cel corona
	if (LIGHT0_ENABLED) {
		float sun_dot = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
		float sun_dist = 1.0 - sun_dot;
		
		float sun_disc = 1.0 - smoothstep(sun_disk_size - sun_disk_softness, sun_disk_size + sun_disk_softness, sun_dist);
		float sun_halo = (1.0 - smoothstep(0.0, sun_halo_size, sun_dist)) * sun_halo_intensity;
		
		vec3 sun_effect = sun_tint.rgb * LIGHT0_COLOR * (sun_disc * 2.5 + sun_halo);
		sky_col += sun_effect;
	}
	
	COLOR = sky_col;
}
