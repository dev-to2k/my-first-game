extends SceneTree
## SAO Starting City kit builder. Saves part scenes + res://scenes/sao_starting_city.tscn
## Implements Floor 1 Aincrad Full Architecture:
## - Labyrinth Tower (North 320m Landmark)
## - Black Iron Palace (East Kurogane Palace)
## - Central Teleport Gate Plaza & Multi-Tier Twin Fountains
## - Market Street with Medieval Merchant Stalls & Warm Lanterns
## - Grand City Wall with Moat & Arched Stone Bridge
## - Windmill Ridge on West Foothills with Animated Rotating Sails
## - Floor 2 Iron/Stone Underbelly Vault Canopy
## - Stratified Anime Cumulus Cloud Bands
## - Perimeter Mountain Ranges & Battlement Fortifications
## - Toon Cel-Shading, Inverted Hull Outlines, Stylized Water & Cobblestone Triplanar

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://scenes/parts")
	_ensure_textures()
	_build_city_kit_scenes()
	_build_church()
	_build_lake()
	_build_wall()
	_build_floor2_ceiling()
	_build_perimeter_landscape()
	_build_anime_clouds()
	_build_labyrinth_tower()
	_build_black_iron_palace()
	_build_windmill_ridge()
	_build_teleport_plaza()
	_build_market_street()
	_build_main()
	print("BUILD_CITY_DONE")
	quit()

func _ensure_textures() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/textures")
	var req := [
		"res://assets/textures/cobblestone_pattern.png",
		"res://assets/textures/cobblestone_normal.png",
		"res://assets/textures/water_wave_normal_1.png",
		"res://assets/textures/water_wave_normal_2.png",
		"res://assets/textures/water_foam_noise.png"
	]
	var all_exist := true
	for p in req:
		if not FileAccess.file_exists(p):
			all_exist = false
			break
	if not all_exist:
		var fn_edge := FastNoiseLite.new()
		fn_edge.noise_type = FastNoiseLite.TYPE_CELLULAR
		fn_edge.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
		fn_edge.cellular_jitter = 0.85
		fn_edge.frequency = 0.035
		var img_edge: Image = fn_edge.get_seamless_image(512, 512)

		var fn_cell := FastNoiseLite.new()
		fn_cell.noise_type = FastNoiseLite.TYPE_CELLULAR
		fn_cell.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
		fn_cell.cellular_jitter = 0.85
		fn_cell.frequency = 0.035
		var img_cell: Image = fn_cell.get_seamless_image(512, 512)

		var fn_dist := FastNoiseLite.new()
		fn_dist.noise_type = FastNoiseLite.TYPE_CELLULAR
		fn_dist.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
		fn_dist.cellular_jitter = 0.85
		fn_dist.frequency = 0.035
		var img_dist: Image = fn_dist.get_seamless_image(512, 512)

		var cobble_img := Image.create(512, 512, false, Image.FORMAT_RGBA8)
		var cobble_bump := Image.create(512, 512, false, Image.FORMAT_RF)
		for y in 512:
			for x in 512:
				var r_val: float = img_edge.get_pixel(x, y).r
				var g_val: float = img_cell.get_pixel(x, y).r
				var b_val: float = img_dist.get_pixel(x, y).r
				var stone_height: float = clamp((r_val - 0.05) * 1.5, 0.0, 1.0)
				cobble_img.set_pixel(x, y, Color(r_val, g_val, b_val, 1.0))
				cobble_bump.set_pixel(x, y, Color(stone_height, stone_height, stone_height, 1.0))

		cobble_img.generate_mipmaps()
		cobble_img.save_png("res://assets/textures/cobblestone_pattern.png")
		cobble_bump.generate_mipmaps()
		cobble_bump.bump_map_to_normal_map(3.5)
		cobble_bump.save_png("res://assets/textures/cobblestone_normal.png")

		var fn_w1 := FastNoiseLite.new()
		fn_w1.noise_type = FastNoiseLite.TYPE_SIMPLEX
		fn_w1.frequency = 0.025
		fn_w1.fractal_octaves = 3
		var w1_img: Image = fn_w1.get_seamless_image(512, 512)
		w1_img.generate_mipmaps()
		w1_img.bump_map_to_normal_map(2.0)
		w1_img.save_png("res://assets/textures/water_wave_normal_1.png")

		var fn_w2 := FastNoiseLite.new()
		fn_w2.noise_type = FastNoiseLite.TYPE_SIMPLEX
		fn_w2.frequency = 0.045
		fn_w2.seed = 8821
		fn_w2.fractal_octaves = 2
		var w2_img: Image = fn_w2.get_seamless_image(512, 512)
		w2_img.generate_mipmaps()
		w2_img.bump_map_to_normal_map(1.5)
		w2_img.save_png("res://assets/textures/water_wave_normal_2.png")

		var fn_foam := FastNoiseLite.new()
		fn_foam.noise_type = FastNoiseLite.TYPE_SIMPLEX
		fn_foam.frequency = 0.05
		fn_foam.fractal_octaves = 3
		var foam_img: Image = fn_foam.get_seamless_image(512, 512)
		foam_img.generate_mipmaps()
		foam_img.save_png("res://assets/textures/water_foam_noise.png")

func _get_toon_material(color: Color = Color.WHITE, use_vert_color: bool = true, outline_width: float = 2.2) -> ShaderMaterial:
	var toon_mat := ShaderMaterial.new()
	toon_mat.shader = load("res://shaders/toon_cel_shading.gdshader")
	if outline_width > 0.0:
		var outline_mat := ShaderMaterial.new()
		outline_mat.shader = load("res://shaders/inverted_hull_outline.gdshader")
		outline_mat.set_shader_parameter("outline_color", Color(0.12, 0.14, 0.18, 1.0))
		outline_mat.set_shader_parameter("outline_width", outline_width)
		outline_mat.set_shader_parameter("min_distance_clamp", 0.5)
		outline_mat.set_shader_parameter("max_distance_clamp", 120.0)
		outline_mat.set_shader_parameter("enable_distance_fade", true)
		outline_mat.set_shader_parameter("fade_start_distance", 60.0)
		outline_mat.set_shader_parameter("fade_end_distance", 120.0)
		toon_mat.next_pass = outline_mat
	
	toon_mat.set_shader_parameter("albedo_color", color)
	toon_mat.set_shader_parameter("shadow_tint", Color(0.549, 0.600, 0.722, 1.0))
	toon_mat.set_shader_parameter("shadow_threshold", 0.35)
	toon_mat.set_shader_parameter("shadow_softness", 0.02)
	toon_mat.set_shader_parameter("half_shadow_threshold", 0.60)
	toon_mat.set_shader_parameter("half_shadow_softness", 0.03)
	toon_mat.set_shader_parameter("half_shadow_intensity", 0.50)
	toon_mat.set_shader_parameter("specular_size", 0.04)
	toon_mat.set_shader_parameter("specular_softness", 0.015)
	toon_mat.set_shader_parameter("specular_color", Color.WHITE)
	toon_mat.set_shader_parameter("roughness", 0.70)
	toon_mat.set_shader_parameter("enable_rim", true)
	toon_mat.set_shader_parameter("rim_color", Color(0.95, 0.98, 1.0, 1.0))
	toon_mat.set_shader_parameter("rim_threshold", 0.50)
	toon_mat.set_shader_parameter("rim_softness", 0.04)
	toon_mat.set_shader_parameter("rim_spread", 2.0)
	toon_mat.set_shader_parameter("use_vertex_color_ao", use_vert_color)
	return toon_mat

func _get_cobblestone_material(tint: Color = Color(0.82, 0.80, 0.76), scale: float = 0.25) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/stylized_cobblestone.gdshader")
	mat.set_shader_parameter("stone_tint", tint)
	mat.set_shader_parameter("grout_shadow_color", Color(0.38, 0.36, 0.40, 1.0))
	mat.set_shader_parameter("triplanar_scale", scale)
	mat.set_shader_parameter("triplanar_sharpness", 8.0)
	mat.set_shader_parameter("light_threshold", 0.40)
	mat.set_shader_parameter("light_softness", 0.03)
	mat.set_shader_parameter("specular_size", 0.04)
	mat.set_shader_parameter("normal_depth", 1.2)
	mat.set_shader_parameter("stone_albedo", load("res://assets/textures/cobblestone_pattern.png"))
	mat.set_shader_parameter("stone_normal", load("res://assets/textures/cobblestone_normal.png"))
	return mat

func _get_water_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/stylized_water.gdshader")
	mat.set_shader_parameter("shallow_color", Color(0.24, 0.74, 0.82, 0.78))
	mat.set_shader_parameter("deep_color", Color(0.06, 0.22, 0.50, 0.96))
	mat.set_shader_parameter("depth_distance", 1.4)
	mat.set_shader_parameter("beer_law_attenuation", 1.2)
	mat.set_shader_parameter("foam_color", Color(0.96, 0.99, 1.0, 1.0))
	mat.set_shader_parameter("shore_foam_threshold", 0.25)
	mat.set_shader_parameter("foam_softness", 0.05)
	mat.set_shader_parameter("foam_scroll_speed", Vector2(0.03, 0.02))
	mat.set_shader_parameter("wave_speed_1", Vector2(0.04, 0.02))
	mat.set_shader_parameter("wave_speed_2", Vector2(-0.03, 0.05))
	mat.set_shader_parameter("wave_scale_1", 3.0)
	mat.set_shader_parameter("wave_scale_2", 6.0)
	mat.set_shader_parameter("normal_strength", 0.65)
	mat.set_shader_parameter("vertex_wave_height", 0.025)
	mat.set_shader_parameter("vertex_wave_frequency", 0.35)
	mat.set_shader_parameter("roughness", 0.04)
	mat.set_shader_parameter("specular_strength", 1.3)
	mat.set_shader_parameter("refraction_strength", 0.02)
	mat.set_shader_parameter("foam_noise", load("res://assets/textures/water_foam_noise.png"))
	mat.set_shader_parameter("wave_normal_map_1", load("res://assets/textures/water_wave_normal_1.png"))
	mat.set_shader_parameter("wave_normal_map_2", load("res://assets/textures/water_wave_normal_2.png"))
	return mat

func _get_sky_material() -> ShaderMaterial:
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/aincrad_sky.gdshader")
	sm.set_shader_parameter("sky_top_color", Color(0.14, 0.44, 0.88, 1.0))
	sm.set_shader_parameter("sky_mid_color", Color(0.36, 0.68, 0.96, 1.0))
	sm.set_shader_parameter("sky_horizon_color", Color(0.78, 0.91, 0.99, 1.0))
	sm.set_shader_parameter("ground_horizon_color", Color(0.68, 0.76, 0.84, 1.0))
	sm.set_shader_parameter("ground_bottom_color", Color(0.28, 0.32, 0.38, 1.0))
	sm.set_shader_parameter("sun_tint", Color(1.0, 0.96, 0.84, 1.0))
	sm.set_shader_parameter("sun_disk_size", 0.035)
	sm.set_shader_parameter("sun_disk_softness", 0.008)
	sm.set_shader_parameter("sun_halo_size", 0.32)
	sm.set_shader_parameter("sun_halo_intensity", 0.45)
	sm.set_shader_parameter("wisp_coverage", 0.35)
	sm.set_shader_parameter("wisp_speed", 0.003)
	return sm

