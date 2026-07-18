extends Control
## Title — full-bleed 80s fantasy one-sheet (Dark Crystal poster language).
## Art goes edge-to-edge. No gold picture frame, no framed-painting matte.


## Soft title foil (typography only — not a border)
const GOLD := Color(0.78, 0.68, 0.42, 0.92)
const GOLD_DIM := Color(0.52, 0.44, 0.28, 0.75)
const INK := Color(0.06, 0.05, 0.07, 0.88)


func _ready() -> void:
	if Music:
		Music.play(Music.Track.TITLE)
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)

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
		# Slight cool grade — poster print, not sunny brochure
		bg.modulate = Color(0.94, 0.92, 0.96)
	else:
		var fallback := ColorRect.new()
		fallback.set_anchors_preset(PRESET_FULL_RECT)
		fallback.color = Color(0.08, 0.07, 0.1)
		add_child(fallback)
	add_child(bg)

	# Soft cinematic vignette only (no hard frame)
	var vig := ColorRect.new()
	vig.set_anchors_preset(PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.color = Color(0.04, 0.03, 0.06, 0.18)
	add_child(vig)

	var bottom_shade := ColorRect.new()
	bottom_shade.set_anchors_preset(PRESET_BOTTOM_WIDE)
	bottom_shade.offset_top = -280
	bottom_shade.color = Color(0.03, 0.02, 0.04, 0.62)
	bottom_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_shade)

	var top_shade := ColorRect.new()
	top_shade.set_anchors_preset(PRESET_TOP_WIDE)
	top_shade.offset_bottom = 140
	top_shade.color = Color(0.03, 0.02, 0.04, 0.32)
	top_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_shade)

	# Title block — poster typography over full-bleed art
	var title_block := VBoxContainer.new()
	title_block.set_anchors_preset(PRESET_CENTER_TOP)
	title_block.offset_left = -340
	title_block.offset_top = 36
	title_block.offset_right = 340
	title_block.offset_bottom = 165
	title_block.add_theme_constant_override("separation", 6)
	add_child(title_block)

	var title := Label.new()
	title.text = "CRYSTALWARD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color(0.88, 0.78, 0.52))
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	title.add_theme_constant_override("outline_size", 12)
	title_block.add_child(title)

	var tagline := Label.new()
	tagline.text = "Defend the Lightwell"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 17)
	tagline.add_theme_color_override("font_color", Color(0.82, 0.76, 0.66))
	tagline.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.02, 0.9))
	tagline.add_theme_constant_override("outline_size", 4)
	title_block.add_child(tagline)

	# Thin rule under title (poster type treatment, not filigree frame)
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(120, 1)
	rule.color = Color(0.7, 0.6, 0.4, 0.45)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_block.add_child(rule)

	# Menu — translucent plate over art (no double gold border / foil plate)
	var menu_host := CenterContainer.new()
	menu_host.set_anchors_preset(PRESET_CENTER_BOTTOM)
	menu_host.offset_top = -248
	menu_host.offset_bottom = -28
	menu_host.offset_left = -210
	menu_host.offset_right = 210
	add_child(menu_host)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.04, 0.06, 0.78)
	sb.set_corner_radius_all(4)
	sb.border_color = Color(0.55, 0.48, 0.32, 0.35)
	sb.set_border_width_all(1)
	sb.shadow_color = Color(0.01, 0.01, 0.02, 0.5)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 5)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 18
	sb.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", sb)
	menu_host.add_child(panel)

	var center := VBoxContainer.new()
	center.add_theme_constant_override("separation", 9)
	panel.add_child(center)

	var flavor := Label.new()
	flavor.text = "The Crystal is fractured. Umbrite seeps through Thren.\nHold the Lightwell until Conjunction."
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.add_theme_font_size_override("font_size", 13)
	flavor.add_theme_color_override("font_color", Color(0.84, 0.8, 0.72, 0.92))
	flavor.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.02, 0.85))
	flavor.add_theme_constant_override("outline_size", 3)
	center.add_child(flavor)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	center.add_child(spacer)

	center.add_child(_btn("Play Campaign", _on_play))
	center.add_child(_btn("Quick Battle", _on_quick))
	center.add_child(_btn("Quit", _on_quit))

	var tips := Label.new()
	tips.text = "1–2 wardens · keyboard or gamepad"
	tips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tips.add_theme_font_size_override("font_size", 11)
	tips.add_theme_color_override("font_color", Color(0.65, 0.58, 0.48, 0.85))
	tips.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	tips.add_theme_constant_override("outline_size", 2)
	center.add_child(tips)

	# Sparse dust motes
	if FX:
		var p := FX.spark_particles(self, Color(0.72, 0.68, 0.55, 0.16), 6, "glow")
		p.position = Vector2(640, 380)
		var pm := p.process_material as ParticleProcessMaterial
		if pm:
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = 380.0
			pm.gravity = Vector3(0, -0.8, 0)
			pm.initial_velocity_min = 0.3
			pm.initial_velocity_max = 3.0


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
	b.custom_minimum_size = Vector2(276, 42)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color(0.9, 0.84, 0.62))
	b.add_theme_color_override("font_hover_color", Color(0.98, 0.92, 0.72))
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.08, 0.07, 0.08, 0.72)
	n.set_corner_radius_all(3)
	n.border_color = Color(0.5, 0.44, 0.3, 0.4)
	n.set_border_width_all(1)
	n.content_margin_left = 12
	n.content_margin_right = 12
	n.content_margin_top = 7
	n.content_margin_bottom = 7
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.14, 0.11, 0.08, 0.88)
	h.border_color = GOLD
	var pr := n.duplicate() as StyleBoxFlat
	pr.bg_color = Color(0.1, 0.08, 0.06, 0.9)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", pr)
	b.pressed.connect(cb)
	return b


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/map_select.tscn")


func _on_quick() -> void:
	if Campaign and Campaign.has_method("select_map"):
		Campaign.select_map("vale_01")
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit() -> void:
	get_tree().quit()
