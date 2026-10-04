shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// -----------------------------------------------------------------------------
// SWORD ART ONLINE STYLIZED TOON SHADER (GODOT 4 FORWARD+)
// -----------------------------------------------------------------------------

group_uniforms BaseProperties;
uniform vec4 albedo_color : source_color = vec4(0.92, 0.90, 0.86, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, hint_default_white;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);

group_uniforms CelBandedLighting;
uniform vec4 shadow_tint : source_color = vec4(0.549, 0.600, 0.722, 1.0); // Anime cool-tinted shadow (#8C99B8)
uniform float shadow_threshold : hint_range(0.0, 1.0, 0.01) = 0.35;
uniform float shadow_softness : hint_range(0.001, 0.2, 0.001) = 0.02; // Very small for sharp cel cut
uniform float half_shadow_threshold : hint_range(0.0, 1.0, 0.01) = 0.60;
uniform float half_shadow_softness : hint_range(0.001, 0.2, 0.001) = 0.03;
uniform float half_shadow_intensity : hint_range(0.0, 1.0, 0.01) = 0.50;
uniform bool use_toon_ramp_texture = false;
uniform sampler2D toon_ramp_texture : hint_default_white, filter_nearest;

group_uniforms SpecularHighlight;
uniform float specular_size : hint_range(0.0, 1.0, 0.01) = 0.06;
uniform float specular_softness : hint_range(0.001, 0.1, 0.001) = 0.015;
uniform vec4 specular_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float roughness : hint_range(0.0, 1.0, 0.01) = 0.3;

group_uniforms AnimeRimLight;
uniform bool enable_rim = true;
uniform vec4 rim_color : source_color = vec4(0.95, 0.98, 1.0, 1.0);
uniform float rim_threshold : hint_range(0.0, 1.0, 0.01) = 0.50;
uniform float rim_softness : hint_range(0.001, 0.5, 0.001) = 0.04;
uniform float rim_spread : hint_range(0.5, 4.0, 0.1) = 2.0;

group_uniforms AmbientAndDetails;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap;
uniform float normal_scale : hint_range(0.0, 2.0, 0.05) = 1.0;
uniform bool use_vertex_color_ao = true;
group_uniforms ArchitectureColors;
uniform bool use_architectural_colors = false;
uniform vec4 wall_color : source_color = vec4(0.886, 0.867, 0.835, 1.0);     // #E2DDD5 Classic ivory/limestone wall
uniform vec4 roof_color_top : source_color = vec4(0.722, 0.290, 0.161, 1.0); // #B84A29 Terracotta orange-red ridge
uniform vec4 roof_color_edge : source_color = vec4(0.580, 0.220, 0.120, 1.0);// Terracotta eaves shadow
uniform vec4 roof_slate_color : source_color = vec4(0.35, 0.42, 0.50, 1.0);  // Slate stone gray variant
uniform float roof_slope_threshold : hint_range(0.0, 1.0, 0.05) = 0.25;
uniform float roof_gradient_scale : hint_range(0.5, 20.0, 0.5) = 4.0;

varying float v_cam_dist;
varying vec3 v_local_pos;

