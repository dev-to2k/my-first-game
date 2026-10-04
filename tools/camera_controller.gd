extends Camera3D
## Dual-mode camera: starts in cinematic view; right-click or Tab toggles free-fly inspection.

@export var move_speed: float = 35.0
@export var sprint_factor: float = 3.0
@export var mouse_sensitivity: float = 0.003

var _free_fly: bool = false
var _initial_pos: Vector3
var _initial_rot: Vector3
var _pitch: float = 0.0
var _yaw: float = 0.0

func _ready() -> void:
	_initial_pos = position
	_initial_rot = rotation
	_pitch = rotation.x
	_yaw = rotation.y

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.keycode == KEY_SPACE:
			_free_fly = !_free_fly
			if not _free_fly:
				position = _initial_pos
				rotation = _initial_rot
				_pitch = _initial_rot.x
				_yaw = _initial_rot.y
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.keycode == KEY_ESCAPE:
			_free_fly = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_free_fly = true
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if _free_fly and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clamp(_pitch - event.relative.y * mouse_sensitivity, -1.5, 1.5)
		rotation = Vector3(_pitch, _yaw, 0.0)

func _process(delta: float) -> void:
	if not _free_fly:
		return
		
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		dir += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		dir += transform.basis.x
	if Input.is_key_pressed(KEY_E):
		dir += Vector3.UP
	if Input.is_key_pressed(KEY_Q):
		dir -= Vector3.UP

	if dir != Vector3.ZERO:
		var speed: float = move_speed
		if Input.is_key_pressed(KEY_SHIFT):
			speed *= sprint_factor
		position += dir.normalized() * speed * delta
