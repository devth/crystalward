extends CanvasLayer
## Fullscreen soft bloom + grade (PJ-style glow).
## Graceful: headless / missing screen-texture → simple vignette ColorRect.


func _ready() -> void:
	layer = 90
	if _should_use_simple_fallback():
		_add_simple_vignette()
		return
	if not _try_soft_bloom():
		_add_simple_vignette()


func _should_use_simple_fallback() -> bool:
	# Screen-texture bloom needs a real display / GPU path.
	if DisplayServer.get_name() == "headless":
		return true
	if OS.has_feature("headless"):
		return true
	return false


func _try_soft_bloom() -> bool:
	var sh := load("res://shaders/soft_bloom.gdshader") as Shader
	if sh == null:
		push_warning("post_fx: soft_bloom shader missing — using vignette fallback")
		return false

	# Ensure backbuffer is available before sampling screen texture.
	var bbc := BackBufferCopy.new()
	bbc.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(bbc)

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = sh
	# Soft ethereal grade — amber lift + violet night (spec art dir)
	mat.set_shader_parameter("bloom_intensity", 0.16)
	mat.set_shader_parameter("saturation", 1.1)
	mat.set_shader_parameter("contrast", 1.04)
	mat.set_shader_parameter("tint", Color(1.02, 0.98, 1.05, 1.0))
	rect.material = mat
	add_child(rect)
	return true


func _add_simple_vignette() -> void:
	# Soft edge darkening without screen-texture (safe on headless / compatibility).
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(0.08, 0.05, 0.12, 0.12)
	add_child(rect)