void vertex() {
	UV = UV * uv_scale + uv_offset;
	v_local_pos = VERTEX;
	v_cam_dist = length((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
}

void fragment() {
	vec4 tex_albedo = texture(albedo_texture, UV);
	vec3 base_color;
	
	if (use_architectural_colors) {
		// Identify roof vs wall by normal slope (sloped/upward faces are roofs)
		float slope = clamp(NORMAL.y, 0.0, 1.0);
		float is_roof = smoothstep(roof_slope_threshold - 0.05, roof_slope_threshold + 0.05, slope);
		
		// Subtle gradient from ridge to eaves along local height
		float roof_grad = clamp(fract(v_local_pos.y / roof_gradient_scale), 0.0, 1.0);
		vec3 terracotta_roof = mix(roof_color_edge.rgb, roof_color_top.rgb, roof_grad);
		
		// Variant: support slate roof if instance color blue channel exceeds red
		vec3 selected_roof = terracotta_roof;
		if (use_vertex_color_ao && COLOR.b > COLOR.r * 1.05) {
			selected_roof = mix(roof_slate_color.rgb * 0.85, roof_slate_color.rgb * 1.15, roof_grad);
		}
		
		base_color = mix(wall_color.rgb, selected_roof, is_roof) * tex_albedo.rgb;
	} else {
		base_color = albedo_color.rgb * tex_albedo.rgb;
		if (use_vertex_color_ao) {
			base_color *= COLOR.rgb;
		}
	}
	
	ALBEDO = base_color;
	ROUGHNESS = roughness;
	
	NORMAL_MAP = texture(normal_map, UV).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
}

void light() {
	// N dot L diffuse calculation
	float NdotL = max(dot(NORMAL, LIGHT), 0.0);
	float atten = ATTENUATION;
	
	// Distance attenuation to eliminate distant sub-pixel geometric glittering and edge shimmering (>50m to 120m)
	float dist_fade = clamp(1.0 - (v_cam_dist - 50.0) / 70.0, 0.0, 1.0);
	
	vec3 direct_diffuse = vec3(0.0);
	float core_shadow = 1.0;
	
	if (use_toon_ramp_texture) {
		float light_factor = NdotL * atten;
		float ramp_coord = clamp(light_factor, 0.01, 0.99);
		vec3 ramp_val = texture(toon_ramp_texture, vec2(ramp_coord, 0.5)).rgb;
		direct_diffuse = ALBEDO * LIGHT_COLOR * ramp_val;
		core_shadow = clamp(ramp_val.r + ramp_val.g + ramp_val.b, 0.0, 1.0);
	} else {
		// Decouple form shadow (N dot L) from shadow map atten to prevent PCF shadow dithering noise
		float form_core = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, NdotL);
		float form_mid = smoothstep(half_shadow_threshold - half_shadow_softness, half_shadow_threshold + half_shadow_softness, NdotL);
		
		// Smooth cast-shadow occlusion step
		float shadow_occ = smoothstep(0.12, 0.55, atten);
		
		core_shadow = form_core * shadow_occ;
		float mid_shadow = form_mid * shadow_occ;
		
		// 3-Tone SAO Anime Lighting Palette:
		// Core shadow preserves energy by zeroing direct diffuse, allowing ambient sky light to illuminate shadows.
		// Penumbra transitions from cool midtone to full sunny lit band.
		vec3 mid_band = mix(ALBEDO * shadow_tint.rgb, ALBEDO, half_shadow_intensity);
		vec3 lit_band = ALBEDO;
		
		vec3 band_color = mix(mid_band, lit_band, mid_shadow);
		direct_diffuse = band_color * LIGHT_COLOR * core_shadow;
	}
	
	// Anime Stylized Specular Highlight (Blinn-Phong with sharp cel cut)
	vec3 specular = vec3(0.0);
	if (specular_size > 0.001) {
		vec3 H = normalize(VIEW + LIGHT);
		float NdotH = max(dot(NORMAL, H), 0.0);
		float spec_intensity = pow(NdotH, 128.0 * (1.0 - roughness + 0.01));
		float spec_cut = smoothstep(1.0 - specular_size - specular_softness, 1.0 - specular_size + specular_softness, spec_intensity);
		specular = spec_cut * specular_color.rgb * LIGHT_COLOR * core_shadow * dist_fade;
	}
	
	// Stylized Anime Rim Light (Fresnel rim with silhouette backlight grazing alignment)
	vec3 rim = vec3(0.0);
	if (enable_rim) {
		float NdotV = 1.0 - max(dot(NORMAL, VIEW), 0.0);
		float rim_intensity = pow(NdotV, rim_spread);
		// Rim catches backlight and grazing contours (surfaces glancing away from the light)
		float backlight_align = clamp(-dot(NORMAL, LIGHT) * 0.5 + 0.5, 0.2, 1.0);
		float rim_term = rim_intensity * backlight_align;
		float rim_cut = smoothstep(rim_threshold - rim_softness, rim_threshold + rim_softness, rim_term);
		rim = rim_cut * rim_color.rgb * LIGHT_COLOR * atten * dist_fade;
	}
	
	DIFFUSE_LIGHT += direct_diffuse;
	SPECULAR_LIGHT += specular + rim;
}
