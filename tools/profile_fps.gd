extends SceneTree
## Profile FPS, Draw Calls, and Frame Time in Forward+

var _frames := 0
var _total_time := 0.0

var _start_time := 0.0

func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var ps: PackedScene = load("res://scenes/sao_starting_city.tscn")
	var inst = ps.instantiate()
	root.add_child(inst)
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	_frames += 1
	if _frames == 16:
		_start_time = Time.get_ticks_msec()
	elif _frames >= 65:
		var elapsed_sec: float = (Time.get_ticks_msec() - _start_time) / 1000.0
		var measured_frames := _frames - 15
		var avg_fps := float(measured_frames) / elapsed_sec
		var avg_msec := (elapsed_sec / float(measured_frames)) * 1000.0
		var draw_calls: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		var primitives: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		var vram_mb: float = float(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)) / (1024.0 * 1024.0)
		
		var rep := ""
		rep += "--- PERFORMANCE REPORT ---\n"
		rep += "MEASURED_FRAMES: %d\n" % measured_frames
		rep += "AVERAGE_FPS: %.1f\n" % avg_fps
		rep += "FRAME_TIME: %.2f ms\n" % avg_msec
		rep += "DRAW_CALLS: %d\n" % draw_calls
		rep += "PRIMITIVES: %d\n" % primitives
		rep += "VRAM_USAGE_MB: %.2f MB\n" % vram_mb
		rep += "PERF_CHECK_DONE\n"
		
		print(rep)
		var p := ProjectSettings.globalize_path("res://perf_results.txt")
		var f := FileAccess.open(p, FileAccess.WRITE)
		if f != null:
			f.store_string(rep)
			f.close()
		quit()
