extends SceneTree

var _frames := 0
var _time := 0.0

func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var ps: PackedScene = load("res://scenes/sao_starting_city.tscn")
	var inst: Node3D = ps.instantiate()
	root.add_child(inst)
	
	# Strip outline from trees ONLY
	for k in ["tree_oak", "tree_small"]:
		var mmi: MultiMeshInstance3D = inst.get_node_or_null(k) as MultiMeshInstance3D
		if mmi and mmi.material_override and mmi.material_override.next_pass:
			# Duplicate material so houses retain outline
			var mat: ShaderMaterial = mmi.material_override.duplicate()
			mat.next_pass = null
			mmi.material_override = mat

func _process(delta: float) -> bool:
	_frames += 1
	if _frames > 15:
		_time += delta
	if _frames >= 65:
		var fps := float(_frames - 15) / _time
		var draw_calls: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var primitives: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		var rep := "HOUSES_OUTLINE_ONLY: FPS=%.1f (%.2f ms) DC=%d PRIM=%d\n" % [fps, (_time / 50.0) * 1000.0, draw_calls, primitives]
		print(rep)
		var f := FileAccess.open("c:/Users/Admin/Documents/my-first-game/diag.txt", FileAccess.WRITE)
		if f != null:
			f.store_string(rep)
			f.close()
		quit()
		return true
	return false
