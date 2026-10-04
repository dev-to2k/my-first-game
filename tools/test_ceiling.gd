extends SceneTree

func _init() -> void:
	var env := Environment.new()
	for p in env.get_property_list():
		var name: String = p["name"]
		if name.begins_with("fog_"):
			print(name, " = ", env.get(name))
	quit()
