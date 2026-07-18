extends Control
## Title — ethereal 80s Dark Crystal cover-art presentation.


func _ready() -> void:
	if Music:
		Music.play(Music.Track.TITLE)
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)

	# Full-bleed painted cover art
	var bg := TextureRect.new()
	bg.name = "CoverArt"
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var tex: Texture2D = _load_title_bg()
	if tex:
		bg.texture = tex
	else:
		var fallback := ColorRect.new()
		fallback.set_anchors_preset(PRESET_FULL_RECT)
		fallback.color = Color(0.08, 0.06, 0.12)
		add_child(fallback)
	add_child(bg)

	# Soft painted vignette (movie poster matte)
	var vig := ColorRect.new()
	vig.set_anchors_preset(PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.color = Color(0.06, 0.04, 0.1, 0.22)
	add_child(vig)

	# Bottom gradient panel so type reads over the art
	var bottom_shade := ColorRect.new()
	bottom_shade.set_anchors_preset(PRESET_BOTTOM_WIDE)
	bottom_shade.offset_top = -280
	bottom_shade.color = Color(0.05, 0.03, 0.08, 0.55)
	bottom_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_shade)

	# Top subtle shade for title band
	var top_shade := ColorRect.new()
	top_shade.set_anchors_preset(PRESET_TOP_WIDE)
	top_shade.offset_bottom = 160
	top_shade.color = Color(0.04, 0.03, 0.08, 0.4)
	top_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_shade)

	# Poster title block (upper third — classic one-sheet placement)
	var title_block := VBoxContainer.new()
	title_block.set_anchors_preset(PRESET_CENTER_TOP)
	title_block.offset_left = -320
	title_block.offset_top = 48
	title_block.offset_right = 320
	title_block.offset_bottom = 200
	title_block.add_theme_constant_override("separation", 6)
	add_child(title_block)

	var title := Label.new()
	title.text = "CRYSTALWARD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	# Warm parchment gold + soft amethyst glow (poster lettering)
	title.add_theme_color_override("font_color", Color(0.96, 0.9, 0.78))
	title.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.18, 0.95))
	title.add_theme_constant_override("outline_size", 12)
	title_block.add_child(title)

	var tagline := Label.new()
	tagline.text = "Defend the Lightwell"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 22)
	tagline.add_theme_color_override("font_color", Color(0.78, 0.68, 0.92))
	tagline.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.1, 0.92))
	tagline.add_theme_constant_override("outline_size", 5)
	title_block.add_child(tagline)

	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(180, 2)
	line.color = Color(0.85, 0.72, 0.45, 0.55)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_block.add_child(line)

	# Menu panel lower-center (over art, parchment matte)
	var menu_host := CenterContainer.new()
	menu_host.set_anchors_preset(PRESET_CENTER_BOTTOM)
	menu_host.offset_top = -260
	menu_host.offset_bottom = -36
	menu_host.offset_left = -200
	menu_host.offset_right = 200
	add_child(menu_host)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.12, 0.72)
	sb.set_corner_radius_all(14)
	sb.border_color = Color(0.72, 0.58, 0.88, 0.4)
	sb.set_border_width_all(1)
	sb.shadow_color = Color(0.02, 0.01, 0.06, 0.55)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, 6)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 20
	sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	menu_host.add_child(panel)

	var center := VBoxContainer.new()
	center.add_theme_constant_override("separation", 10)
	panel.add_child(center)

	var flavor := Label.new()
	flavor.text = "A fractured crystal. A living forest.\nHold the light until Conjunction."
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.add_theme_font_size_override("font_size", 14)
	flavor.add_theme_color_override("font_color", Color(0.9, 0.86, 0.96, 0.9))
	flavor.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.08, 0.85))
	flavor.add_theme_constant_override("outline_size", 3)
	center.add_child(flavor)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	center.add_child(spacer)

	center.add_child(_btn("Play Campaign", _on_play))
	center.add_child(_btn("Quick Battle", _on_quick))
	center.add_child(_btn("Quit", _on_quit))

	var tips := Label.new()
	tips.text = "1–2 wardens · keyboard or gamepad"
	tips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tips.add_theme_font_size_override("font_size", 12)
	tips.add_theme_color_override("font_color", Color(0.7, 0.65, 0.82, 0.8))
	tips.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	tips.add_theme_constant_override("outline_size", 2)
	center.add_child(tips)

	# Sparse ethereal dust over the painting (not confetti)
	if FX:
		var p := FX.spark_particles(self, Color(0.95, 0.88, 0.65, 0.35), 14, "glow")
		p.position = Vector2(640, 360)
		var pm := p.process_material as ParticleProcessMaterial
		if pm:
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = 420.0
			pm.gravity = Vector3(0, -2.5, 0)
			pm.initial_velocity_min = 1.0
			pm.initial_velocity_max = 8.0
		var p2 := FX.spark_particles(self, Color(0.7, 0.55, 0.95, 0.28), 10, "magic")
		p2.position = Vector2(640, 300)
		var pm2 := p2.process_material as ParticleProcessMaterial
		if pm2:
			pm2.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm2.emission_sphere_radius = 280.0
			pm2.gravity = Vector3(0, -1.5, 0)


func _load_title_bg() -> Texture2D:
	var path := "res://assets/ui/title_background.jpg"
	if ResourceLoader.exists(path):
		var res := load(path)
		if res is Texture2D:
			return res as Texture2D
	var global := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global):
		var img := Image.new()
		if img.load(global) == OK:
			return ImageTexture.create_from_image(img)
	return null


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 46)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color(0.96, 0.92, 0.84))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.9))
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.14, 0.1, 0.2, 0.75)
	n.set_corner_radius_all(8)
	n.border_color = Color(0.78, 0.62, 0.42, 0.5)  # amber gold rim
	n.set_border_width_all(1)
	n.content_margin_left = 14
	n.content_margin_right = 14
	n.content_margin_top = 8
	n.content_margin_bottom = 8
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.22, 0.16, 0.3, 0.88)
	h.border_color = Color(0.95, 0.82, 0.55, 0.75)
	var pr := n.duplicate() as StyleBoxFlat
	pr.bg_color = Color(0.18, 0.12, 0.26, 0.9)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", pr)
	b.pressed.connect(cb)
	return b


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/map_select.tscn")


func _on_quick() -> void:
	if Campaign:
		# First campaign stage
		if Campaign.has_method("select_map"):
			Campaign.select_map("vale_01")
		else:
			Campaign.select_map("glade")
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit() -> void:
	get_tree().quit()
