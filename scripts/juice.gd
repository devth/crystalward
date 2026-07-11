extends Node
## Screen shake, flashes, freezeframe — game feel.
## Autoloaded as Juice.

var _shake_amp: float = 0.0
var _shake_decay: float = 8.0
var _flash: ColorRect
var _camera: Camera2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_flash()


func bind_camera(cam: Camera2D) -> void:
	_camera = cam


func _ensure_flash() -> void:
	if _flash and is_instance_valid(_flash):
		return
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	layer.add_child(_flash)


func shake(amount: float = 6.0, decay: float = 10.0) -> void:
	_shake_amp = maxf(_shake_amp, amount)
	_shake_decay = decay


func flash(color: Color = Color(1, 0.9, 1, 0.35), duration: float = 0.12) -> void:
	_ensure_flash()
	_flash.color = color
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, duration)


func hitstop(seconds: float = 0.04) -> void:
	## Brief freezeframe. Skips under headless / already-paused so boots stay clean.
	var tree := get_tree()
	if tree == null or tree.paused:
		return
	# DisplayServer.headless is true when launched with --headless
	if DisplayServer.get_name() == "headless":
		return
	Engine.time_scale = 0.15
	await tree.create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	if _shake_amp > 0.05:
		var off := Vector2(
			randf_range(-_shake_amp, _shake_amp),
			randf_range(-_shake_amp, _shake_amp)
		)
		_camera.offset = off
		_shake_amp = lerpf(_shake_amp, 0.0, 1.0 - exp(-_shake_decay * delta))
	else:
		_camera.offset = _camera.offset.lerp(Vector2.ZERO, 1.0 - exp(-12.0 * delta))
		_shake_amp = 0.0
