shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// -----------------------------------------------------------------------------
// STYLIZED COBBLESTONE & PLAZA PAVEMENT SHADER (TRIPLANAR + TOON)
// -----------------------------------------------------------------------------

group_uniforms TexturesAndMapping;
uniform sampler2D stone_albedo : source_color, filter_linear_mipmap, hint_default_white;
uniform sampler2D stone_normal : hint_normal, filter_linear_mipmap;
uniform sampler2D stone_roughness : hint_default_white, filter_linear_mipmap;
uniform float triplanar_scale = 0.25;
uniform float triplanar_sharpness : hint_range(1.0, 32.0, 1.0) = 8.0;
uniform vec4 stone_tint : source_color = vec4(0.88, 0.86, 0.82, 1.0);
uniform vec4 grout_shadow_color : source_color = vec4(0.38, 0.36, 0.40, 1.0);
uniform float normal_depth : hint_range(0.0, 3.0, 0.1) = 1.2;

group_uniforms CelLighting;
uniform float light_threshold : hint_range(0.0, 1.0, 0.01) = 0.40;
uniform float light_softness : hint_range(0.001, 0.2, 0.001) = 0.03;
uniform float specular_size : hint_range(0.01, 0.5, 0.01) = 0.04;

varying vec3 v_world_pos;
varying vec3 v_world_normal;
varying vec3 v_view_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	v_view_normal = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
}

vec4 sample_triplanar(sampler2D tex, vec3 p, vec3 weights) {
	vec4 col_x = texture(tex, p.zy * triplanar_scale);
	vec4 col_y = texture(tex, p.xz * triplanar_scale);
	vec4 col_z = texture(tex, p.xy * triplanar_scale);
	return col_x * weights.x + col_y * weights.y + col_z * weights.z;
}

void fragment() {
	vec3 norm = normalize(v_world_normal);
	vec3 blend_weights = pow(abs(norm), vec3(triplanar_sharpness));
	blend_weights /= (blend_weights.x + blend_weights.y + blend_weights.z);
	
	vec4 tex_col = sample_triplanar(stone_albedo, v_world_pos, blend_weights);
	vec4 tex_norm = sample_triplanar(stone_normal, v_world_pos, blend_weights);
	
	// R channel is stone edge / grout mask (0 = grout, >0.20 = stone)
	// G channel is cell random shade variation
	float grout_mask = smoothstep(0.12, 0.28, tex_col.r);
	float stone_variation = (tex_col.g - 0.5) * 0.12;
	vec3 stone_base = clamp(stone_tint.rgb + vec3(stone_variation), 0.0, 1.0);
	vec3 stone_color = mix(grout_shadow_color.rgb, stone_base, grout_mask);
	
	// Distance anti-aliasing fade to avoid sub-pixel moire and shimmer at range
	float dist = -VERTEX.z;
	float dist_fade = clamp((dist - 50.0) / 100.0, 0.0, 1.0);
	vec3 avg_stone = mix(stone_tint.rgb, grout_shadow_color.rgb, 0.20);
	stone_color = mix(stone_color, avg_stone, dist_fade * 0.90);
	
	ALBEDO = stone_color;
	ROUGHNESS = mix(0.98, 0.92, grout_mask);
	SPECULAR = 0.0;
	NORMAL_MAP = tex_norm.rgb;
	NORMAL_MAP_DEPTH = normal_depth * 0.3 * grout_mask * (1.0 - dist_fade);
}

void light() {
	// Use geometric normal for the main cel band to eliminate noisy pixel chatter
	float geom_NdotL = max(dot(normalize(v_view_normal), LIGHT), 0.0);
	float bump_NdotL = max(dot(NORMAL, LIGHT), 0.0);
	float light_factor = geom_NdotL * ATTENUATION;
	float step_light = smoothstep(light_threshold - light_softness, light_threshold + light_softness, light_factor);
	
	// Normal map gently modulates bevel shade without harsh shadow popping
	float bevel_shading = mix(0.88, 1.0, clamp(bump_NdotL * 1.4, 0.0, 1.0));
	vec3 lit_color = ALBEDO * LIGHT_COLOR * bevel_shading;
	DIFFUSE_LIGHT += lit_color * step_light;
}
