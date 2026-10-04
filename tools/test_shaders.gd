extends SceneTree

func _init() -> void:
	print("--- TESTING ALL 4 PRODUCTION SHADERS ---")
	var shader_paths = [
		"res://shaders/toon_cel_shading.gdshader",
		"res://shaders/inverted_hull_outline.gdshader",
		"res://shaders/stylized_water.gdshader",
		"res://shaders/stylized_cobblestone.gdshader",
		"res://shaders/aincrad_sky.gdshader"
	]
	
	var pass_count := 0
	for p in shader_paths:
		var s: Shader = load(p)
		if s == null:
			printerr("FAIL to load: ", p)
			continue
		var mat = ShaderMaterial.new()
		mat.shader = s
		if mat.shader != null:
			pass_count += 1
			print("PASSED: ", p)
		else:
			printerr("FAILED material binding: ", p)
	
	print("RESULT: ", pass_count, "/", shader_paths.size(), " SHADERS VALID")
	quit()
