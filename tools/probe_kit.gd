extends SceneTree
func _init() -> void:
	var ps: PackedScene = load("res://assets/kit/house_m.glb")
	if ps == null:
		print("PROBE_FAIL load")
		quit()
		return
	var inst = ps.instantiate()
	var stack: Array = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var m: Mesh = n.mesh
			print("PROBE_MESH surfaces=", m.get_surface_count())
			print("PROBE_MAT ", m.surface_get_material(0))
			var aabb: AABB = m.get_aabb()
			print("PROBE_AABB ", aabb.position, " size=", aabb.size)
		for c in n.get_children():
			stack.append(c)
	print("PROBE_DONE")
	quit()
