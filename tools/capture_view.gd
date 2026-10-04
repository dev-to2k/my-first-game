extends SceneTree
## Capture the spec camera view to viewport_check.png, then quit.
## Run: Godot --path . --resolution 1280x720 --script res://tools/capture_view.gd
## (Do NOT combine with a scene path argument; this script loads the scene.)

var _frames := 0

func _initialize() -> void:
	var ps: PackedScene = load("res://scenes/sao_starting_city.tscn")
	var inst = ps.instantiate()
	root.add_child(inst)
	process_frame.connect(_on_frame)

func _on_frame() -> void:
	_frames += 1
	if _frames >= 35:
		var img := root.get_texture().get_image()
		var p := ProjectSettings.globalize_path("res://viewport_check.png")
		img.save_png(p)
		print("CAPTURE_DONE: ", p)
		quit()
