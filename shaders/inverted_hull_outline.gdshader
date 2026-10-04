shader_type spatial;
render_mode cull_front, unshaded, depth_draw_never, shadows_disabled;

// -----------------------------------------------------------------------------
// ANIME INVERTED HULL OUTLINE PASS (GODOT 4 FORWARD+)
// Use as next_pass on ShaderMaterial or StandardMaterial3D
// -----------------------------------------------------------------------------

group_uniforms OutlineSettings;
uniform vec4 outline_color : source_color = vec4(0.12, 0.14, 0.18, 1.0); // Anime dark indigo-grey outline
uniform float outline_width : hint_range(0.0, 20.0, 0.1) = 2.5;
uniform float min_distance_clamp : hint_range(0.1, 20.0, 0.1) = 0.5;
uniform float max_distance_clamp : hint_range(10.0, 500.0, 1.0) = 120.0;

group_uniforms DistanceFade;
uniform bool enable_distance_fade = true;
uniform float fade_start_distance : hint_range(10.0, 300.0, 1.0) = 60.0;
uniform float fade_end_distance : hint_range(20.0, 500.0, 1.0) = 120.0;

void vertex() {
	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float cam_dist = length(view_pos.xyz);
	
	// Distance-based outline fade-out:
	// If beyond fade_end_distance, collapse vertex to 0 with w=0 so GPU clipper discards
	// the primitive completely before rasterization without needing fragment discard!
	float fade = 1.0;
	if (enable_distance_fade) {
		fade = clamp(1.0 - (cam_dist - fade_start_distance) / max(fade_end_distance - fade_start_distance, 0.001), 0.0, 1.0);
		fade = smoothstep(0.0, 1.0, fade);
	}
	
	if (fade <= 0.0001) {
		POSITION = vec4(0.0, 0.0, 2.0, 0.0);
	} else {
		// Perspective depth compensation:
		vec3 view_normal = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
		float depth = clamp(-view_pos.z, min_distance_clamp, max_distance_clamp);
		view_pos.xyz += view_normal * (outline_width * 0.001 * depth * fade);
		POSITION = PROJECTION_MATRIX * view_pos;
	}
}

void fragment() {
	ALBEDO = outline_color.rgb;
}

