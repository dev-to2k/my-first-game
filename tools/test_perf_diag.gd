extends SceneTree

var _frames := 0
var _time := 0.0
var _test_idx := 0

func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_run_next_test()

func _run_next_test() -> void:
	for c in root.get_children():
		c.queue_free()
	_frames = 0
	_time = 0.0
	
	var ps: PackedScene = load("res://scenes/sao_starting_city.tscn")
	var inst: Node3D = ps.instantiate()
	root.add_child(inst)
	
	var sun: DirectionalLight3D = inst.get_node_or_null("Sun")
	var we: WorldEnvironment = inst.get_node_or_null("WorldEnvironment")
	
	if _test_idx == 1:
		# Test with shadow splits = 2 and max distance = 200m
		if sun:
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			sun.directional_shadow_max_distance = 220.0
	elif _test_idx == 2:
		# Test without shadows
		if sun:
			sun.shadow_enabled = false
	elif _test_idx == 3:
		# Test without SSAO
		if we and we.environment:
			we.environment.ssao_enabled = false

func _process(delta: float) -> bool:
	_frames += 1
	if _frames > 15:
		_time += delta
	if _frames >= 65:
		var fps := float(_frames - 15) / _time
		var draw_calls: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var primitives: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		print("TEST ", _test_idx, ": FPS=%.1f (%.2f ms) DC=%d PRIM=%d" % [fps, (_time / 50.0) * 1000.0, draw_calls, primitives])
		_test_idx += 1
		if _test_idx > 3:
			quit()
			return true
		_run_next_test()
	return false
