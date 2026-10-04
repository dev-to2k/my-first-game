extends Area3D
## SAO Teleport Gate System (Aincrad Floor Transition)
## Handles player / camera entering the interaction zone at the Teleport Plaza.
## Displays anime-style HUD prompt: "Nhấn [F] hoặc [T] để Dịch Chuyển"
## Executes a full-screen white/blue anime warp fade and transitions to target floor scene.

@export_file("*.tscn") var target_scene: String = "res://scenes/floor_02.tscn"
@export var destination_name: String = "Floor 2: Urbus (Tầng 2 - Thành phố Khởi đầu Urbus)"
@export var interaction_radius: float = 8.5
@export var auto_teleport_on_enter: bool = false

var _player_in_range: bool = false
var _is_transitioning: bool = false
var _hud_layer: CanvasLayer = null
var _prompt_panel: PanelContainer = null
var _fade_rect: ColorRect = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_build_hud()

func _build_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "TeleportHUD"
	_hud_layer.layer = 100
	add_child(_hud_layer)

	_prompt_panel = PanelContainer.new()
	_prompt_panel.name = "PromptPanel"
	_prompt_panel.anchors_preset = Control.PRESET_CENTER_BOTTOM
	_prompt_panel.anchor_left = 0.5
	_prompt_panel.anchor_right = 0.5
	_prompt_panel.anchor_top = 1.0
	_prompt_panel.anchor_bottom = 1.0
	_prompt_panel.offset_left = -280
	_prompt_panel.offset_right = 280
	_prompt_panel.offset_top = -135
	_prompt_panel.offset_bottom = -35
	_prompt_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.10, 0.18, 0.88)
	style.border_color = Color(0.25, 0.85, 1.0, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_prompt_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_prompt_panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "◆ CỔNG DỊCH CHUYỂN / TELEPORT GATE ◆"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", Color(0.35, 0.92, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 15)
	vbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "Nhấn [F] hoặc [T] để Dịch Chuyển đến %s" % destination_name
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	sub_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(sub_lbl)

	var hint_lbl := Label.new()
	hint_lbl.text = "[ Nhấp chuột vào đây hoặc bấm phím F / T / Enter ]"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_color_override("font_color", Color(0.65, 0.82, 0.95, 0.75))
	hint_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hint_lbl)

	_prompt_panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			start_teleport()
	)

	_hud_layer.add_child(_prompt_panel)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeOverlay"
	_fade_rect.anchors_preset = Control.PRESET_FULL_RECT
	_fade_rect.anchor_right = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	_hud_layer.add_child(_fade_rect)

func _process(_delta: float) -> void:
	if _is_transitioning:
		return

	# Support camera inspection distance check
	var cam := get_viewport().get_camera_3d()
	if cam:
		var d := global_position.distance_to(cam.global_position)
		var in_range := d <= interaction_radius
		if in_range != _player_in_range:
			_player_in_range = in_range
			_update_prompt_visibility()

func _update_prompt_visibility() -> void:
	if _prompt_panel:
		_prompt_panel.visible = _player_in_range and not _is_transitioning

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if _player_in_range and (event.keycode == KEY_F or event.keycode == KEY_T or event.keycode == KEY_ENTER):
			start_teleport()

func _on_body_entered(_body: Node) -> void:
	_player_in_range = true
	_update_prompt_visibility()
	if auto_teleport_on_enter:
		start_teleport()

func _on_body_exited(_body: Node) -> void:
	_player_in_range = false
	_update_prompt_visibility()

func _on_area_entered(_area: Area3D) -> void:
	_player_in_range = true
	_update_prompt_visibility()

func _on_area_exited(_area: Area3D) -> void:
	_player_in_range = false
	_update_prompt_visibility()

func start_teleport(override_target: String = "") -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if _prompt_panel:
		_prompt_panel.visible = false

	var dest := override_target if override_target != "" else target_scene
	print("[TeleportGate] Initiating Warp Transition to: ", dest)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	_fade_rect.color = Color(0.65, 0.90, 1.0, 0.0)
	tween.tween_property(_fade_rect, "color", Color(1.0, 1.0, 1.0, 1.0), 0.70)
	tween.tween_callback(func():
		var err := get_tree().change_scene_to_file(dest)
		if err != OK:
			push_error("[TeleportGate] Scene change failed for %s, error code: %d" % [dest, err])
			_is_transitioning = false
			_fade_rect.color = Color(1, 1, 1, 0)
	)
