shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;

// -----------------------------------------------------------------------------
// SWORD ART ONLINE STYLIZED WATER SHADER (GODOT 4 FORWARD+)
// -----------------------------------------------------------------------------

group_uniforms ColorGrading;
uniform vec4 shallow_color : source_color = vec4(0.22, 0.78, 0.82, 0.85); // Bright turquoise
uniform vec4 deep_color : source_color = vec4(0.08, 0.28, 0.58, 0.95);    // Deep sapphire blue
uniform float depth_distance : hint_range(0.1, 20.0, 0.1) = 3.5;
uniform float beer_law_attenuation : hint_range(0.1, 5.0, 0.1) = 1.2;

group_uniforms FoamAndShoreline;
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 1.0);
uniform float shore_foam_threshold : hint_range(0.01, 1.5, 0.01) = 0.45;
uniform float foam_softness : hint_range(0.01, 0.5, 0.01) = 0.08;
uniform sampler2D foam_noise : hint_default_white, filter_linear_mipmap;
uniform vec2 foam_scroll_speed = vec2(0.03, 0.02);

group_uniforms Waves;
uniform sampler2D wave_normal_map_1 : hint_normal, filter_linear_mipmap;
uniform sampler2D wave_normal_map_2 : hint_normal, filter_linear_mipmap;
uniform vec2 wave_speed_1 = vec2(0.04, 0.02);
uniform vec2 wave_speed_2 = vec2(-0.03, 0.05);
uniform float wave_scale_1 = 4.0;
uniform float wave_scale_2 = 8.0;
uniform float normal_strength : hint_range(0.0, 2.0, 0.05) = 0.6;
uniform float vertex_wave_height : hint_range(0.0, 1.0, 0.01) = 0.08;
uniform float vertex_wave_frequency : hint_range(0.1, 10.0, 0.1) = 2.0;

group_uniforms StylizedGlints;
uniform float roughness : hint_range(0.0, 1.0, 0.05) = 0.05;
uniform float specular_strength : hint_range(0.0, 2.0, 0.05) = 1.2;
uniform float refraction_strength : hint_range(0.0, 0.1, 0.005) = 0.02;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void vertex() {
	// Stylized sinusoidal undulating waves
	float wave = sin((VERTEX.x * vertex_wave_frequency) + (TIME * 1.5)) *
	             cos((VERTEX.z * vertex_wave_frequency * 0.8) + (TIME * 1.2));
	VERTEX.y += wave * vertex_wave_height;
}

void fragment() {
	// Panning dual normal waves
	vec2 uv1 = UV * wave_scale_1 + wave_speed_1 * TIME;
	vec2 uv2 = UV * wave_scale_2 + wave_speed_2 * TIME;
	vec3 n1 = texture(wave_normal_map_1, uv1).rgb * 2.0 - 1.0;
	vec3 n2 = texture(wave_normal_map_2, uv2).rgb * 2.0 - 1.0;
	vec3 blended_normal = normalize(n1 + n2);
	NORMAL_MAP = normalize(vec3(blended_normal.xy, 1.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = normal_strength;

	// Reconstruct linear camera depth from depth_texture
	float raw_depth = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, raw_depth);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	float linear_depth = -view_pos.z;
	// Safe positive water depth (clamp against negative depth precision issues)
	float water_depth = max(linear_depth - (-VERTEX.z), 0.0);
	
	// Beer's law depth color gradient
	float depth_blend = clamp(water_depth / depth_distance, 0.0, 1.0);
	depth_blend = pow(depth_blend, beer_law_attenuation);
	vec4 water_color = mix(shallow_color, deep_color, depth_blend);
	
	// Stylized underwater refraction distortion
	vec2 refr_offset = blended_normal.xy * refraction_strength * clamp(water_depth, 0.0, 1.0);
	vec3 ref_scene = texture(screen_texture, SCREEN_UV + refr_offset).rgb;
	
	// Dynamic shore foam using noise
	vec2 foam_uv = UV * 6.0 + foam_scroll_speed * TIME;
	float noise_val = texture(foam_noise, foam_uv).r;
	float foam_edge = 1.0 - smoothstep(0.0, shore_foam_threshold, water_depth);
	float foam_factor = foam_edge * smoothstep(0.3, 0.7, noise_val + foam_edge * 0.5);
	foam_factor = clamp(foam_factor, 0.0, 1.0);
	
	// Blend water color with refracted bottom and surface foam
	vec3 water_rgb = mix(ref_scene * water_color.rgb, water_color.rgb, water_color.a);
	vec3 final_rgb = mix(water_rgb, foam_color.rgb, foam_factor);
	
	ALBEDO = final_rgb;
	ROUGHNESS = roughness;
	SPECULAR = 0.8;
	ALPHA = mix(water_color.a, 1.0, foam_factor);
}

void light() {
	// Stylized sharp glint specular for anime water reflection
	float NdotL = max(dot(NORMAL, LIGHT), 0.0);
	vec3 H = normalize(VIEW + LIGHT);
	float NdotH = max(dot(NORMAL, H), 0.0);
	float spec = pow(NdotH, 256.0 * (1.0 - roughness));
	float spec_cut = smoothstep(0.4, 0.5, spec);
	
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * NdotL * ATTENUATION;
	SPECULAR_LIGHT += spec_cut * LIGHT_COLOR * specular_strength * ATTENUATION;
}
