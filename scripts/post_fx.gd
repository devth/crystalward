extends CanvasLayer
## Fullscreen grade — clear cinematic look, not washed watercolor fog.


func _ready() -> void:
	layer = 90
	if _should_use_simple_fallback():
		_add_simple_vignette()
		return
	if not _try_cinematic_grade():
		_add_simple_vignette()


func _should_use_simple_fallback() -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	if OS.has_feature("headless"):
		return true
	return false


func _try_cinematic_grade() -> bool:
	var sh := load("res://shaders/soft_bloom.gdshader") as Shader
	if sh == null:
		push_warning("post_fx: grade shader missing — using vignette fallback")
		return false

	var bbc := BackBufferCopy.new()
	bbc.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(bbc)

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = sh
	# Sharp, readable world — keep bloom soft, kill watercolor mush
	mat.set_shader_parameter("bloom_intensity", 0.12)
	mat.set_shader_parameter("bloom_threshold", 0.68)
	mat.set_shader_parameter("saturation", 1.06)
	mat.set_shader_parameter("contrast", 1.08)
	mat.set_shader_parameter("tint", Color(1.0, 0.99, 1.01, 1.0))
	mat.set_shader_parameter("gold_lift", 0.02)
	mat.set_shader_parameter("clarity", 0.92)
	mat.set_shader_parameter("paper_grain", 0.018)
	mat.set_shader_parameter("pigment_bleed", 0.08)
	mat.set_shader_parameter("wash_strength", 0.06)
	rect.material = mat
	add_child(rect)
	return true


func _add_simple_vignette() -> void:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(0.08, 0.07, 0.1, 0.08)
	add_child(rect)
