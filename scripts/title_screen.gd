extends Control
## Title — photoreal Dark Crystal poster: gold filigree, luminous crystal landscape.


func _ready() -> void:
	if Music:
		Music.play(Music.Track.TITLE)
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)

	# Full-bleed cover painting
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
		fallback.color = Color(0.12, 0.14, 0.16)
		add_child(fallback)
	add_child(bg)

	# Very light warm matte — keep the painting bright and realistic
	var vig := ColorRect.new()
	vig.set_anchors_preset(PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.color = Color(0.08, 0.06, 0.1, 0.12)
	add_child(vig)

	# Soft bottom readability band (not heavy purple fog)
	var bottom_shade := ColorRect.new()
	bottom_shade.set_anchors_preset(PRESET_BOTTOM_WIDE)
	bottom_shade.offset_top = -240
	bottom_shade.color = Color(0.06, 0.05, 0.08, 0.42)
	bottom_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_shade)

	# Gold filigree frame (poster border)
	_add_gold_filigree_frame()

	# Title — classic one-sheet gold lettering
	var title_block := VBoxContainer.new()
	title_block.set_anchors_preset(PRESET_CENTER_TOP)
	title_block.offset_left = -340
	title_block.offset_top = 36
	title_block.offset_right = 340
	title_block.offset_bottom = 180
	title_block.add_theme_constant_override("separation", 4)
	add_child(title_block)

	var title := Label.new()
	title.text = "CRYSTALWARD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 62)
	title.add_theme_color_override("font_color", Color(0.98, 0.9, 0.62))  # gold leaf
	title.add_theme_color_override("font_outline_color", Color(0.18, 0.1, 0.04, 0.92))
	title.add_theme_constant_override("outline_size", 10)
	title_block.add_child(title)

	var tagline := Label.new()
	tagline.text = "Defend the Lightwell"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 20)
	tagline.add_theme_color_override("font_color", Color(0.92, 0.86, 0.72))
	tagline.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.04, 0.9))
	tagline.add_theme_constant_override("outline_size", 4)
	title_block.add_child(tagline)

	# Gold rule with small filigree dots
	var rule_row := HBoxContainer.new()
	rule_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rule_row.add_theme_constant_override("separation", 10)
	title_block.add_child(rule_row)
	rule_row.add_child(_gold_dot())
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(160, 2)
	line.color = Color(0.9, 0.75, 0.4, 0.7)
	rule_row.add_child(line)
	rule_row.add_child(_gold_dot())

	# Menu — dark lacquer with gold rim (elegant, not spooky)
	var menu_host := CenterContainer.new()
	menu_host.set_anchors_preset(PRESET_CENTER_BOTTOM)
	menu_host.offset_top = -248
	menu_host.offset_bottom = -32
	menu_host.offset_left = -210
	menu_host.offset_right = 210
	add_child(menu_host)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.1, 0.78)
	sb.set_corner_radius_all(6)
	sb.border_color = Color(0.88, 0.72, 0.38, 0.75)  # gold filigree edge
	sb.set_border_width_all(2)
	sb.shadow_color = Color(0.05, 0.03, 0.02, 0.45)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 5)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 18
	sb.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", sb)
	menu_host.add_child(panel)

	# Inner gold hairline
	var inner := PanelContainer.new()
	var isb := StyleBoxFlat.new()
	isb.bg_color = Color(0, 0, 0, 0)
	isb.set_corner_radius_all(4)
	isb.border_color = Color(0.78, 0.62, 0.32, 0.35)
	isb.set_border_width_all(1)
	isb.content_margin_left = 12
	isb.content_margin_right = 12
	isb.content_margin_top = 8
	isb.content_margin_bottom = 8
	inner.add_theme_stylebox_override("panel", isb)
	panel.add_child(inner)

	var center := VBoxContainer.new()
	center.add_theme_constant_override("separation", 10)
	inner.add_child(center)

	var flavor := Label.new()
	flavor.text = "A fractured crystal. A living world.\nHold the light until Conjunction."
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.add_theme_font_size_override("font_size", 14)
	flavor.add_theme_color_override("font_color", Color(0.94, 0.9, 0.82, 0.92))
	flavor.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.8))
	flavor.add_theme_constant_override("outline_size", 3)
	center.add_child(flavor)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	center.add_child(spacer)

	center.add_child(_btn("Play Campaign", _on_play))
	center.add_child(_btn("Quick Battle", _on_quick))
	center.add_child(_btn("Quit", _on_quit))

	var tips := Label.new()
	tips.text = "1–2 wardens · keyboard or gamepad"
	tips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tips.add_theme_font_size_override("font_size", 12)
	tips.add_theme_color_override("font_color", Color(0.82, 0.74, 0.55, 0.85))
	tips.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	tips.add_theme_constant_override("outline_size", 2)
	center.add_child(tips)

	# Very sparse golden dust — poster atmosphere
	if FX:
		var p := FX.spark_particles(self, Color(0.95, 0.85, 0.55, 0.28), 12, "glow")
		p.position = Vector2(640, 360)
		var pm := p.process_material as ParticleProcessMaterial
		if pm:
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = 400.0
			pm.gravity = Vector3(0, -1.2, 0)
			pm.initial_velocity_min = 0.5
			pm.initial_velocity_max = 5.0


func _gold_dot() -> ColorRect:
	var d := ColorRect.new()
	d.custom_minimum_size = Vector2(5, 5)
	d.color = Color(0.92, 0.78, 0.42, 0.85)
	return d


