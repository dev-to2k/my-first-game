extends SceneTree

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/textures")
	
	# 1. Cobblestone Albedo & Pattern Map (512x512)
	# R = Distance2 - Distance (Cell edge / grout mask)
	# G = Cell Value (Per-stone random color variation)
	# B = Distance (Dome height of stone)
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
			# Clamp and shape stone height
			var stone_height: float = clamp((r_val - 0.05) * 1.5, 0.0, 1.0)
			cobble_img.set_pixel(x, y, Color(r_val, g_val, b_val, 1.0))
			cobble_bump.set_pixel(x, y, Color(stone_height, stone_height, stone_height, 1.0))

	cobble_img.generate_mipmaps()
	cobble_img.save_png("res://assets/textures/cobblestone_pattern.png")

	cobble_bump.generate_mipmaps()
	cobble_bump.bump_map_to_normal_map(3.5)
	cobble_bump.save_png("res://assets/textures/cobblestone_normal.png")

	# 2. Water Wave Normal Maps (512x512)
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

	# 3. Water Foam Noise (512x512)
	var fn_foam := FastNoiseLite.new()
	fn_foam.noise_type = FastNoiseLite.TYPE_SIMPLEX
	fn_foam.frequency = 0.05
	fn_foam.fractal_octaves = 3
	var foam_img: Image = fn_foam.get_seamless_image(512, 512)
	foam_img.generate_mipmaps()
	foam_img.save_png("res://assets/textures/water_foam_noise.png")

	print("TEXTURE_BAKE_COMPLETE")
	quit()
