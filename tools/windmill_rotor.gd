extends Node3D
## Rotates windmill sails steadily around Z axis.

@export var rotation_speed: float = 0.45

func _process(delta: float) -> void:
	rotate_z(rotation_speed * delta)
