extends SceneTree

var _frames := 0
var _time := 0.0

func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var ps: PackedScene = load("res://scenes/sao_starting_city.tscn")
	var inst = ps.instantiate()
	root.add_child(inst)

func _process(delta: float) -> bool:
	_frames += 1
	if _frames > 5:
		_time += delta
	if _frames == 30:
		var fps := float(_frames - 5) / _time
		var rep := "FPS_TEST: %.1f FPS (%.2f ms)" % [fps, (_time / float(_frames - 5)) * 1000.0]
		print(rep)
		var f := FileAccess.open("res://breakdown_out.txt", FileAccess.WRITE)
		if f:
			f.store_string(rep)
			f.close()
		quit()
		return true
	return false