func _mat(c: Color, rough: float = 0.9, _metallic: float = 0.0) -> ShaderMaterial:
	var m := _get_toon_material(c, false, 2.0)
	m.set_shader_parameter("roughness", rough)
	if rough > 0.82:
		m.set_shader_parameter("specular_size", 0.0)
	else:
		m.set_shader_parameter("specular_size", 0.05)
	return m

func _box(size: Vector3, mat: Material) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	b.material = mat
	return b

func _cyl(rt: float, rb: float, h: float, mat: Material, seg: int = 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = seg
	c.material = mat
	return c

func _sph(r: float, h: float, mat: Material, hemi: bool = false) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = h
	s.radial_segments = 16
	s.rings = 8
	s.is_hemisphere = hemi
	s.material = mat
	return s

func _prism(size: Vector3, mat: Material) -> PrismMesh:
	var p := PrismMesh.new()
	p.size = size
	p.material = mat
	return p

func _torus(in_r: float, out_r: float, mat: Material, r_seg: int = 32, rings: int = 12) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = in_r
	t.outer_radius = out_r
	t.ring_segments = r_seg
	t.rings = rings
	t.material = mat
	return t

func _mi(mesh: Mesh, pos: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	return mi

func _pack_save(node: Node, path: String) -> void:
	var ps := PackedScene.new()
	ps.pack(node)
	ResourceSaver.save(ps, path)

func _mesh_of(path: String) -> Mesh:
	var ps: PackedScene = load(path)
	var inst = ps.instantiate()
	var stack: Array = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var m: Mesh = n.mesh
			return m
		for c in n.get_children():
			stack.append(c)
	return null

func _build_church() -> void:
	var r := Node3D.new()
	r.name = "Church"
	var wall_m := _mat(Color(0.906, 0.894, 0.863))
	var dome_m := _mat(Color(0.45, 0.55, 0.62), 0.5, 0.4)
	var roof_m := _mat(Color(0.769, 0.416, 0.227), 0.8)
	var dark_m := _mat(Color(0.16, 0.17, 0.20), 0.6)
	
	# Main Basilica Nave & Transept
	r.add_child(_mi(_box(Vector3(26, 11, 16), wall_m), Vector3(0, 5.5, 0)))
	r.add_child(_mi(_sph(9.0, 9.0, dome_m, true), Vector3(0, 11.0, 0)))
	
	# 4 Corner Turrets
	for sx in [-9.0, 9.0]:
		for sz in [-5.0, 5.0]:
			r.add_child(_mi(_cyl(1.6, 1.8, 12.0, wall_m), Vector3(sx, 6, sz)))
			r.add_child(_mi(_cyl(0.05, 1.7, 3.4, dome_m), Vector3(sx, 13.7, sz)))
	
	# Twin Romanesque Belfry Towers on facade (replaces single obstructive thin needle)
	for tx in [-7.5, 7.5]:
		r.add_child(_mi(_cyl(2.2, 2.5, 20.0, wall_m, 12), Vector3(tx, 10.0, 7.0)))
		r.add_child(_mi(_cyl(0.05, 2.6, 6.5, roof_m, 12), Vector3(tx, 23.25, 7.0)))
	
	# Cathedral Front Portal
	r.add_child(_mi(_box(Vector3(6, 7, 1.2), dark_m), Vector3(0, 3.5, 8.1)))
	
	for c in r.get_children():
		c.owner = r
	_pack_save(r, "res://scenes/parts/church.tscn")

func _build_lake() -> void:
	var r := Node3D.new()
	r.name = "LakePark"
	var grass_m := _mat(Color(0.28, 0.52, 0.26))
	var stone_m := _mat(Color(0.66, 0.63, 0.57))
	var lakebed_m := _mat(Color(0.08, 0.20, 0.28))
	var cream_m := _mat(Color(0.906, 0.894, 0.863))
	var water_lily_m := _mat(Color(0.32, 0.65, 0.30))
	var flower_m := _mat(Color(0.95, 0.55, 0.70))
	var wood_bench_m := _mat(Color(0.42, 0.28, 0.18))
	
	# 60m x 30m Rectangular Water Park
	# Surrounding grassy park banks
	r.add_child(_mi(_box(Vector3(3, 0.35, 60), grass_m), Vector3(-16.2, 0.15, 0)))
	r.add_child(_mi(_box(Vector3(3, 0.35, 60), grass_m), Vector3(16.2, 0.15, 0)))
	r.add_child(_mi(_box(Vector3(36, 0.35, 3), grass_m), Vector3(0, 0.15, -31.5)))
	r.add_child(_mi(_box(Vector3(36, 0.35, 3), grass_m), Vector3(0, 0.15, 31.5)))

	# Stone quay / embankment border lining the lake inner edge (30m x 60m)
	r.add_child(_mi(_box(Vector3(1.8, 0.5, 60), stone_m), Vector3(-13.9, 0.2, 0)))
	r.add_child(_mi(_box(Vector3(1.8, 0.5, 60), stone_m), Vector3(13.9, 0.2, 0)))
	r.add_child(_mi(_box(Vector3(30, 0.5, 1.8), stone_m), Vector3(0, 0.2, -29.1)))
	r.add_child(_mi(_box(Vector3(30, 0.5, 1.8), stone_m), Vector3(0, 0.2, 29.1)))

	# Sunken lakebed bottom under water
	r.add_child(_mi(_box(Vector3(26, 0.6, 56), lakebed_m), Vector3(0, -1.0, 0)))
	
	# Water surface (PlaneMesh with fine subdivision, 26m x 56m inside 30m x 60m border)
	var water_pm := PlaneMesh.new()
	water_pm.size = Vector2(26, 56)
	water_pm.subdivide_width = 32
	water_pm.subdivide_depth = 64
	water_pm.material = _get_water_material()
	var water_mi := _mi(water_pm, Vector3(0, 0.12, 0))
	water_mi.name = "WaterSurface"
	r.add_child(water_mi)

	# Water lily clusters with anime lotus flowers
	var lily_positions := [
		Vector3(16.0, 0.13, -8.0),
		Vector3(22.0, 0.13, 10.0),
		Vector3(-6.0, 0.13, 14.0),
		Vector3(-22.0, 0.13, -12.0)
	]
	for lp in lily_positions:
		var pad := _mi(_cyl(1.4, 1.5, 0.02, water_lily_m, 10), lp)
		r.add_child(pad)
		var lotus := _mi(_sph(0.35, 0.5, flower_m), lp + Vector3(0.3, 0.2, 0.2))
		r.add_child(lotus)

	# Pavilion stone base & pillars & roof on west side
	r.add_child(_mi(_box(Vector3(14, 0.8, 10), stone_m), Vector3(-14, 0.15, 0)))
	for cx in [-17.0, -11.0]:
		for cz in [-3.5, 3.5]:
			r.add_child(_mi(_cyl(0.25, 0.28, 2.8, cream_m, 8), Vector3(cx, 1.8, cz)))
	t_roof(r, Vector3(8.0, 1.8, 9.0), Vector3(-14, 4.0, 0))
	r.add_child(_mi(_box(Vector3(6, 0.35, 3), stone_m), Vector3(-24, 0.3, 0)))

	# Lake island knoll with stone rim and anime small tree
	var island_stone := _mi(_cyl(4.5, 4.8, 0.6, stone_m, 16), Vector3(8, 0.15, 2))
	r.add_child(island_stone)
	var island_grass := _mi(_cyl(4.2, 4.2, 0.15, grass_m, 16), Vector3(8, 0.45, 2))
	r.add_child(island_grass)
	var island_tree_mesh: Mesh = _mesh_of("res://assets/kit/tree_small.glb")
	if island_tree_mesh != null:
		var island_tree := _mi(island_tree_mesh, Vector3(8, 0.52, 2))
		island_tree.material_override = _get_toon_material(Color(0.94, 0.93, 0.91), true, 2.2)
		r.add_child(island_tree)

	# Park benches along promenade
	for bx in [-28.0, 24.0]:
		r.add_child(_mi(_box(Vector3(2.6, 0.45, 0.8), wood_bench_m), Vector3(bx, 0.38, 23.0)))
		r.add_child(_mi(_box(Vector3(2.6, 0.45, 0.8), wood_bench_m), Vector3(bx, 0.38, -23.0)))

	for c in r.get_children():
		c.owner = r
	_pack_save(r, "res://scenes/parts/lake_park.tscn")

func t_roof(parent: Node, size: Vector3, pos: Vector3) -> void:
	var p := PrismMesh.new()
	p.size = size
	p.material = _mat(Color(0.769, 0.416, 0.227), 0.8)
	parent.add_child(_mi(p, pos))

func _build_wall() -> void:
	var r := Node3D.new()
	r.name = "CityWall"
	var stone := _mat(Color(0.60, 0.59, 0.54), 0.85)
	var dark_stone := _mat(Color(0.44, 0.43, 0.40), 0.9)
	var roof_m := _mat(Color(0.722, 0.290, 0.161), 0.8)
	var iron_m := _mat(Color(0.18, 0.18, 0.22), 0.5)
	var banner_red_m := _mat(Color(0.78, 0.18, 0.22))
	var banner_blue_m := _mat(Color(0.15, 0.35, 0.78))
	
	var center_z: float = 15.0
	var r_wall: float = 195.0
	var segments: int = 24
	var ang_start: float = 0.20
	var ang_end: float = PI - 0.20
	var ang_step: float = (ang_end - ang_start) / float(segments)
	
	for i in segments:
		var a_mid: float = ang_start + (float(i) + 0.5) * ang_step
		var p_mid := Vector3(cos(a_mid) * r_wall, 0, center_z + sin(a_mid) * r_wall)
		if abs(p_mid.x) < 13.0:
			continue
		var a_yaw: float = -a_mid + PI * 0.5
		r.add_child(_mi(_box(Vector3(5.0, 18.0, 23.0), stone), Vector3(p_mid.x, 9.0, p_mid.z), Vector3(0, a_yaw, 0)))
		r.add_child(_mi(_box(Vector3(5.8, 1.6, 23.0), dark_stone), Vector3(p_mid.x, 18.8, p_mid.z), Vector3(0, a_yaw, 0)))
		r.add_child(_mi(_box(Vector3(1.2, 1.4, 11.0), dark_stone), Vector3(p_mid.x, 20.3, p_mid.z), Vector3(0, a_yaw, 0)))
		
		# Bastion tower every 4th segment
		if i % 4 == 1:
			r.add_child(_mi(_cyl(5.0, 5.4, 24.0, stone, 16), Vector3(p_mid.x, 12.0, p_mid.z)))
			r.add_child(_mi(_cyl(0.05, 5.8, 6.5, roof_m, 16), Vector3(p_mid.x, 27.25, p_mid.z)))
			
	# Grand South Gatehouse
	for gx in [-13.5, 13.5]:
		r.add_child(_mi(_cyl(5.4, 5.8, 32.0, stone, 18), Vector3(gx, 16.0, 180.0)))
		r.add_child(_mi(_cyl(0.05, 6.2, 8.0, roof_m, 18), Vector3(gx, 36.0, 180.0)))
	r.add_child(_mi(_box(Vector3(18.0, 12.0, 6.5), stone), Vector3(0, 22.0, 180.0)))
	r.add_child(_mi(_box(Vector3(20.0, 1.8, 7.2), dark_stone), Vector3(0, 28.9, 180.0)))
	for px in range(-7, 8, 2):
		r.add_child(_mi(_cyl(0.12, 0.12, 9.0, iron_m, 6), Vector3(float(px), 11.5, 180.5)))
	r.add_child(_mi(_box(Vector3(16.0, 0.4, 0.4), iron_m), Vector3(0, 13.0, 180.5)))
	r.add_child(_mi(_box(Vector3(2.2, 9.0, 0.15), banner_red_m), Vector3(-13.5, 17.0, 185.3)))
	r.add_child(_mi(_box(Vector3(2.2, 9.0, 0.15), banner_blue_m), Vector3(13.5, 17.0, 185.3)))
	
	# Semi-Circular Turquoise Water Moat (R = 207m, width 18m)
	var r_moat: float = 207.0
	for i in segments:
		var a_mid: float = ang_start + (float(i) + 0.5) * ang_step
		var m_mid := Vector3(cos(a_mid) * r_moat, 0, center_z + sin(a_mid) * r_moat)
		if abs(m_mid.x) < 9.0:
			continue
		var a_yaw: float = -a_mid + PI * 0.5
		var water_pm := PlaneMesh.new()
		water_pm.size = Vector2(18.0, 25.0)
		water_pm.material = _get_water_material()
		r.add_child(_mi(water_pm, Vector3(m_mid.x, -0.4, m_mid.z), Vector3(0, a_yaw, 0)))
		var curb_p := Vector3(cos(a_mid) * (r_moat + 9.0), 0, center_z + sin(a_mid) * (r_moat + 9.0))
		r.add_child(_mi(_box(Vector3(1.4, 2.5, 25.0), stone), Vector3(curb_p.x, -0.2, curb_p.z), Vector3(0, a_yaw, 0)))
		
	# Grand Arched Stone Moat Bridge over canal (from Z=180 to Z=210)
	var bridge_deck := _get_cobblestone_material(Color(0.85, 0.83, 0.80), 0.35)
	r.add_child(_mi(_box(Vector3(16.0, 1.4, 30.0), bridge_deck), Vector3(0, 0.2, 195.0)))
	r.add_child(_mi(_box(Vector3(1.2, 1.4, 30.0), stone), Vector3(-8.2, 1.4, 195.0)))
	r.add_child(_mi(_box(Vector3(1.2, 1.4, 30.0), stone), Vector3(8.2, 1.4, 195.0)))
	r.add_child(_mi(_cyl(4.5, 4.5, 15.0, stone, 16), Vector3(0, -2.0, 190.0), Vector3(0, 0, PI * 0.5)))
	r.add_child(_mi(_cyl(4.5, 4.5, 15.0, stone, 16), Vector3(0, -2.0, 200.0), Vector3(0, 0, PI * 0.5)))

	for c in r.get_children():
		c.owner = r
	_pack_save(r, "res://scenes/parts/city_wall.tscn")

func _build_labyrinth_tower() -> void:
	var r := Node3D.new()
	r.name = "LabyrinthTower"
	
	var base_m := _get_toon_material(Color(0.18, 0.20, 0.26), false, 0.0)
	base_m.set_shader_parameter("roughness", 0.88)
	base_m.set_shader_parameter("shadow_tint", Color(0.28, 0.34, 0.48))
	
	var mid_m := _get_toon_material(Color(0.24, 0.27, 0.34), false, 0.0)
	mid_m.set_shader_parameter("roughness", 0.85)
	mid_m.set_shader_parameter("shadow_tint", Color(0.34, 0.40, 0.52))
	
	var dark_iron_m := _get_toon_material(Color(0.13, 0.15, 0.19), false, 1.5)
	dark_iron_m.set_shader_parameter("roughness", 0.45)
	dark_iron_m.set_shader_parameter("shadow_tint", Color(0.22, 0.25, 0.35))
	
	var rune_glow_m := StandardMaterial3D.new()
	rune_glow_m.albedo_color = Color(0.18, 0.90, 1.0)
	rune_glow_m.emission_enabled = true
	rune_glow_m.emission = Color(0.18, 0.90, 1.0)
	rune_glow_m.emission_energy_multiplier = 4.8
	rune_glow_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Monumental Stepped Fluted Cylinders piercing into Floor 2 ceiling vault (height 168m)
	r.add_child(_mi(_cyl(44.0, 49.0, 30.0, base_m, 32), Vector3(0, 15.0, 0)))
	r.add_child(_mi(_cyl(36.0, 40.0, 36.0, base_m, 28), Vector3(0, 48.0, 0)))
	r.add_child(_mi(_cyl(27.0, 32.0, 40.0, mid_m, 24), Vector3(0, 86.0, 0)))
	r.add_child(_mi(_cyl(18.0, 23.0, 42.0, mid_m, 20), Vector3(0, 127.0, 0)))
	r.add_child(_mi(_cyl(11.0, 15.0, 36.0, dark_iron_m, 16), Vector3(0, 166.0, 0)))
	
	# 4 Glowing Azure Runic Energy Rings encircling tower at tier steps
	r.add_child(_mi(_torus(43.0, 46.0, rune_glow_m, 36, 12), Vector3(0, 30.0, 0)))
	r.add_child(_mi(_torus(35.0, 37.5, rune_glow_m, 32, 10), Vector3(0, 66.0, 0)))
	r.add_child(_mi(_torus(26.0, 28.2, rune_glow_m, 28, 8), Vector3(0, 106.0, 0)))
	r.add_child(_mi(_torus(17.0, 19.0, rune_glow_m, 24, 8), Vector3(0, 148.0, 0)))

	# 8 Vertical Runic Conduits bridging the energy rings
	for i in 8:
		var a := TAU * float(i) / 8.0
		var dir := Vector3(cos(a), 0, sin(a))
		r.add_child(_mi(_box(Vector3(0.7, 72.0, 0.7), rune_glow_m), dir * 31.0 + Vector3(0, 72.0, 0), Vector3(0, -a, 0)))

	# 8 Flying Buttress Pylons radiating at base into chasm
	for i in 8:
		var a := TAU * float(i) / 8.0
		var dir := Vector3(cos(a), 0, sin(a))
		var norm_yaw := -a + PI * 0.5
		# Outer buttress pier
		r.add_child(_mi(_cyl(2.6, 3.6, 44.0, base_m, 8), dir * 58.0 + Vector3(0, 22.0, 0)))
		r.add_child(_mi(_cyl(0.05, 3.0, 8.0, dark_iron_m, 8), dir * 58.0 + Vector3(0, 48.0, 0)))
		# Lower and upper arched buttress struts
		r.add_child(_mi(_box(Vector3(2.6, 16.0, 22.0), base_m), dir * 46.0 + Vector3(0, 18.0, 0), Vector3(0.12, norm_yaw, 0)))
		r.add_child(_mi(_box(Vector3(2.0, 12.0, 20.0), dark_iron_m), dir * 45.0 + Vector3(0, 38.0, 0), Vector3(0.16, norm_yaw, 0)))

	# 8 Fluted Gothic Spire Turrets around mid balcony
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var dir := Vector3(cos(a), 0, sin(a))
		r.add_child(_mi(_cyl(1.4, 1.8, 26.0, dark_iron_m, 8), dir * 30.0 + Vector3(0, 107.0, 0)))
		r.add_child(_mi(_cyl(0.05, 1.6, 7.0, rune_glow_m, 8), dir * 30.0 + Vector3(0, 123.5, 0)))

	# Grand Dungeon Portal on south side (facing Town of Beginnings)
	r.add_child(_mi(_box(Vector3(14, 18, 8), base_m), Vector3(0, 9, 47)))
	r.add_child(_mi(_box(Vector3(8, 12, 10), dark_iron_m), Vector3(0, 6, 47)))
	r.add_child(_mi(_sph(3.4, 6.8, rune_glow_m), Vector3(0, 6, 45)))

	for c in r.get_children():
		if c is GeometryInstance3D:
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		c.owner = r
	_pack_save(r, "res://scenes/parts/labyrinth_tower.tscn")

func _build_black_iron_palace() -> void:
	var r := Node3D.new()
	r.name = "BlackIronPalace"
	
	var iron_stone_m := _get_toon_material(Color(0.12, 0.11, 0.16), false, 1.8)
	iron_stone_m.set_shader_parameter("roughness", 0.60)
	iron_stone_m.set_shader_parameter("shadow_tint", Color(0.20, 0.16, 0.30))
	iron_stone_m.set_shader_parameter("specular_size", 0.08)
	iron_stone_m.set_shader_parameter("specular_color", Color(0.85, 0.82, 0.98))
	
	var stone_trim_m := _get_toon_material(Color(0.20, 0.19, 0.25), false, 1.6)
	stone_trim_m.set_shader_parameter("roughness", 0.68)
	stone_trim_m.set_shader_parameter("shadow_tint", Color(0.26, 0.22, 0.36))

	var roof_m := _get_toon_material(Color(0.16, 0.17, 0.22), false, 1.8)
	roof_m.set_shader_parameter("roughness", 0.45)

	var gold_finial_m := _mat(Color(0.88, 0.74, 0.30), 0.35, 0.8)
	
	var rose_glow_m := StandardMaterial3D.new()
	rose_glow_m.albedo_color = Color(0.95, 0.82, 0.45)
	rose_glow_m.emission_enabled = true
	rose_glow_m.emission = Color(0.95, 0.82, 0.45)
	rose_glow_m.emission_energy_multiplier = 1.5
	rose_glow_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var lancet_glow_m := StandardMaterial3D.new()
	lancet_glow_m.albedo_color = Color(1.0, 0.88, 0.55)
	lancet_glow_m.emission_enabled = true
	lancet_glow_m.emission = Color(1.0, 0.88, 0.55)
	lancet_glow_m.emission_energy_multiplier = 1.8
	lancet_glow_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var glyph_cyan_m := StandardMaterial3D.new()
	glyph_cyan_m.albedo_color = Color(0.20, 0.88, 0.95)
	glyph_cyan_m.emission_enabled = true
	glyph_cyan_m.emission = Color(0.20, 0.88, 0.95)
	glyph_cyan_m.emission_energy_multiplier = 3.5
	glyph_cyan_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# 1. Raised Fortress Terrace Plinth & Grand Steps
	r.add_child(_mi(_box(Vector3(126, 8, 68), iron_stone_m), Vector3(0, 4, 0)))
	r.add_child(_mi(_box(Vector3(128, 1.6, 70), stone_trim_m), Vector3(0, 8.8, 0)))
	# Crenelations on terrace parapet
	for px in [-60.0, -40.0, -20.0, 20.0, 40.0, 60.0]:
		r.add_child(_mi(_box(Vector3(6.0, 2.2, 1.4), stone_trim_m), Vector3(px, 10.5, 34.5)))
	# Monumental entrance stairs
	r.add_child(_mi(_box(Vector3(26, 4, 18), stone_trim_m), Vector3(0, 2, 40)))

	# 2. Central Palace Keep (Layered Gothic Volumes)
	r.add_child(_mi(_box(Vector3(50, 26, 28), iron_stone_m), Vector3(0, 21, 0)))
	r.add_child(_mi(_box(Vector3(42, 22, 24), iron_stone_m), Vector3(0, 45, 0)))
	
	# Steep Gothic Mansard Roof on Keep
	var keep_roof := PrismMesh.new()
	keep_roof.size = Vector3(44, 22, 26)
	keep_roof.material = roof_m
	r.add_child(_mi(keep_roof, Vector3(0, 67, 0)))

	# Central Needle Spire on Roof Ridge with Gold Finial
	r.add_child(_mi(_cyl(1.2, 1.8, 22.0, roof_m, 8), Vector3(0, 81, 0)))
	r.add_child(_mi(_cyl(0.05, 1.2, 8.0, gold_finial_m, 8), Vector3(0, 93, 0)))

	# 4 Corner Gothic Fluted Buttress Turrets on Keep
	for sx in [-22.0, 22.0]:
		for sz in [-13.0, 13.0]:
			r.add_child(_mi(_cyl(2.2, 2.6, 52.0, iron_stone_m, 8), Vector3(sx, 34, sz)))
			r.add_child(_mi(_cyl(0.05, 2.4, 14.0, roof_m, 8), Vector3(sx, 67, sz)))
			r.add_child(_mi(_sph(0.4, 0.8, gold_finial_m), Vector3(sx, 74.5, sz)))

	# 3. Gothic Rose Window with Stone Tracery and Radial Mullions
	var rose_pos := Vector3(0, 46, 12.2)
	# Outer dark stone relief ring
	r.add_child(_mi(_cyl(6.2, 6.2, 0.8, stone_trim_m, 24), rose_pos, Vector3(PI * 0.5, 0, 0)))
	# Luminous stained-glass backplate
	r.add_child(_mi(_cyl(5.6, 5.6, 0.6, rose_glow_m, 24), rose_pos + Vector3(0, 0, 0.1), Vector3(PI * 0.5, 0, 0)))
	# Inner stone tracery ring
	var inner_tracery := TorusMesh.new()
	inner_tracery.inner_radius = 2.4
	inner_tracery.outer_radius = 2.8
	inner_tracery.material = stone_trim_m
	r.add_child(_mi(inner_tracery, rose_pos + Vector3(0, 0, 0.35), Vector3(PI * 0.5, 0, 0)))
	# 12 Radial mullion spokes
	for mi in 12:
		var ma := float(mi) * PI / 6.0
		r.add_child(_mi(_box(Vector3(0.24, 5.2, 0.5), iron_stone_m), rose_pos + Vector3(0, 0, 0.3), Vector3(0, 0, ma)))
	# Central gold guild medallion
	r.add_child(_mi(_cyl(0.85, 0.85, 0.7, gold_finial_m, 16), rose_pos + Vector3(0, 0, 0.4), Vector3(PI * 0.5, 0, 0)))

	# 4. Gothic Lancet Windows on Facade
	for wx in [-14.0, -8.0, 8.0, 14.0]:
		r.add_child(_mi(_box(Vector3(1.4, 8.0, 0.6), lancet_glow_m), Vector3(wx, 24.0, 14.1)))
		r.add_child(_mi(_cyl(0.05, 0.7, 1.4, lancet_glow_m, 8), Vector3(wx, 28.7, 14.1), Vector3(0, 0, PI * 0.5)))

	# 5. Monument of Life Grand Barbican & Entrance Portal
	r.add_child(_mi(_box(Vector3(22, 16, 12), iron_stone_m), Vector3(0, 16, 18)))
	r.add_child(_mi(_box(Vector3(24, 1.4, 14), stone_trim_m), Vector3(0, 24.5, 18)))
	# Arched entrance gate
	r.add_child(_mi(_box(Vector3(8, 11, 8), _mat(Color(0.06, 0.06, 0.08))), Vector3(0, 13.5, 20.5)))
	# Monument of Life Monolith inside Barbican with glowing inscriptions
	r.add_child(_mi(_box(Vector3(5.2, 7.5, 0.8), iron_stone_m), Vector3(0, 13.0, 18.0)))
	r.add_child(_mi(_box(Vector3(4.4, 0.2, 0.9), glyph_cyan_m), Vector3(0, 15.0, 18.0)))
	r.add_child(_mi(_box(Vector3(4.4, 0.2, 0.9), glyph_cyan_m), Vector3(0, 13.5, 18.0)))
	r.add_child(_mi(_box(Vector3(4.4, 0.2, 0.9), glyph_cyan_m), Vector3(0, 12.0, 18.0)))

	# 6. Colossal Flanking Octagonal Bastion Towers
	for sx in [-38.0, 38.0]:
		# Lower octagonal drum
		r.add_child(_mi(_cyl(7.5, 8.5, 36.0, iron_stone_m, 8), Vector3(sx, 24, 4)))
		# Mid decorative belt
		r.add_child(_mi(_cyl(8.6, 8.6, 1.4, stone_trim_m, 8), Vector3(sx, 42.5, 4)))
		# Upper octagonal drum
		r.add_child(_mi(_cyl(6.2, 7.2, 32.0, iron_stone_m, 8), Vector3(sx, 58, 4)))
		# Flared machicolated crown
		r.add_child(_mi(_cyl(7.6, 6.2, 3.2, stone_trim_m, 8), Vector3(sx, 74.5, 4)))
		# High octagonal gothic spire roof
		r.add_child(_mi(_cyl(0.05, 7.2, 18.0, roof_m, 8), Vector3(sx, 84.5, 4)))
		r.add_child(_mi(_sph(0.5, 1.0, gold_finial_m), Vector3(sx, 94.0, 4)))

	# 7. Connecting Fortress Curtain Wings with Parapets
	for sx in [-62.0, 62.0]:
		r.add_child(_mi(_box(Vector3(34, 22, 6), iron_stone_m), Vector3(sx, 17, 0)))
		r.add_child(_mi(_box(Vector3(34, 1.6, 7), stone_trim_m), Vector3(sx, 28.8, 0)))
		for cx in [-12.0, 0.0, 12.0]:
			r.add_child(_mi(_box(Vector3(2.5, 1.6, 1.2), stone_trim_m), Vector3(sx + cx, 30.2, 3.0)))

	for c in r.get_children():
		c.owner = r
	_pack_save(r, "res://scenes/parts/black_iron_palace.tscn")

func _build_windmill_ridge() -> void:
	var r := Node3D.new()
	r.name = "WindmillRidge"
	
	var knoll_m := _get_toon_material(Color(0.28, 0.50, 0.26), false, 0.0)
	knoll_m.set_shader_parameter("roughness", 0.95)
	knoll_m.set_shader_parameter("shadow_tint", Color(0.20, 0.38, 0.22))
	
	var stone_m := _get_toon_material(Color(0.76, 0.74, 0.70), false, 1.8)
	stone_m.set_shader_parameter("roughness", 0.85)

	# 1. Sculpted Rolling Grassy Ridge & Knolls on the West Foothills
	# Central ridge spine
	r.add_child(_mi(_cyl(55.0, 75.0, 18.0, knoll_m, 24), Vector3(0, 9.0, 0)))
	# North knoll
	r.add_child(_mi(_cyl(48.0, 68.0, 16.0, knoll_m, 20), Vector3(-15.0, 14.0, -65.0)))
	# South slope knoll
	r.add_child(_mi(_cyl(50.0, 70.0, 15.0, knoll_m, 20), Vector3(-10.0, 11.0, 60.0)))
	# East terrace shoulder
	r.add_child(_mi(_cyl(42.0, 58.0, 14.0, knoll_m, 20), Vector3(25.0, 12.0, -10.0)))
	
	# Low stone terrace retaining walls along ridge edge
	for i in 16:
		var a := TAU * float(i) / 16.0
		var rw_pos := Vector3(cos(a) * 62.0, 5.0, sin(a) * 62.0)
		r.add_child(_mi(_box(Vector3(12.0, 3.0, 1.8), stone_m), rw_pos, Vector3(0, -a + PI * 0.5, 0)))

	# 2. The 4 Tudor Windmills along the Ridge Crest
	var mill_defs := [
		{"pos": Vector3(0.0, 18.0, 0.0), "yaw": 0.50, "speed": 0.45},
		{"pos": Vector3(-12.0, 22.0, -65.0), "yaw": 0.35, "speed": 0.38},
		{"pos": Vector3(-8.0, 18.5, 60.0), "yaw": 0.65, "speed": 0.52},
		{"pos": Vector3(22.0, 19.0, -15.0), "yaw": 0.40, "speed": 0.42}
	]
	
	for md in mill_defs:
		var mill := _create_windmill(md["pos"], md["yaw"], md["speed"])
		r.add_child(mill)
		
	for c in r.get_children():
		c.owner = r
		_set_owner_recursive(c, r)
	_pack_save(r, "res://scenes/parts/windmill_ridge.tscn")

func _create_windmill(pos: Vector3, yaw: float, rotor_speed: float) -> Node3D:
	var mill := Node3D.new()
	mill.position = pos
	mill.rotation = Vector3(0, yaw, 0)
	
	var stone_m := _get_toon_material(Color(0.82, 0.80, 0.76), false, 1.8)
	var plaster_m := _get_toon_material(Color(0.95, 0.93, 0.89), false, 1.8)
	var timber_m := _mat(Color(0.32, 0.20, 0.12))
	var roof_m := _mat(Color(0.24, 0.28, 0.35), 0.6) # Dark slate roof
	var sail_m := _get_toon_material(Color(0.95, 0.94, 0.90), false, 0.0)
	var hay_m := _mat(Color(0.80, 0.66, 0.32))
	var warm_lamp_m := StandardMaterial3D.new()
	warm_lamp_m.albedo_color = Color(1.0, 0.85, 0.50)
	warm_lamp_m.emission_enabled = true
	warm_lamp_m.emission = Color(1.0, 0.85, 0.50)
	warm_lamp_m.emission_energy_multiplier = 3.5
	warm_lamp_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Masonry stone plinth base with doorway
	mill.add_child(_mi(_cyl(4.2, 5.2, 5.0, stone_m, 12), Vector3(0, 2.5, 0)))
	mill.add_child(_mi(_box(Vector3(1.4, 2.4, 1.0), timber_m), Vector3(0, 2.0, 4.8)))

	# Octagonal half-timbered body
	mill.add_child(_mi(_cyl(3.4, 4.0, 11.0, plaster_m, 8), Vector3(0, 10.5, 0)))
	# 8 Timber corner posts
	for i in 8:
		var a := TAU * float(i) / 8.0
		var post_pos := Vector3(cos(a) * 3.7, 10.5, sin(a) * 3.7)
		mill.add_child(_mi(_box(Vector3(0.25, 11.0, 0.25), timber_m), post_pos, Vector3(0, -a, 0)))

	# Wooden viewing gallery / balcony
	mill.add_child(_mi(_cyl(4.4, 4.4, 0.5, timber_m, 12), Vector3(0, 15.5, 0)))
	for i in 8:
		var a := TAU * float(i) / 8.0
		var r_pos := Vector3(cos(a) * 4.3, 16.3, sin(a) * 4.3)
		mill.add_child(_mi(_cyl(0.06, 0.06, 1.2, timber_m, 6), r_pos))

	# Revolving conical slate roof cap
	mill.add_child(_mi(_cyl(0.05, 4.5, 5.2, roof_m, 12), Vector3(0, 18.6, 0)))
	# Weather-vane spire
	mill.add_child(_mi(_cyl(0.06, 0.08, 2.2, timber_m, 6), Vector3(0, 22.0, 0)))

	# Forward axle shaft
	mill.add_child(_mi(_cyl(0.35, 0.45, 3.2, timber_m, 8), Vector3(0, 16.5, 2.4), Vector3(PI * 0.5, 0, 0)))

	# Rotating Rotor Node with sails
	var rotor := Node3D.new()
	rotor.name = "Rotor"
	rotor.position = Vector3(0, 16.5, 4.1)
	rotor.set_script(load("res://tools/windmill_rotor.gd"))
	rotor.set("rotation_speed", rotor_speed)
	
	# Central wooden axle hub
	rotor.add_child(_mi(_cyl(0.85, 0.85, 0.6, timber_m, 8), Vector3(0, 0, 0), Vector3(PI * 0.5, 0, 0)))
	
	# 4 Timber spars & sail canvas
	for i in 4:
		var sa := float(i) * TAU / 4.0
		var spar_pos := Vector3(cos(sa) * 6.5, sin(sa) * 6.5, 0.1)
		var spar := _mi(_box(Vector3(0.24, 13.0, 0.24), timber_m), spar_pos, Vector3(0, 0, sa))
		rotor.add_child(spar)
		
		# White sail cloth offset on spar
		var sail_pos := Vector3(cos(sa) * 7.0 - sin(sa) * 1.2, sin(sa) * 7.0 + cos(sa) * 1.2, 0.2)
		var sail := _mi(_box(Vector3(2.0, 9.5, 0.06), sail_m), sail_pos, Vector3(0, 0, sa))
		rotor.add_child(sail)
	
	mill.add_child(rotor)

	# Doorway lantern
	mill.add_child(_mi(_box(Vector3(0.35, 0.45, 0.35), warm_lamp_m), Vector3(1.2, 3.4, 4.6)))

	# Haystacks props near windmill
	mill.add_child(_mi(_sph(2.2, 2.4, hay_m), Vector3(7.5, 0.8, 3.5)))
	mill.add_child(_mi(_sph(1.6, 1.8, hay_m), Vector3(9.5, 0.6, 1.8)))

	return mill

func _build_teleport_plaza() -> void:
	var r := Node3D.new()
	r.name = "TeleportPlaza"
	
	var marble_m := _get_toon_material(Color(0.96, 0.95, 0.93), false, 1.8)
	var gold_m := _mat(Color(0.88, 0.72, 0.28), 0.35, 0.8)
	var iron_m := _mat(Color(0.18, 0.18, 0.22), 0.5)
	var lamp_glow_m := StandardMaterial3D.new()
	lamp_glow_m.albedo_color = Color(1.0, 0.88, 0.55)
	lamp_glow_m.emission_enabled = true
	lamp_glow_m.emission = Color(1.0, 0.88, 0.55)
	lamp_glow_m.emission_energy_multiplier = 3.5
	lamp_glow_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var crystal_m := StandardMaterial3D.new()
	crystal_m.albedo_color = Color(0.18, 0.92, 1.0)
	crystal_m.emission_enabled = true
	crystal_m.emission = Color(0.18, 0.92, 1.0)
	crystal_m.emission_energy_multiplier = 5.2
	crystal_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var crystal_shard_m := StandardMaterial3D.new()
	crystal_shard_m.albedo_color = Color(0.40, 0.96, 1.0)
	crystal_shard_m.emission_enabled = true
	crystal_shard_m.emission = Color(0.40, 0.96, 1.0)
	crystal_shard_m.emission_energy_multiplier = 4.2
	crystal_shard_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var banner_blue_m := _mat(Color(0.15, 0.35, 0.78))
	var banner_red_m := _mat(Color(0.78, 0.18, 0.22))

	# === 1. The Central Teleport Gate Monument ===
	var gate_origin := Vector3(0, 0, 28)
	
	# Raised 3-tiered concentric marble dais
	r.add_child(_mi(_cyl(8.5, 8.8, 0.3, marble_m, 32), gate_origin + Vector3(0, 0.15, 0)))
	r.add_child(_mi(_cyl(6.8, 7.0, 0.3, gold_m, 28), gate_origin + Vector3(0, 0.45, 0)))
	r.add_child(_mi(_cyl(5.2, 5.4, 0.3, marble_m, 24), gate_origin + Vector3(0, 0.75, 0)))

	# Twin Classical Marble Columns
	for sx in [-4.8, 4.8]:
		r.add_child(_mi(_box(Vector3(2.4, 1.4, 2.4), marble_m), gate_origin + Vector3(sx, 1.6, 0)))
		r.add_child(_mi(_cyl(0.95, 1.05, 12.0, marble_m, 16), gate_origin + Vector3(sx, 8.3, 0)))
		r.add_child(_mi(_box(Vector3(2.6, 1.2, 2.6), gold_m), gate_origin + Vector3(sx, 14.8, 0)))

	# Archway Lintel & Pediment
	r.add_child(_mi(_box(Vector3(13.6, 2.6, 2.8), marble_m), gate_origin + Vector3(0, 16.5, 0)))
	var arch_vault := TorusMesh.new()
	arch_vault.inner_radius = 3.6
	arch_vault.outer_radius = 4.8
	arch_vault.material = marble_m
	r.add_child(_mi(arch_vault, gate_origin + Vector3(0, 13.8, 0), Vector3(PI * 0.5, 0, 0)))
	# Gold SAO Guild Emblem Medallion
	r.add_child(_mi(_cyl(1.3, 1.3, 0.5, gold_m, 16), gate_origin + Vector3(0, 16.6, 1.5), Vector3(PI * 0.5, 0, 0)))

	# Enlarged Floating Teleport Crystal with Orbiting Shards
	var crystal := Node3D.new()
	crystal.name = "TeleportCrystal"
	crystal.position = gate_origin + Vector3(0, 7.5, 0)
	crystal.set_script(load("res://tools/crystal_float.gd"))
	crystal.set("rotation_speed", 0.9)
	crystal.set("bob_amplitude", 0.35)
	
	# Central Octahedral Crystal (4.8m tall)
	var top_pyr := PrismMesh.new()
	top_pyr.size = Vector3(3.0, 3.8, 3.0)
	top_pyr.material = crystal_m
	crystal.add_child(_mi(top_pyr, Vector3(0, 1.9, 0)))
	var bot_pyr := PrismMesh.new()
	bot_pyr.size = Vector3(3.0, 3.8, 3.0)
	bot_pyr.material = crystal_m
	crystal.add_child(_mi(bot_pyr, Vector3(0, -1.9, 0), Vector3(PI, 0, 0)))
	
	# Inner glowing nucleus
	crystal.add_child(_mi(_sph(0.9, 0.9, crystal_m), Vector3.ZERO))

	# 4 Orbiting Satellite Crystal Shards
	for si in 4:
		var sa := float(si) * TAU / 4.0
		var shard_p := Vector3(cos(sa) * 3.6, sin(sa * 2.0) * 0.4, sin(sa) * 3.6)
		var shard_top := PrismMesh.new()
		shard_top.size = Vector3(0.8, 1.2, 0.8)
		shard_top.material = crystal_shard_m
		crystal.add_child(_mi(shard_top, shard_p + Vector3(0, 0.6, 0), Vector3(0, sa, 0)))
		var shard_bot := PrismMesh.new()
		shard_bot.size = Vector3(0.8, 1.2, 0.8)
		shard_bot.material = crystal_shard_m
		crystal.add_child(_mi(shard_bot, shard_p + Vector3(0, -0.6, 0), Vector3(PI, sa, 0)))

	# Omnidirectional cyan glow light
	var crystal_light := OmniLight3D.new()
	crystal_light.light_color = Color(0.25, 0.92, 1.0)
	crystal_light.light_energy = 3.6
	crystal_light.omni_range = 22.0
	crystal_light.shadow_enabled = false
	crystal.add_child(crystal_light)
	r.add_child(crystal)

	# === 2. Symmetrical Twin Marble Fountains flanking Central Plaza ===
	for fx in [-17.0, 17.0]:
		var f_origin := gate_origin + Vector3(fx, 0, 0)
		# Lower basin
		r.add_child(_mi(_cyl(4.6, 4.8, 0.6, marble_m, 24), f_origin + Vector3(0, 0.3, 0)))
		var f_water_1 := PlaneMesh.new()
		f_water_1.size = Vector2(8.8, 8.8)
		f_water_1.material = _get_water_material()
		r.add_child(_mi(f_water_1, f_origin + Vector3(0, 0.55, 0)))
		# Middle tier
		r.add_child(_mi(_cyl(0.9, 1.1, 1.3, marble_m, 12), f_origin + Vector3(0, 1.25, 0)))
		r.add_child(_mi(_cyl(2.6, 2.8, 0.4, marble_m, 18), f_origin + Vector3(0, 2.1, 0)))
		var f_water_2 := PlaneMesh.new()
		f_water_2.size = Vector2(5.0, 5.0)
		f_water_2.material = _get_water_material()
		r.add_child(_mi(f_water_2, f_origin + Vector3(0, 2.25, 0)))
		# Top tier nozzle
		r.add_child(_mi(_cyl(0.5, 0.6, 1.0, marble_m, 10), f_origin + Vector3(0, 2.8, 0)))
		r.add_child(_mi(_cyl(1.3, 1.4, 0.3, marble_m, 14), f_origin + Vector3(0, 3.4, 0)))
		r.add_child(_mi(_cyl(0.08, 0.25, 1.2, gold_m, 8), f_origin + Vector3(0, 4.1, 0)))

	# === 3. Plaza Perimeter Street Lamps & Benches ===
	for i in 12:
		var a := TAU * float(i) / 12.0
		var l_pos := gate_origin + Vector3(cos(a) * 26.0, 0, sin(a) * 26.0)
		r.add_child(_mi(_cyl(0.14, 0.22, 4.4, iron_m, 8), l_pos + Vector3(0, 2.2, 0)))
		r.add_child(_mi(_box(Vector3(0.5, 0.65, 0.5), lamp_glow_m), l_pos + Vector3(0, 4.5, 0)))
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.88, 0.62)
		light.light_energy = 0.9
		light.omni_range = 9.0
		light.shadow_enabled = false
		light.position = l_pos + Vector3(0, 4.5, 0)
		r.add_child(light)

	# Benches along colonnade ring
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var b_pos := gate_origin + Vector3(cos(a) * 28.5, 0.35, sin(a) * 28.5)
		r.add_child(_mi(_box(Vector3(2.6, 0.45, 0.8), marble_m), b_pos, Vector3(0, -a + PI * 0.5, 0)))

	# Heraldic Banners hanging on colonnade pillars
	for i in 24:
		var a := TAU * float(i) / 24.0
		var banner_m: Material = banner_blue_m if (i % 2 == 0) else banner_red_m
		var b_pos := gate_origin + Vector3(cos(a) * 30.0, 4.5, sin(a) * 30.0)
		r.add_child(_mi(_box(Vector3(0.9, 3.2, 0.1), banner_m), b_pos, Vector3(0, -a, 0)))

	for c in r.get_children():
		c.owner = r
	_pack_save(r, "res://scenes/parts/teleport_plaza.tscn")

func _build_market_street() -> void:
	var r := Node3D.new()
	r.name = "MarketStreet"
	
	var wood_m := _mat(Color(0.36, 0.24, 0.16))
	var iron_m := _mat(Color(0.18, 0.18, 0.22), 0.5)
	var crate_m := _mat(Color(0.55, 0.40, 0.25))
	var fruit_red := _mat(Color(0.90, 0.20, 0.20))
	var fruit_green := _mat(Color(0.35, 0.75, 0.25))
	var potion_blue := _mat(Color(0.20, 0.70, 1.0), 0.2)
	var potion_purple := _mat(Color(0.70, 0.20, 0.90), 0.2)
	
	var awnings := [
		_mat(Color(0.85, 0.22, 0.22)), # Crimson
		_mat(Color(0.20, 0.42, 0.85)), # Royal Blue
		_mat(Color(0.25, 0.65, 0.30)), # Emerald
		_mat(Color(0.88, 0.55, 0.18))  # Warm Amber
	]
	
	var lamp_glow_m := StandardMaterial3D.new()
	lamp_glow_m.albedo_color = Color(1.0, 0.88, 0.55)
	lamp_glow_m.emission_enabled = true
	lamp_glow_m.emission = Color(1.0, 0.88, 0.55)
	lamp_glow_m.emission_energy_multiplier = 3.5
	lamp_glow_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# 10 Market Stalls along Avenue (skipping lake park z=62 to 128)
	var stall_z_coords := [38.0, 50.0, 136.0, 148.0, 160.0]
	var stall_idx := 0
	for z_pos in stall_z_coords:
		for x_side in [-8.5, 8.5]:
			var aw_mat: Material = awnings[stall_idx % awnings.size()]
			stall_idx += 1
			var facing_east: bool = x_side < 0.0
			var rot_y: float = 0.0 if facing_east else PI
			
			var stall := Node3D.new()
			stall.position = Vector3(x_side, 0.15, z_pos)
			stall.rotation = Vector3(0, rot_y, 0)
			
			# Timber counter table
			stall.add_child(_mi(_box(Vector3(1.2, 0.95, 3.6), wood_m), Vector3(0, 0.475, 0)))
			
			# 4 Canopy posts
			for cx in [-0.55, 0.55]:
				for cz in [-1.75, 1.75]:
					stall.add_child(_mi(_cyl(0.06, 0.08, 2.6, wood_m, 6), Vector3(cx, 1.3, cz)))
			
			# Slanted Striped Canopy Awning
			var awning_mesh := PrismMesh.new()
			awning_mesh.size = Vector3(2.2, 0.6, 4.0)
			awning_mesh.material = aw_mat
			stall.add_child(_mi(awning_mesh, Vector3(0, 2.7, 0), Vector3(0, PI * 0.5, 0)))
			
			# Goods on counter
			stall.add_child(_mi(_box(Vector3(0.5, 0.3, 0.8), crate_m), Vector3(0, 1.1, -1.0)))
			stall.add_child(_mi(_sph(0.12, 0.12, fruit_red), Vector3(0, 1.32, -1.0)))
			stall.add_child(_mi(_sph(0.12, 0.12, fruit_green), Vector3(0, 1.32, -0.8)))
			
			# Potion vials
			stall.add_child(_mi(_cyl(0.08, 0.12, 0.35, potion_blue, 8), Vector3(0.1, 1.12, 0.6)))
			stall.add_child(_mi(_cyl(0.08, 0.12, 0.35, potion_purple, 8), Vector3(0.1, 1.12, 1.0)))
			
			# Storage barrels next to stall
			stall.add_child(_mi(_cyl(0.42, 0.38, 1.1, wood_m, 10), Vector3(0.8, 0.55, 2.2)))
			stall.add_child(_mi(_cyl(0.38, 0.35, 0.9, wood_m, 10), Vector3(0.9, 0.45, -2.1)))
			
			r.add_child(stall)

	# Avenue Street Lamps
	var z_cur := 35.0
	while z_cur <= 165.0:
		if z_cur < 62.0 or z_cur > 128.0:
			for x_side in [-10.8, 10.8]:
				var l_pos := Vector3(x_side, 0.15, z_cur)
				r.add_child(_mi(_cyl(0.12, 0.18, 4.2, iron_m, 8), l_pos + Vector3(0, 2.1, 0)))
				r.add_child(_mi(_box(Vector3(0.45, 0.6, 0.45), lamp_glow_m), l_pos + Vector3(0, 4.3, 0)))
				var light := OmniLight3D.new()
				light.light_color = Color(1.0, 0.88, 0.62)
				light.light_energy = 0.85
				light.omni_range = 8.5
				light.shadow_enabled = false
				light.position = l_pos + Vector3(0, 4.3, 0)
				r.add_child(light)
		z_cur += 22.0

	for c in r.get_children():
		c.owner = r
		_set_owner_recursive(c, r)
	_pack_save(r, "res://scenes/parts/market_street.tscn")

func _build_floor2_ceiling() -> void:
	var r := Node3D.new()
	r.name = "Floor2Ceiling"
	
	var stone_vault_m := _get_toon_material(Color(0.14, 0.16, 0.22), false, 0.0)
	stone_vault_m.set_shader_parameter("roughness", 0.85)
	stone_vault_m.set_shader_parameter("shadow_tint", Color(0.24, 0.28, 0.38))
	
	var iron_m := _get_toon_material(Color(0.22, 0.24, 0.30), false, 2.0)
	iron_m.set_shader_parameter("roughness", 0.35)
	iron_m.set_shader_parameter("specular_size", 0.08)
	iron_m.set_shader_parameter("specular_color", Color(0.92, 0.96, 1.0))
	iron_m.set_shader_parameter("shadow_tint", Color(0.32, 0.36, 0.46))
	
	var steel_m := _get_toon_material(Color(0.32, 0.35, 0.42), false, 1.8)
	steel_m.set_shader_parameter("roughness", 0.40)
	steel_m.set_shader_parameter("shadow_tint", Color(0.38, 0.42, 0.52))
	
	var glow_m := StandardMaterial3D.new()
	glow_m.albedo_color = Color(0.28, 0.88, 1.0)
	glow_m.emission_enabled = true
	glow_m.emission = Color(0.28, 0.88, 1.0)
	glow_m.emission_energy_multiplier = 4.0
	glow_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var center_origin := Vector3(0, 114, -80)
	
	# Monumental Stepped Stone Canopy Vault
	r.add_child(_mi(_cyl(560.0, 580.0, 16.0, stone_vault_m, 48), center_origin + Vector3(0, 36, 0)))
	r.add_child(_mi(_cyl(410.0, 440.0, 14.0, stone_vault_m, 40), center_origin + Vector3(0, 24, 0)))
	r.add_child(_mi(_cyl(270.0, 300.0, 12.0, stone_vault_m, 32), center_origin + Vector3(0, 14, 0)))
	r.add_child(_mi(_cyl(140.0, 170.0, 10.0, stone_vault_m, 24), center_origin + Vector3(0, 6, 0)))
	r.add_child(_mi(_cyl(55.0, 75.0, 10.0, stone_vault_m, 20), center_origin + Vector3(0, 0, 0)))
	
	# Concentric Structural Iron & Steel Arch Rings
	r.add_child(_mi(_torus(62.0, 70.0, iron_m, 36, 12), center_origin + Vector3(0, -1, 0)))
	r.add_child(_mi(_torus(130.0, 140.0, steel_m, 44, 12), center_origin + Vector3(0, 5, 0)))
	r.add_child(_mi(_torus(215.0, 227.0, iron_m, 52, 12), center_origin + Vector3(0, 12, 0)))
	r.add_child(_mi(_torus(310.0, 324.0, steel_m, 60, 12), center_origin + Vector3(0, 20, 0)))
	r.add_child(_mi(_torus(415.0, 432.0, iron_m, 68, 14), center_origin + Vector3(0, 29, 0)))
	r.add_child(_mi(_torus(525.0, 545.0, iron_m, 76, 16), center_origin + Vector3(0, 38, 0)))

	# 16 Radial Iron Girders
	for i in 16:
		var a := TAU * float(i) / 16.0
		var dir := Vector3(cos(a), 0, sin(a))
		var norm_yaw := -a + PI * 0.5
		
		r.add_child(_mi(_box(Vector3(3.6, 4.2, 115.0), iron_m), center_origin + dir * 78.0 + Vector3(0, 2.0, 0), Vector3(0.04, norm_yaw, 0)))
		r.add_child(_mi(_box(Vector3(4.4, 5.0, 140.0), iron_m), center_origin + dir * 205.0 + Vector3(0, 8.5, 0), Vector3(0.06, norm_yaw, 0)))
		r.add_child(_mi(_box(Vector3(5.2, 5.8, 160.0), iron_m), center_origin + dir * 350.0 + Vector3(0, 17.0, 0), Vector3(0.07, norm_yaw, 0)))
		r.add_child(_mi(_box(Vector3(6.0, 6.6, 140.0), iron_m), center_origin + dir * 500.0 + Vector3(0, 26.5, 0), Vector3(0.08, norm_yaw, 0)))
		
		r.add_child(_mi(_cyl(1.3, 1.7, 7.0, iron_m, 8), center_origin + dir * 135.0 + Vector3(0, 6.0, 0)))
		r.add_child(_mi(_cyl(1.7, 2.1, 9.0, iron_m, 8), center_origin + dir * 221.0 + Vector3(0, 13.0, 0)))
		r.add_child(_mi(_cyl(2.1, 2.5, 11.0, iron_m, 8), center_origin + dir * 317.0 + Vector3(0, 21.0, 0)))
		r.add_child(_mi(_cyl(2.5, 2.9, 13.0, iron_m, 8), center_origin + dir * 423.0 + Vector3(0, 30.0, 0)))

	# Hanging Gothic Citadel Hub & Core
	r.add_child(_mi(_cyl(22.0, 28.0, 12.0, iron_m, 8), center_origin + Vector3(0, -6, 0)))
	r.add_child(_mi(_cyl(14.0, 19.0, 10.0, steel_m, 8), center_origin + Vector3(0, -15, 0)))
	r.add_child(_mi(_cyl(8.0, 12.0, 12.0, iron_m, 12), center_origin + Vector3(0, -24, 0)))
	r.add_child(_mi(_cyl(1.4, 7.0, 18.0, iron_m, 12), center_origin + Vector3(0, -36, 0)))
	r.add_child(_mi(_sph(2.5, 5.0, glow_m), center_origin + Vector3(0, -46, 0)))
	
	for b_i in 8:
		var ba := float(b_i) * TAU / 8.0
		var b_pos := center_origin + Vector3(cos(ba) * 16.0, -14.0, sin(ba) * 16.0)
		r.add_child(_mi(_box(Vector3(1.4, 14.0, 6.0), iron_m), b_pos, Vector3(0, -ba + PI * 0.5, 0)))
		var turret_pos := center_origin + Vector3(cos(ba) * 22.0, -12.0, sin(ba) * 22.0)
		r.add_child(_mi(_cyl(0.8, 1.8, 12.0, iron_m, 8), turret_pos))
		r.add_child(_mi(_sph(0.9, 1.8, glow_m), turret_pos + Vector3(0, -7.0, 0)))

	for c in r.get_children():
		if c is GeometryInstance3D:
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		c.owner = r
	_pack_save(r, "res://scenes/parts/floor2_ceiling.tscn")

func _build_perimeter_landscape() -> void:
	var r := Node3D.new()
	r.name = "PerimeterLandscape"
	
	var grass_m := _get_toon_material(Color(0.26, 0.48, 0.28), false, 0.0)
	grass_m.set_shader_parameter("roughness", 0.95)
	
	var far_mountain_m := _get_toon_material(Color(0.28, 0.40, 0.54), false, 0.0)
	far_mountain_m.set_shader_parameter("roughness", 0.90)
	far_mountain_m.set_shader_parameter("shadow_tint", Color(0.42, 0.54, 0.70))
	
	var near_mountain_m := _get_toon_material(Color(0.24, 0.38, 0.44), false, 0.0)
	near_mountain_m.set_shader_parameter("roughness", 0.88)
	near_mountain_m.set_shader_parameter("shadow_tint", Color(0.34, 0.48, 0.58))
	
	var stone_wall_m := _mat(Color(0.64, 0.62, 0.58), 0.85)
	var roof_m := _mat(Color(0.769, 0.416, 0.227), 0.8)
	
	# Broad circular terrain disc (radius 580m)
	r.add_child(_mi(_cyl(580.0, 580.0, 4.0, grass_m, 48), Vector3(0, -2.1, 28)))
	
	# Tier 1: Outer Colossal Mountain Peaks (faceted anime alpine peaks along radius 480-510m)
	for i in 28:
		var a := TAU * float(i) / 28.0
		# Leave majestic alpine gap around true North to frame Labyrinth Tower
		var d_from_north: float = abs(wrapf(a - PI * 1.5, -PI, PI))
		if d_from_north < 0.28:
			continue
		var dist := 490.0 + sin(float(i) * 3.7) * 22.0
		var h := 130.0 + cos(float(i) * 2.3) * 30.0
		var w := 160.0 + sin(float(i) * 1.5) * 30.0
		var m_pos := Vector3(cos(a) * dist, h * 0.5 - 2.0, 28.0 + sin(a) * dist)
		var peak := _mi(_cyl(0.05, w * 0.5, h, far_mountain_m, 8), m_pos, Vector3(0, -a + PI * 0.5, 0))
		r.add_child(peak)
		# Secondary shoulder ridge
		var sh_pos := Vector3(cos(a + 0.06) * (dist - 18.0), h * 0.35 - 2.0, 28.0 + sin(a + 0.06) * (dist - 18.0))
		r.add_child(_mi(_cyl(0.05, w * 0.35, h * 0.7, near_mountain_m, 8), sh_pos, Vector3(0, -a + PI * 0.5, 0)))
	
	# Tier 2: Mid-range Foothill Ridges
	for i in 24:
		var a := TAU * (float(i) + 0.5) / 24.0
		var d_from_north: float = abs(wrapf(a - PI * 1.5, -PI, PI))
		if d_from_north < 0.25:
			continue
		var dist := 435.0 + sin(float(i) * 2.9) * 15.0
		var h := 68.0 + cos(float(i) * 3.1) * 18.0
		var w := 130.0 + sin(float(i) * 1.8) * 22.0
		var m_pos := Vector3(cos(a) * dist, h * 0.5 - 2.0, 28.0 + sin(a) * dist)
		var ridge := _mi(_cyl(0.05, w * 0.45, h, near_mountain_m, 8), m_pos, Vector3(0, -a + PI * 0.5, 0))
		r.add_child(ridge)
	
	# Outer fortress battlement wall ring (radius 390m)
	for i in 32:
		var a := TAU * float(i) / 32.0
		var w_pos := Vector3(cos(a) * 390.0, 11.0, 28.0 + sin(a) * 390.0)
		var wall_seg := _mi(_box(Vector3(78.0, 22.0, 5.0), stone_wall_m), w_pos, Vector3(0, -a + PI * 0.5, 0))
		r.add_child(wall_seg)
		var t_pos := Vector3(cos(a) * 390.0, 14.0, 28.0 + sin(a) * 390.0)
		r.add_child(_mi(_cyl(4.2, 4.6, 28.0, stone_wall_m, 12), t_pos))
		r.add_child(_mi(_cyl(0.05, 4.8, 5.5, roof_m, 12), t_pos + Vector3(0, 16.5, 0)))

	for c in r.get_children():
		if c is GeometryInstance3D:
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		c.owner = r
	_pack_save(r, "res://scenes/parts/perimeter_landscape.tscn")

func _build_anime_clouds() -> void:
	var r := Node3D.new()
	r.name = "AnimeClouds"
	
	var cloud_m := _get_toon_material(Color(1.0, 1.0, 0.99), false, 0.0)
	cloud_m.set_shader_parameter("shadow_tint", Color(0.80, 0.85, 0.95, 1.0))
	cloud_m.set_shader_parameter("shadow_threshold", 0.35)
	cloud_m.set_shader_parameter("shadow_softness", 0.12)
	cloud_m.set_shader_parameter("half_shadow_threshold", 0.60)
	cloud_m.set_shader_parameter("half_shadow_softness", 0.10)
	cloud_m.set_shader_parameter("half_shadow_intensity", 0.82)
	cloud_m.set_shader_parameter("roughness", 0.95)
	cloud_m.set_shader_parameter("specular_size", 0.0)
	cloud_m.set_shader_parameter("enable_rim", true)
	cloud_m.set_shader_parameter("rim_color", Color(1.0, 0.97, 0.88, 1.0))
	cloud_m.set_shader_parameter("rim_threshold", 0.50)
	cloud_m.set_shader_parameter("rim_softness", 0.10)
	cloud_m.set_shader_parameter("rim_spread", 2.2)
	
	var cloud_defs := [
		{"pos": Vector3(-270, 52, -280), "scale": Vector3(1.6, 1.3, 1.4), "rot": 0.25},
		{"pos": Vector3(-130, 58, -310), "scale": Vector3(1.7, 1.4, 1.4), "rot": -0.2},
		{"pos": Vector3(140, 56, -300), "scale": Vector3(1.7, 1.35, 1.4), "rot": 0.3},
		{"pos": Vector3(275, 50, -270), "scale": Vector3(1.5, 1.25, 1.3), "rot": -0.25},
		{"pos": Vector3(-360, 48, -170), "scale": Vector3(1.5, 1.2, 1.3), "rot": 0.5},
		{"pos": Vector3(365, 48, -160), "scale": Vector3(1.5, 1.2, 1.3), "rot": -0.45},
		{"pos": Vector3(-160, 88, -75), "scale": Vector3(1.3, 1.0, 1.2), "rot": 0.2},
		{"pos": Vector3(170, 90, -85), "scale": Vector3(1.35, 1.05, 1.2), "rot": -0.3},
		{"pos": Vector3(-220, 92, 15), "scale": Vector3(1.2, 0.95, 1.1), "rot": 0.4},
		{"pos": Vector3(230, 90, 5), "scale": Vector3(1.25, 1.0, 1.15), "rot": -0.35},
		# Flanking cloud banks framing Labyrinth Tower without obscuring its central spire
		{"pos": Vector3(-105, 96, -175), "scale": Vector3(1.3, 1.0, 1.2), "rot": 0.15},
		{"pos": Vector3(105, 94, -175), "scale": Vector3(1.3, 1.0, 1.2), "rot": -0.15}
	]
	
	for cd in cloud_defs:
		var cluster := _create_anime_cumulus(cloud_m, cd["pos"], cd["scale"], cd["rot"])
		r.add_child(cluster)
		
	for c in r.get_children():
		c.owner = r
		_set_owner_recursive(c, r)
	_pack_save(r, "res://scenes/parts/anime_clouds.tscn")

func _create_anime_cumulus(mat: Material, center: Vector3, cl_scale: Vector3, rot_y: float) -> Node3D:
	var cluster := Node3D.new()
	cluster.position = center
	cluster.rotation = Vector3(0, rot_y, 0)
	cluster.scale = cl_scale
	
	var puffs := [
		[Vector3(0, 0, 0), 18.0, Vector3(1.3, 0.72, 1.1)],
		[Vector3(-14, -1, 3), 15.0, Vector3(1.1, 0.68, 1.0)],
		[Vector3(15, -1, -2), 16.0, Vector3(1.1, 0.70, 1.0)],
		[Vector3(0, -2, -10), 13.0, Vector3(1.0, 0.65, 1.1)],
		[Vector3(0, -2, 11), 13.0, Vector3(1.0, 0.65, 1.1)],
		[Vector3(0, 8, 0), 17.0, Vector3(1.1, 1.15, 1.1)],
		[Vector3(-11, 7, 2), 13.0, Vector3(1.0, 1.10, 1.0)],
		[Vector3(12, 8, -1), 14.0, Vector3(1.05, 1.12, 1.05)],
		[Vector3(3, 6, 7), 11.0, Vector3(0.95, 1.0, 0.95)],
		[Vector3(-3, 7, -6), 12.0, Vector3(0.95, 1.05, 0.95)]
	]
	
	for p_data in puffs:
		var p_offset: Vector3 = p_data[0]
		var r: float = p_data[1]
		var scl_3d: Vector3 = p_data[2]
		
		var puff_mesh := SphereMesh.new()
		puff_mesh.radius = r
		puff_mesh.height = r * 2.0
		puff_mesh.radial_segments = 14
		puff_mesh.rings = 7
		puff_mesh.material = mat
		var mi := MeshInstance3D.new()
		mi.mesh = puff_mesh
		mi.position = p_offset
		mi.scale = scl_3d
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cluster.add_child(mi)
		
	return cluster

func _build_city_kit_scenes() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/city_kit")
	var toon_building_mat := _get_toon_material(Color(0.94, 0.93, 0.91), true, 2.2)
	var toon_tree_mat := _get_toon_material(Color(0.94, 0.93, 0.91), true, 0.0)
	for k in ["house_s", "house_m", "house_l", "corner", "tower_small", "tree_oak", "tree_small"]:
		var is_tree: bool = (k as String).begins_with("tree")
		var mat: ShaderMaterial = toon_tree_mat if is_tree else toon_building_mat
		var m: Mesh = _mesh_of("res://assets/kit/%s.glb" % k)
		if m != null:
			m.surface_set_material(0, mat)
			var r := Node3D.new()
			r.name = k
			var mi := MeshInstance3D.new()
			mi.name = "Mesh"
			mi.mesh = m
			mi.material_override = mat
			r.add_child(mi)
			mi.owner = r
			_pack_save(r, "res://assets/city_kit/%s.tscn" % k)

func _build_main() -> void:
	var root := Node3D.new()
	root.name = "StartingCity"
	
	# Sky & Environment
	var sky := Sky.new()
	sky.sky_material = _get_sky_material()
	
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.64, 0.74, 0.88)
	env.ambient_light_sky_contribution = 0.75
	env.ambient_light_energy = 0.65
	
	# Tonemapping (Filmic Anime curve)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.tonemap_white = 1.16
	
	# Bloom & Glow (Softlight Anime radiance)
	env.glow_enabled = true
	env.glow_intensity = 0.50
	env.glow_strength = 0.95
	env.glow_bloom = 0.22
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	
	# SSAO (Deep comic ink shading in crevices & eaves)
	env.ssao_enabled = true
	env.ssao_radius = 1.3
	env.ssao_intensity = 1.9
	env.ssao_power = 1.5
	env.ssao_detail = 0.50
	env.ssao_horizon = 0.06
	
	# Aerial Perspective Atmospheric Fog
	env.fog_enabled = true
	env.fog_light_color = Color(0.78, 0.88, 0.98)
	env.fog_light_energy = 1.05
	env.fog_sun_scatter = 0.15
	env.fog_density = 0.0010
	env.fog_aerial_perspective = 0.86
	env.fog_sky_affect = 0.20
	env.fog_height = 0.0
	env.fog_height_density = 0.0
	
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	root.add_child(we)
	
	# Directional Sun (Warm golden anime light)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.basis = Basis.from_euler(Vector3(deg_to_rad(-46.0), deg_to_rad(138.0), 0.0))
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 1.20
	sun.light_indirect_energy = 0.90
	sun.shadow_enabled = true
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.8
	sun.shadow_blur = 1.5
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_split_1 = 0.08
	sun.directional_shadow_split_2 = 0.22
	sun.directional_shadow_split_3 = 0.50
	sun.directional_shadow_max_distance = 360.0
	sun.directional_shadow_blend_splits = true
	root.add_child(sun)
	
	# Dual-mode Cinematic & Free-Fly Camera
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.position = Vector3(0, 55, 230)
	cam.rotation = Vector3(-0.240, 0, 0)
	cam.fov = 50.0
	cam.current = true
	cam.set_script(load("res://tools/camera_controller.gd"))
	root.add_child(cam)
	
	# Inner City Ground Pavement (semi-circular cobblestone inside city walls)
	var inner_ground := StaticBody3D.new()
	inner_ground.name = "InnerCityGround"
	root.add_child(inner_ground)
	var inner_pm := CylinderMesh.new()
	inner_pm.top_radius = 192.0
	inner_pm.bottom_radius = 192.0
	inner_pm.height = 0.2
	inner_pm.radial_segments = 48
	inner_pm.material = _get_cobblestone_material(Color(0.82, 0.80, 0.76), 0.32)
	var ig_mi := MeshInstance3D.new()
	ig_mi.name = "Mesh"
	ig_mi.mesh = inner_pm
	ig_mi.position = Vector3(0, -0.05, 15.0)
	inner_ground.add_child(ig_mi)

	# 1. Main Boulevard (24m wide stone cobblestone avenue running from Gate Z=180 to Palace Z=-115)
	var blvd_m := _get_cobblestone_material(Color(0.88, 0.86, 0.82), 0.35)
	var blvd := _mi(_box(Vector3(24.0, 0.15, 300.0), blvd_m), Vector3(0, 0.05, 32.5))
	blvd.name = "MainBoulevard"
	root.add_child(blvd)

	# 2. Grand City Wall with Moat & Arched Stone Bridge (Semi-circular)
	var wall: Node3D = (load("res://scenes/parts/city_wall.tscn") as PackedScene).instantiate()
	wall.position = Vector3(0, 0, 0)
	root.add_child(wall)

	# 3. Rectangular Water Park (60m x 30m) at Z=95 along Boulevard
	var lake: Node3D = (load("res://scenes/parts/lake_park.tscn") as PackedScene).instantiate()
	lake.position = Vector3(0, 0, 95)
	root.add_child(lake)

	# 4. Circular Teleport Plaza (80m diameter) at Z=15
	var teleport_plaza: Node3D = (load("res://scenes/parts/teleport_plaza.tscn") as PackedScene).instantiate()
	teleport_plaza.position = Vector3(0, 0, 15)
	root.add_child(teleport_plaza)

	# 5. Black Iron Palace (Monumental Gothic palace terminating boulevard at Z=-115)
	var palace: Node3D = (load("res://scenes/parts/black_iron_palace.tscn") as PackedScene).instantiate()
	palace.position = Vector3(0, 0, -115)
	root.add_child(palace)

	# 6. Perimeter Landscape (Lush green fields #609B36, dirt roads, alpine rims)
	var landscape: Node3D = (load("res://scenes/parts/perimeter_landscape.tscn") as PackedScene).instantiate()
	landscape.position = Vector3(0, 0, 0)
	root.add_child(landscape)

	# 7. Floor 2 Vault Ceiling Canopy (Y=280m)
	var ceiling: Node3D = (load("res://scenes/parts/floor2_ceiling.tscn") as PackedScene).instantiate()
	ceiling.position = Vector3(0, 0, 0)
	root.add_child(ceiling)

	# 8. Windmill Ridge on West Foothills
	var windmills: Node3D = (load("res://scenes/parts/windmill_ridge.tscn") as PackedScene).instantiate()
	windmills.position = Vector3(-195, 2, -20)
	windmills.rotation = Vector3(0, 0.25, 0)
	root.add_child(windmills)

	# 9. Church placed on lateral residential block
	var church: Node3D = (load("res://scenes/parts/church.tscn") as PackedScene).instantiate()
	church.position = Vector3(90, 0, 45)
	church.rotation = Vector3(0, -0.4, 0)
	root.add_child(church)

	# MultiMeshInstance3D per kit item
	var toon_building_mat := _get_toon_material(Color(0.94, 0.93, 0.91), true, 2.2)
	toon_building_mat.set_shader_parameter("use_architectural_colors", true)
	toon_building_mat.set_shader_parameter("wall_color", Color(0.886, 0.867, 0.835))
	toon_building_mat.set_shader_parameter("roof_color_top", Color(0.722, 0.290, 0.161))
	toon_building_mat.set_shader_parameter("roof_color_edge", Color(0.580, 0.220, 0.120))
	toon_building_mat.set_shader_parameter("roof_slate_color", Color(0.35, 0.42, 0.50))
	
	var toon_tree_mat := _get_toon_material(Color(0.94, 0.93, 0.91), true, 0.0)

	for k in ["house_s", "house_m", "house_l", "corner", "tower_small", "tree_oak", "tree_small"]:
		var is_tree: bool = (k as String).begins_with("tree")
		var mat: ShaderMaterial = toon_tree_mat if is_tree else toon_building_mat
		var m: Mesh = _mesh_of("res://assets/kit/%s.glb" % k)
		m.surface_set_material(0, mat)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = m
		mm.instance_count = 0
		var mmi := MultiMeshInstance3D.new()
		mmi.name = k
		mmi.multimesh = mm
		mmi.material_override = mat
		root.add_child(mmi)

	root.set_script(load("res://tools/city_populate.gd"))
	var baked_count: int = root.populate_city()
	print("PREBAKED_RADIAL_INSTANCES: ", baked_count)

	for c in root.get_children():
		c.owner = root

	_pack_save(root, "res://scenes/sao_starting_city.tscn")
	root.free()

func _add_road(root: Node, mat: Material, pos: Vector3, yaw: float) -> void:
	var r := _mi(_box(Vector3(8, 0.12, 500), mat), pos, Vector3(0, yaw, 0))
	r.name = "Road"
	root.add_child(r)

func _set_owner_recursive(n: Node, o: Node) -> void:
	for c in n.get_children():
		c.owner = o
		_set_owner_recursive(c, o)