func _add_gold_filigree_frame() -> void:
	## Ornate gold border + corner flourishes (movie-poster filigree).
	var margin := 18.0
	var gold := Color(0.88, 0.72, 0.38, 0.82)
	var gold_soft := Color(0.78, 0.6, 0.28, 0.45)

	# Outer gold rectangle
	var outer := _rect_border(margin, gold, 2.5)
	add_child(outer)
	# Inner hairline
	var inner := _rect_border(margin + 8.0, gold_soft, 1.0)
	add_child(inner)

	# Corner ornaments
	var corners := [
		Vector2(margin + 4, margin + 4),  # TL
		Vector2(-margin - 4, margin + 4),  # TR (from right)
		Vector2(margin + 4, -margin - 4),  # BL
		Vector2(-margin - 4, -margin - 4),  # BR
	]
	var signs := [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
	for i in 4:
		_add_corner_flourish(corners[i], signs[i], gold)


func _rect_border(m: float, col: Color, width: float) -> Control:
	var host := Control.new()
	host.set_anchors_preset(PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Four lines via ColorRects
	var top := ColorRect.new()
	top.color = col
	top.set_anchors_preset(PRESET_TOP_WIDE)
	top.offset_left = m
	top.offset_right = -m
	top.offset_bottom = width
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(top)
	var bot := ColorRect.new()
	bot.color = col
	bot.set_anchors_preset(PRESET_BOTTOM_WIDE)
	bot.offset_left = m
	bot.offset_right = -m
	bot.offset_top = -width
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(bot)
	var left := ColorRect.new()
	left.color = col
	left.set_anchors_preset(PRESET_LEFT_WIDE)
	left.offset_top = m
	left.offset_bottom = -m
	left.offset_right = width
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(left)
	var right := ColorRect.new()
	right.color = col
	right.set_anchors_preset(PRESET_RIGHT_WIDE)
	right.offset_top = m
	right.offset_bottom = -m
	right.offset_left = -width
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(right)
	return host


func _add_corner_flourish(anchor: Vector2, sign: Vector2, gold: Color) -> void:
	var host := Control.new()
	host.set_anchors_preset(PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(host)

	var base := Vector2(
		anchor.x if sign.x > 0 else get_viewport_rect().size.x + anchor.x,
		anchor.y if sign.y > 0 else get_viewport_rect().size.y + anchor.y
	)
	# Use anchors so it resizes: place with offset from corners
	var root := Node2D.new()
	root.z_index = 20
	# Position via set_anchors after ready — use deferred layout
	root.set_meta("sign", sign)
	root.set_meta("inset", 22.0)
	host.add_child(root)
	# Draw filigree as nested gold arcs (polygon L-brackets + diamond)
	var sx: float = sign.x
	var sy: float = sign.y
	var pieces: Array = [
		# Outer L
		[Vector2(0, 0), Vector2(sx * 42, 0), Vector2(sx * 42, sy * 3), Vector2(sx * 3, sy * 3), Vector2(sx * 3, sy * 42), Vector2(0, sy * 42)],
		# Inner L
		[Vector2(sx * 8, sy * 8), Vector2(sx * 32, sy * 8), Vector2(sx * 32, sy * 11), Vector2(sx * 11, sy * 11), Vector2(sx * 11, sy * 32), Vector2(sx * 8, sy * 32)],
	]
	for pts in pieces:
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array(pts)
		poly.color = gold
		root.add_child(poly)
	# Corner diamond
	var d := Polygon2D.new()
	d.polygon = PackedVector2Array([
		Vector2(sx * 14, sy * 4), Vector2(sx * 18, sy * 8), Vector2(sx * 14, sy * 12), Vector2(sx * 10, sy * 8)
	])
	d.color = Color(gold.r, gold.g, gold.b, 0.95)
	root.add_child(d)
	# Position after layout
	host.resized.connect(func():
		var sz := host.size
		if sz.x < 10.0:
			sz = get_viewport_rect().size
		root.position = Vector2(
			22.0 if sx > 0 else sz.x - 22.0,
			22.0 if sy > 0 else sz.y - 22.0
		)
	)
	# Initial place
	call_deferred("_place_flourish", root, sx, sy)


func _place_flourish(root: Node2D, sx: float, sy: float) -> void:
	if not is_instance_valid(root):
		return
	var sz := get_viewport_rect().size
	root.position = Vector2(
		22.0 if sx > 0 else sz.x - 22.0,
		22.0 if sy > 0 else sz.y - 22.0
	)


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
	b.custom_minimum_size = Vector2(280, 44)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", Color(0.98, 0.92, 0.72))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.85))
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.12, 0.1, 0.1, 0.7)
	n.set_corner_radius_all(4)
	n.border_color = Color(0.86, 0.7, 0.36, 0.65)
	n.set_border_width_all(1)
	n.content_margin_left = 14
	n.content_margin_right = 14
	n.content_margin_top = 8
	n.content_margin_bottom = 8
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.2, 0.16, 0.1, 0.85)
	h.border_color = Color(0.98, 0.86, 0.5, 0.9)
	var pr := n.duplicate() as StyleBoxFlat
	pr.bg_color = Color(0.16, 0.12, 0.08, 0.9)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", pr)
	b.pressed.connect(cb)
	return b


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/map_select.tscn")


func _on_quick() -> void:
	if Campaign:
		if Campaign.has_method("select_map"):
			Campaign.select_map("vale_01")
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit() -> void:
	get_tree().quit()
