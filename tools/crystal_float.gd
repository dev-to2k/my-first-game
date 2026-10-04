extends Node3D
## Floating and slowly rotating Teleport Crystal for SAO Starting City central plaza.

@export var rotation_speed: float = 0.8
@export var bob_amplitude: float = 0.25
@export var bob_frequency: float = 1.8

var _base_y: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	_base_y = position.y

func _process(delta: float) -> void:
	_time += delta
	rotate_y(rotation_speed * delta)
	position.y = _base_y + sin(_time * bob_frequency) * bob_amplitude
