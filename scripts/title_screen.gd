extends Control
## Title screen — rich fantasy backdrop + menu.


func _ready() -> void:
	if Music:
		Music.play(Music.Track.TITLE)
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)

	# Rich painted fantasy background
	var bg := TextureRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = _load_title_bg()
	if tex:
		bg.texture = tex
	else:
		# Fallback solid
		var fallback := ColorRect.new()
		fallback.set_anchors_preset(PRESET_FULL_RECT)
		fallback.color = Color(0.08, 0.1, 0.12)
		add_child(fallback)
	add_child(bg)

	# Soft vignette so UI stays readable
	var vig_top := ColorRect.new()
	vig_top.set_anchors_preset(PRESET_TOP_WIDE)
	vig_top.offset_bottom = 140
	vig_top.color = Color(0.05, 0.04, 0.1, 0.35)
	vig_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig_top)

	var vig_bot := ColorRect.new()
	vig_bot.set_anchors_preset(PRESET_BOTTOM_WIDE)
	vig_bot.offset_top = -280
	vig_bot.color = Color(0.04, 0.03, 0.08, 0.55)
	vig_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig_bot)

	# Gentle darken sides
	var vig_full := ColorRect.new()
	vig_full.set_anchors_preset(PRESET_FULL_RECT)
	vig_full.color = Color(0.08, 0.06, 0.12, 0.18)
	vig_full.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig_full)

	var center := VBoxContainer.new()
	center.set_anchors_preset(PRESET_CENTER)
	center.offset_left = -240
	center.offset_top = -40
	center.offset_right = 240
	center.offset_bottom = 280
	center.add_theme_constant_override("separation", 12)
	add_child(center)

	var title := Label.new()
	title.text = "CRYSTALWARD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.12, 0.98))
	title.add_theme_constant_override("outline_size", 10)
	center.add_child(title)

	var sub := Label.new()
	sub.text = "Defend the Lightwell"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.7, 0.95, 0.8))
	sub.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.06, 0.9))
	sub.add_theme_constant_override("outline_size", 4)
	center.add_child(sub)

	var flavor := Label.new()
	flavor.text = "A forest of thorns, mist, and crystal light.\nCo-op tower defense for 1–2 wardens."
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.add_theme_font_size_override("font_size", 14)
	flavor.add_theme_color_override("font_color", Color(0.9, 0.88, 0.95, 0.92))
	flavor.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.1, 0.85))
	flavor.add_theme_constant_override("outline_size", 3)
	center.add_child(flavor)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	center.add_child(spacer)

	center.add_child(_btn("Play Campaign", _on_play))
	center.add_child(_btn("Quick Battle", _on_quick))
	center.add_child(_btn("Quit", _on_quit))

	var tips := Label.new()
	tips.text = "Switch Pro / Joy-Cons via Bluetooth · Esc pause in-game"
	tips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tips.add_theme_font_size_override("font_size", 12)
	tips.add_theme_color_override("font_color", Color(0.75, 0.72, 0.85, 0.85))
	tips.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	tips.add_theme_constant_override("outline_size", 2)
	center.add_child(tips)

	# Floating pollen / fairy dust over art
	if FX:
		var p := FX.spark_particles(self, Color(0.95, 0.85, 0.55, 0.55), 28, "star")
		p.position = Vector2(640, 400)
		var pm := p.process_material as ParticleProcessMaterial
		if pm:
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = 380.0
			pm.gravity = Vector3(0, -6, 0)
			pm.initial_velocity_min = 4.0
			pm.initial_velocity_max = 18.0
		var p2 := FX.spark_particles(self, Color(0.75, 0.55, 1.0, 0.4), 18, "glow")
		p2.position = Vector2(640, 280)
		var pm2 := p2.process_material as ParticleProcessMaterial
		if pm2:
			pm2.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm2.emission_sphere_radius = 220.0
			pm2.gravity = Vector3(0, -3, 0)


func _load_title_bg() -> Texture2D:
	var path := "res://assets/ui/title_background.jpg"
	if ResourceLoader.exists(path):
		var res := load(path)
		if res is Texture2D:
			return res as Texture2D
	# Raw load if not imported yet
	var global := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global):
		var img := Image.new()
		if img.load(global) == OK:
			return ImageTexture.create_from_image(img)
	return null


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 48)
	b.add_theme_font_size_override("font_size", 18)
	# Soft panel look
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.12, 0.1, 0.18, 0.82)
	n.set_corner_radius_all(10)
	n.border_color = Color(0.75, 0.65, 0.95, 0.55)
	n.set_border_width_all(2)
	n.content_margin_left = 12
	n.content_margin_right = 12
	n.content_margin_top = 8
	n.content_margin_bottom = 8
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.22, 0.18, 0.32, 0.9)
	h.border_color = Color(0.9, 0.8, 1.0, 0.75)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.pressed.connect(cb)
	return b


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/map_select.tscn")


func _on_quick() -> void:
	if Campaign:
		Campaign.select_map("glade")
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit() -> void:
	get_tree().quit()
