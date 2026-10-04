extends SceneTree
## SAO Starting City kit builder. Saves part scenes + res://scenes/sao_starting_city.tscn
## Loop 3: Aincrad Sky, Floor 2 Ceiling, Perimeter Mountains, Anime Clouds & Post-Processing Pipeline
## Implements Floor 2 underbelly iron/stone canopy, stratified anime cloud bands,
## atmospheric aerial fog, SSAO comic ink crevice shadowing, and filmic softlight bloom.

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
	toon_mat.set_shader_parameter("shadow_tint", Color(0.549, 0.600, 0.722, 1.0)) # #8C99B8
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
	var dark_m := _mat(Color(0.16, 0.17, 0.20), 0.6)
	r.add_child(_mi(_box(Vector3(26, 10, 16), wall_m), Vector3(0, 5, 0)))
	r.add_child(_mi(_sph(9.0, 9.0, dome_m, true), Vector3(0, 10, 0)))
	for sx in [-9.0, 9.0]:
		for sz in [-5.0, 5.0]:
			r.add_child(_mi(_cyl(1.6, 1.8, 12.0, wall_m), Vector3(sx, 6, sz)))
			r.add_child(_mi(_cyl(0.05, 1.7, 3.4, dome_m), Vector3(sx, 13.7, sz)))
	r.add_child(_mi(_cyl(1.1, 1.4, 70.0, wall_m), Vector3(0, 35, -12)))
	r.add_child(_mi(_cyl(0.05, 1.3, 5.0, dome_m), Vector3(0, 72.5, -12)))
	r.add_child(_mi(_box(Vector3(6, 7, 0.6), dark_m), Vector3(0, 3.5, 8.1)))
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
	
	# Surrounding grassy park banks (hollow basin inside 70x42m)
	r.add_child(_mi(_box(Vector3(82, 0.35, 7), grass_m), Vector3(0, 0.16, 24.5)))
	r.add_child(_mi(_box(Vector3(82, 0.35, 7), grass_m), Vector3(0, 0.16, -24.5)))
	r.add_child(_mi(_box(Vector3(6, 0.35, 42), grass_m), Vector3(38, 0.16, 0)))
	r.add_child(_mi(_box(Vector3(6, 0.35, 42), grass_m), Vector3(-38, 0.16, 0)))

	# Stone quay / embankment border lining the lake inner edge
	r.add_child(_mi(_box(Vector3(72, 0.45, 1.4), stone_m), Vector3(0, 0.18, 21.0)))
	r.add_child(_mi(_box(Vector3(72, 0.45, 1.4), stone_m), Vector3(0, 0.18, -21.0)))
	r.add_child(_mi(_box(Vector3(1.4, 0.45, 42), stone_m), Vector3(35.0, 0.18, 0)))
	r.add_child(_mi(_box(Vector3(1.4, 0.45, 42), stone_m), Vector3(-35.0, 0.18, 0)))

	# Sunken lakebed bottom under water (deep enough for water gradient!)
	r.add_child(_mi(_box(Vector3(70, 0.60, 42), lakebed_m), Vector3(0, -1.2, 0)))
	
	# Water surface (PlaneMesh with fine subdivision for smooth wave undulation)
	var water_pm := PlaneMesh.new()
	water_pm.size = Vector2(70, 42)
	water_pm.subdivide_width = 70
	water_pm.subdivide_depth = 42
	water_pm.material = _get_water_material()
	var water_mi := _mi(water_pm, Vector3(0, 0.12, 0))
	water_mi.name = "WaterSurface"
	r.add_child(water_mi)

	# Pavilion stone base & pillars & roof on west side
	r.add_child(_mi(_box(Vector3(14, 0.8, 10), stone_m), Vector3(-14, 0.15, 0)))
	for cx in [-17.0, -11.0]:
		for cz in [-3.5, 3.5]:
			r.add_child(_mi(_cyl(0.25, 0.28, 2.8, cream_m, 8), Vector3(cx, 1.8, cz)))
	t_roof(r, Vector3(8.0, 1.8, 9.0), Vector3(-14, 4.0, 0))
	# Arched footbridge connecting west bank to pavilion
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
	var stone := _mat(Color(0.66, 0.63, 0.57))
	r.add_child(_mi(_box(Vector3(420, 20, 4), stone), Vector3(0, 10, 0)))
	r.add_child(_mi(_box(Vector3(420, 1.6, 4.8), stone), Vector3(0, 20.8, 0)))
	for sx in [-28.0, 28.0]:
		r.add_child(_mi(_cyl(4.5, 4.8, 24.0, stone, 16), Vector3(sx, 12, 0)))
		r.add_child(_mi(_cyl(0.05, 5.0, 5.0, _mat(Color(0.769, 0.416, 0.227), 0.8), 16), Vector3(sx, 26.5, 0)))
	r.add_child(_mi(_box(Vector3(10, 9, 0.8), _mat(Color(0.16, 0.17, 0.2), 0.7)), Vector3(0, 4.5, 2.1)))
	for c in r.get_children():
		c.owner = r
	_pack_save(r, "res://scenes/parts/city_wall.tscn")

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
	
	# Emissive anime crystal core with HDR bloom radiance
	var glow_m := StandardMaterial3D.new()
	glow_m.albedo_color = Color(0.28, 0.88, 1.0)
	glow_m.emission_enabled = true
	glow_m.emission = Color(0.28, 0.88, 1.0)
	glow_m.emission_energy_multiplier = 4.0
	glow_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Framed at (0, 114, -80) to majestically crown the sky within the spec camera frustum
	var center_origin := Vector3(0, 114, -80)
	
	# 1. Monumental Stepped Stone Canopy Vault (Vòm trần đá Aincrad Floor 2)
	r.add_child(_mi(_cyl(560.0, 580.0, 16.0, stone_vault_m, 48), center_origin + Vector3(0, 36, 0)))
	r.add_child(_mi(_cyl(410.0, 440.0, 14.0, stone_vault_m, 40), center_origin + Vector3(0, 24, 0)))
	r.add_child(_mi(_cyl(270.0, 300.0, 12.0, stone_vault_m, 32), center_origin + Vector3(0, 14, 0)))
	r.add_child(_mi(_cyl(140.0, 170.0, 10.0, stone_vault_m, 24), center_origin + Vector3(0, 6, 0)))
	r.add_child(_mi(_cyl(55.0, 75.0, 10.0, stone_vault_m, 20), center_origin + Vector3(0, 0, 0)))
	
	# 2. Concentric Structural Iron & Steel Arch Rings (Nan sắt vành đai)
	r.add_child(_mi(_torus(62.0, 70.0, iron_m, 36, 12), center_origin + Vector3(0, -1, 0)))
	r.add_child(_mi(_torus(130.0, 140.0, steel_m, 44, 12), center_origin + Vector3(0, 5, 0)))
	r.add_child(_mi(_torus(215.0, 227.0, iron_m, 52, 12), center_origin + Vector3(0, 12, 0)))
	r.add_child(_mi(_torus(310.0, 324.0, steel_m, 60, 12), center_origin + Vector3(0, 20, 0)))
	r.add_child(_mi(_torus(415.0, 432.0, iron_m, 68, 14), center_origin + Vector3(0, 29, 0)))
	r.add_child(_mi(_torus(525.0, 545.0, iron_m, 76, 16), center_origin + Vector3(0, 38, 0)))

	# 3. 16 Radial Iron Girders / Arch Ribs (Nan dầm giàn chịu lực tỏa tia)
	for i in 16:
		var a := TAU * float(i) / 16.0
		var dir := Vector3(cos(a), 0, sin(a))
		var norm_yaw := -a + PI * 0.5
		
		# Inner beam segment (r=20 to 135)
		var p1 := center_origin + dir * 78.0 + Vector3(0, 2.0, 0)
		r.add_child(_mi(_box(Vector3(3.6, 4.2, 115.0), iron_m), p1, Vector3(0.04, norm_yaw, 0)))
		
		# Mid beam segment (r=135 to 275)
		var p2 := center_origin + dir * 205.0 + Vector3(0, 8.5, 0)
		r.add_child(_mi(_box(Vector3(4.4, 5.0, 140.0), iron_m), p2, Vector3(0.06, norm_yaw, 0)))
		
		# Outer beam segment (r=275 to 430)
		var p3 := center_origin + dir * 350.0 + Vector3(0, 17.0, 0)
		r.add_child(_mi(_box(Vector3(5.2, 5.8, 160.0), iron_m), p3, Vector3(0.07, norm_yaw, 0)))
		
		# Far beam segment (r=430 to 570)
		var p4 := center_origin + dir * 500.0 + Vector3(0, 26.5, 0)
		r.add_child(_mi(_box(Vector3(6.0, 6.6, 140.0), iron_m), p4, Vector3(0.08, norm_yaw, 0)))
		
		# Vertical hanging brackets / truss connections
		r.add_child(_mi(_cyl(1.3, 1.7, 7.0, iron_m, 8), center_origin + dir * 135.0 + Vector3(0, 6.0, 0)))
		r.add_child(_mi(_cyl(1.7, 2.1, 9.0, iron_m, 8), center_origin + dir * 221.0 + Vector3(0, 13.0, 0)))
		r.add_child(_mi(_cyl(2.1, 2.5, 11.0, iron_m, 8), center_origin + dir * 317.0 + Vector3(0, 21.0, 0)))
		r.add_child(_mi(_cyl(2.5, 2.9, 13.0, iron_m, 8), center_origin + dir * 423.0 + Vector3(0, 30.0, 0)))

	# 4. Hanging Gothic Citadel Hub & Core (Lõi pháo đài Gothic treo trung tâm)
	r.add_child(_mi(_cyl(22.0, 28.0, 12.0, iron_m, 8), center_origin + Vector3(0, -6, 0)))
	r.add_child(_mi(_cyl(14.0, 19.0, 10.0, steel_m, 8), center_origin + Vector3(0, -15, 0)))
	
	# Central hanging Gothic spire
	r.add_child(_mi(_cyl(8.0, 12.0, 12.0, iron_m, 12), center_origin + Vector3(0, -24, 0)))
	r.add_child(_mi(_cyl(1.4, 7.0, 18.0, iron_m, 12), center_origin + Vector3(0, -36, 0)))
	r.add_child(_mi(_sph(2.5, 5.0, glow_m), center_origin + Vector3(0, -46, 0)))
	
	# 8 Gothic flying buttresses & stalactite turrets
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
	
	# Tier 1: Outer Colossal Mountain Peaks (32 overlapping peaks along radius 480-510m)
	for i in 32:
		var a := TAU * float(i) / 32.0
		var dist := 490.0 + sin(float(i) * 3.7) * 25.0
		var h := 125.0 + cos(float(i) * 2.3) * 30.0
		var w := 190.0 + sin(float(i) * 1.5) * 35.0
		var m_pos := Vector3(cos(a) * dist, h * 0.5 - 2.0, 28.0 + sin(a) * dist)
		var peak := _mi(_prism(Vector3(w, h, w * 0.85), far_mountain_m), m_pos, Vector3(0, -a + PI * 0.5, 0))
		r.add_child(peak)
	
	# Tier 2: Mid-range Foothill Ridges (28 overlapping ridges along radius 425-445m)
	for i in 28:
		var a := TAU * (float(i) + 0.5) / 28.0
		var dist := 435.0 + sin(float(i) * 2.9) * 15.0
		var h := 68.0 + cos(float(i) * 3.1) * 18.0
		var w := 140.0 + sin(float(i) * 1.8) * 25.0
		var m_pos := Vector3(cos(a) * dist, h * 0.5 - 2.0, 28.0 + sin(a) * dist)
		var ridge := _mi(_prism(Vector3(w, h, w * 0.75), near_mountain_m), m_pos, Vector3(0, -a + PI * 0.5, 0))
		r.add_child(ridge)
	
	# Outer fortress battlement wall ring (radius 390m)
	for i in 32:
		var a := TAU * float(i) / 32.0
		var w_pos := Vector3(cos(a) * 390.0, 11.0, 28.0 + sin(a) * 390.0)
		var wall_seg := _mi(_box(Vector3(78.0, 22.0, 5.0), stone_wall_m), w_pos, Vector3(0, -a + PI * 0.5, 0))
		r.add_child(wall_seg)
		# Watchtower at wall vertices
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
		# Horizon atmospheric billowing cumulus banks floating above mountain ridges:
		{"pos": Vector3(-270, 52, -280), "scale": Vector3(1.6, 1.3, 1.4), "rot": 0.25},
		{"pos": Vector3(-130, 58, -310), "scale": Vector3(1.7, 1.4, 1.4), "rot": -0.2},
		{"pos": Vector3(140, 56, -300), "scale": Vector3(1.7, 1.35, 1.4), "rot": 0.3},
		{"pos": Vector3(275, 50, -270), "scale": Vector3(1.5, 1.25, 1.3), "rot": -0.25},
		{"pos": Vector3(-360, 48, -170), "scale": Vector3(1.5, 1.2, 1.3), "rot": 0.5},
		{"pos": Vector3(365, 48, -160), "scale": Vector3(1.5, 1.2, 1.3), "rot": -0.45},
		
		# High altitude cloud banks framing Floor 2 canopy:
		{"pos": Vector3(-160, 88, -75), "scale": Vector3(1.3, 1.0, 1.2), "rot": 0.2},
		{"pos": Vector3(170, 90, -85), "scale": Vector3(1.35, 1.05, 1.2), "rot": -0.3},
		{"pos": Vector3(-220, 92, 15), "scale": Vector3(1.2, 0.95, 1.1), "rot": 0.4},
		{"pos": Vector3(230, 90, 5), "scale": Vector3(1.25, 1.0, 1.15), "rot": -0.35},
		{"pos": Vector3(0, 94, -145), "scale": Vector3(1.4, 1.1, 1.25), "rot": 0.1}
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
	
	# Anime Cumulus structure: Flat pillowy base + tiered billowing domes
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
	
	# Tonemapping (Filmic Anime curve - balanced exposure without blowout)
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
	
	# Spec Camera
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.position = Vector3(0, 55, 230)
	cam.rotation = Vector3(-0.240, 0, 0)
	cam.fov = 50.0
	cam.current = true
	root.add_child(cam)
	
	# Inner Ground plane with stylized cobblestone triplanar shader
	var ground_sb := StaticBody3D.new()
	ground_sb.name = "Ground"
	root.add_child(ground_sb)
	var pm := PlaneMesh.new()
	pm.size = Vector2(700, 700)
	pm.material = _get_cobblestone_material(Color(0.68, 0.66, 0.62), 0.32)
	var gmi := MeshInstance3D.new()
	gmi.name = "Mesh"
	gmi.mesh = pm
	gmi.position = Vector3(0, -0.02, 0)
	ground_sb.add_child(gmi)
	var col := CollisionShape3D.new()
	col.name = "Collision"
	var bs := BoxShape3D.new()
	bs.size = Vector3(700, 1, 700)
	col.shape = bs
	col.position = Vector3(0, -0.5, 0)
	ground_sb.add_child(col)

	# Roads & Plaza with stylized cobblestone shader
	var road_m := _get_cobblestone_material(Color(0.78, 0.76, 0.72), 0.32)
	var grass_m := _mat(Color(0.28, 0.52, 0.26))
	_add_road(root, road_m, Vector3(0, 0.06, 28), 0.0)
	_add_road(root, road_m, Vector3(0, 0.06, 28), PI / 2.0)
	_add_road(root, road_m, Vector3(0, 0.06, 28), PI / 4.0)
	_add_road(root, road_m, Vector3(0, 0.06, 28), -PI / 4.0)
	var avenue := _mi(_box(Vector3(18, 0.15, 190), _get_cobblestone_material(Color(0.84, 0.82, 0.78), 0.32)), Vector3(0, 0.07, 75))
	avenue.name = "Avenue"
	root.add_child(avenue)
	var avgl := _mi(_box(Vector3(5, 0.14, 190), grass_m), Vector3(-11.5, 0.06, 75))
	avgl.name = "AvenueGrassL"
	root.add_child(avgl)
	var avgr := _mi(_box(Vector3(5, 0.14, 190), grass_m), Vector3(11.5, 0.06, 75))
	avgr.name = "AvenueGrassR"
	root.add_child(avgr)

	# Central Plaza disc with cobblestone shader
	var plaza_m := _get_cobblestone_material(Color(0.88, 0.86, 0.82), 0.32)
	var plaza := _mi(_cyl(34.0, 34.0, 0.3, plaza_m, 48), Vector3(0, 0.15, 28))
	plaza.name = "PlazaDisc"
	root.add_child(plaza)
	for i in 24:
		var a := TAU * float(i) / 24.0
		var pillar := _mi(_cyl(0.7, 0.8, 6.0, _mat(Color(0.906, 0.894, 0.863)), 10), Vector3(cos(a) * 30.0, 3.3, 28.0 + sin(a) * 30.0))
		pillar.name = "Col_%02d" % i
		root.add_child(pillar)
	var ring := TorusMesh.new()
	ring.inner_radius = 29.2
	ring.outer_radius = 30.8
	ring.material = _mat(Color(0.769, 0.416, 0.227), 0.8)
	var col_ring := _mi(ring, Vector3(0, 6.5, 28))
	col_ring.name = "ColonnadeRing"
	root.add_child(col_ring)
	var mon_base := _mi(_box(Vector3(3, 2, 3), _mat(Color(0.66, 0.63, 0.57))), Vector3(0, 1.3, 28))
	mon_base.name = "MonumentBase"
	root.add_child(mon_base)
	var mon_col := _mi(_cyl(1.0, 1.2, 9.0, _mat(Color(0.906, 0.894, 0.863)), 12), Vector3(0, 6.8, 28))
	mon_col.name = "MonumentColumn"
	root.add_child(mon_col)

	# Modular Landmark Parts
	var church: Node3D = (load("res://scenes/parts/church.tscn") as PackedScene).instantiate()
	church.position = Vector3(0, 0, 0)
	root.add_child(church)
	var lake: Node3D = (load("res://scenes/parts/lake_park.tscn") as PackedScene).instantiate()
	lake.position = Vector3(0, 0, 95)
	root.add_child(lake)
	var wall: Node3D = (load("res://scenes/parts/city_wall.tscn") as PackedScene).instantiate()
	wall.position = Vector3(0, 0, 180)
	root.add_child(wall)

	# Aincrad Environment Parts (Floor 2 Ceiling, Perimeter Mountains, Anime Clouds)
	var ceiling: Node3D = (load("res://scenes/parts/floor2_ceiling.tscn") as PackedScene).instantiate()
	ceiling.position = Vector3(0, 0, 0)
	root.add_child(ceiling)
	var landscape: Node3D = (load("res://scenes/parts/perimeter_landscape.tscn") as PackedScene).instantiate()
	landscape.position = Vector3(0, 0, 0)
	root.add_child(landscape)
	var clouds: Node3D = (load("res://scenes/parts/anime_clouds.tscn") as PackedScene).instantiate()
	clouds.position = Vector3(0, 0, 0)
	root.add_child(clouds)

	# One MultiMeshInstance3D per kit item (houses + anime trees) with toon shader + outline on buildings
	var toon_building_mat := _get_toon_material(Color(0.94, 0.93, 0.91), true, 2.2)
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
	print("PREBAKED_INSTANCES: ", baked_count)
	for c in root.get_children():
		c.owner = root
		_set_owner_recursive(c, root)
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
