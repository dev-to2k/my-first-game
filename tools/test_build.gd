extends SceneTree

func _init() -> void:
	var f := FileAccess.open("res://test_build_out.txt", FileAccess.WRITE)
	var s = load("res://tools/build_city.gd")
	f.store_string("LOAD SCRIPT: %s\n" % str(s))
	f.close()
	quit()
