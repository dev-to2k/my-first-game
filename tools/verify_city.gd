extends SceneTree
## Verify SAO Starting City output. Run headless, prints VERIFY_* lines.

func _init() -> void:
	var ps: PackedScene = load("res://scenes/sao_starting_city.tscn")
	if ps == null:
		print("VERIFY_FAIL load main")
		quit()
		return
	var root = ps.instantiate()
	var mm_nodes := 0
	var mm_total := 0
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MultiMeshInstance3D:
			mm_nodes += 1
			mm_total += (n as MultiMeshInstance3D).multimesh.instance_count
		for c in n.get_children():
			stack.append(c)
	var lines := []
	lines.append("VERIFY_MMI_NODES: %d INSTANCES: %d" % [mm_nodes, mm_total])
	var cam: Camera3D = root.get_node("Camera3D")
	lines.append("VERIFY_CAM pos=%s rot=%s fov=%s" % [str(cam.position), str(cam.rotation), str(cam.fov)])
	var sun: DirectionalLight3D = root.get_node("Sun")
	lines.append("VERIFY_SUN rot=%s energy=%s" % [str(sun.rotation), str(sun.light_energy)])
	var we: WorldEnvironment = root.get_node("WorldEnvironment")
	var e: Environment = we.environment
	lines.append("VERIFY_ENV fog=%s density=%s aerial=%s glow=%s tonemap=%s" % [str(e.fog_enabled), str(e.fog_density), str(e.fog_aerial_perspective), str(e.glow_enabled), str(e.tonemap_mode)])
	for p in ["res://scenes/parts/church.tscn", "res://scenes/parts/lake_park.tscn", "res://scenes/parts/city_wall.tscn", "res://scenes/parts/floor2_ceiling.tscn", "res://scenes/parts/perimeter_landscape.tscn", "res://scenes/parts/anime_clouds.tscn"]:
		lines.append("VERIFY_PART %s ok=%s" % [p, str(load(p) != null)])
	for k in ["house_s", "house_m", "house_l", "corner", "tower_small", "tree_oak", "tree_small"]:
		lines.append("VERIFY_KIT %s ok=%s" % [k, str(load("res://assets/city_kit/%s.tscn" % k) != null)])
	lines.append("VERIFY_DONE")
	
	var out_str := "\n".join(lines)
	print(out_str)
	var f := FileAccess.open("res://verify_results.txt", FileAccess.WRITE)
	if f != null:
		f.store_string(out_str)
		f.close()
	root.free()
	quit()
