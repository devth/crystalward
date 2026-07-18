extends Control
## Title — 80s fantasy one-sheet: aged gold filigree, gritty beauty, soft threat.


## Tarnished gold (foil on aged paper — not bright jewelry)
const GOLD := Color(0.72, 0.58, 0.32, 0.88)
const GOLD_DIM := Color(0.48, 0.38, 0.22, 0.7)
const GOLD_EDGE := Color(0.55, 0.42, 0.22, 0.55)
const INK := Color(0.06, 0.05, 0.07, 0.88)
const PARCHMENT := Color(0.88, 0.82, 0.68, 0.92)


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
		# Slight cool grade so it never reads "sunny brochure"
		bg.modulate = Color(0.92, 0.9, 0.95)
	else:
		var fallback := ColorRect.new()
		fallback.set_anchors_preset(PRESET_FULL_RECT)
		fallback.color = Color(0.08, 0.07, 0.1)
		add_child(fallback)
	add_child(bg)

	# Gritty atmospheric matte (bruised dusk, not purple Halloween fog)
	var vig := ColorRect.new()
	vig.set_anchors_preset(PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.color = Color(0.05, 0.04, 0.07, 0.28)
	add_child(vig)

	var bottom_shade := ColorRect.new()
	bottom_shade.set_anchors_preset(PRESET_BOTTOM_WIDE)
	bottom_shade.offset_top = -260
	bottom_shade.color = Color(0.04, 0.03, 0.05, 0.58)
	bottom_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_shade)

	var top_shade := ColorRect.new()
	top_shade.set_anchors_preset(PRESET_TOP_WIDE)
	top_shade.offset_bottom = 120
	top_shade.color = Color(0.04, 0.03, 0.05, 0.35)
	top_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_shade)

	# Aged gold filigree frame (paperback / one-sheet ornament)
	_add_aged_gold_frame()

	# Title block
	var title_block := VBoxContainer.new()
	title_block.set_anchors_preset(PRESET_CENTER_TOP)
	title_block.offset_left = -340
	title_block.offset_top = 40
	title_block.offset_right = 340
	title_block.offset_bottom = 175
	title_block.add_theme_constant_override("separation", 5)
	add_child(title_block)

	var title := Label.new()
	title.text = "CRYSTALWARD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	# Aged foil gold — dull sheen, not chrome yellow
	title.add_theme_color_override("font_color", Color(0.86, 0.74, 0.48))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.04, 0.95))
	title.add_theme_constant_override("outline_size", 11)
	title_block.add_child(title)

	var tagline := Label.new()
	tagline.text = "Defend the Lightwell"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 18)
	tagline.add_theme_color_override("font_color", Color(0.78, 0.72, 0.62))
	tagline.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.03, 0.9))
	tagline.add_theme_constant_override("outline_size", 4)
	title_block.add_child(tagline)

	var rule_row := HBoxContainer.new()
	rule_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rule_row.add_theme_constant_override("separation", 8)
	title_block.add_child(rule_row)
	rule_row.add_child(_filigree_pip())
	var line := ColorRect.new()
	line.custom_minimum_size = Vector2(140, 1)
	line.color = GOLD_DIM
	rule_row.add_child(line)
	rule_row.add_child(_filigree_pip())

	# Menu — dark lacquer, tarnished gold rim (80s foil plate)
	var menu_host := CenterContainer.new()
	menu_host.set_anchors_preset(PRESET_CENTER_BOTTOM)
	menu_host.offset_top = -248
	menu_host.offset_bottom = -28
	menu_host.offset_left = -210
	menu_host.offset_right = 210
	add_child(menu_host)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.06, 0.07, 0.82)
	sb.set_corner_radius_all(3)
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.shadow_color = Color(0.02, 0.01, 0.02, 0.55)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 16
	sb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", sb)
	menu_host.add_child(panel)

	var inner := PanelContainer.new()
	var isb := StyleBoxFlat.new()
	isb.bg_color = Color(0, 0, 0, 0)
	isb.set_corner_radius_all(2)
	isb.border_color = GOLD_EDGE
	isb.set_border_width_all(1)
	isb.content_margin_left = 14
	isb.content_margin_right = 14
	isb.content_margin_top = 10
	isb.content_margin_bottom = 10
	inner.add_theme_stylebox_override("panel", isb)
	panel.add_child(inner)

	var center := VBoxContainer.new()
	center.add_theme_constant_override("separation", 9)
	inner.add_child(center)

	var flavor := Label.new()
	flavor.text = "The Crystal is fractured. Umbrite seeps through Thren.\nHold the Lightwell until Conjunction."
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.add_theme_font_size_override("font_size", 13)
	flavor.add_theme_color_override("font_color", Color(0.82, 0.78, 0.7, 0.92))
	flavor.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.02, 0.85))
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
	tips.add_theme_color_override("font_color", Color(0.62, 0.55, 0.42, 0.85))
	tips.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	tips.add_theme_constant_override("outline_size", 2)
	center.add_child(tips)

	# Sparse dust — ash/gold, not fairy confetti
	if FX:
		var p := FX.spark_particles(self, Color(0.7, 0.62, 0.45, 0.2), 8, "glow")
		p.position = Vector2(640, 380)
		var pm := p.process_material as ParticleProcessMaterial
		if pm:
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = 380.0
			pm.gravity = Vector3(0, -0.8, 0)
			pm.initial_velocity_min = 0.3
			pm.initial_velocity_max = 3.5


func _filigree_pip() -> Control:
	var d := ColorRect.new()
	d.custom_minimum_size = Vector2(4, 4)
	d.color = GOLD
	return d


func _add_aged_gold_frame() -> void:
	## 80s fantasy paperback / one-sheet: thin tarnished foil border + corner scrolls.
	var m := 16.0
	add_child(_rect_border(m, GOLD_DIM, 1.5))
	add_child(_rect_border(m + 6.0, GOLD_EDGE, 1.0))
	# Mid-side diamond pips (classic foil plate detail)
	for side in ["top", "bottom", "left", "right"]:
		_add_side_pip(side, m + 3.0)

	var signs := [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
	for s in signs:
		_add_corner_scroll(s)


func _rect_border(margin: float, col: Color, width: float) -> Control:
	var host := Control.new()
	host.set_anchors_preset(PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := ColorRect.new()
	top.color = col
	top.set_anchors_preset(PRESET_TOP_WIDE)
	top.offset_left = margin
	top.offset_right = -margin
	top.offset_bottom = width
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(top)
	var bot := ColorRect.new()
	bot.color = col
	bot.set_anchors_preset(PRESET_BOTTOM_WIDE)
	bot.offset_left = margin
	bot.offset_right = -margin
	bot.offset_top = -width
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(bot)
	var left := ColorRect.new()
	left.color = col
	left.set_anchors_preset(PRESET_LEFT_WIDE)
	left.offset_top = margin
	left.offset_bottom = -margin
	left.offset_right = width
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(left)
	var right := ColorRect.new()
	right.color = col
	right.set_anchors_preset(PRESET_RIGHT_WIDE)
	right.offset_top = margin
	right.offset_bottom = -margin
	right.offset_left = -width
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(right)
	return host


func _add_side_pip(side: String, inset: float) -> void:
	var pip := ColorRect.new()
	pip.color = GOLD
	pip.custom_minimum_size = Vector2(6, 6)
	pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match side:
		"top":
			pip.set_anchors_preset(PRESET_CENTER_TOP)
			pip.offset_left = -3
			pip.offset_right = 3
			pip.offset_top = inset
			pip.offset_bottom = inset + 6
		"bottom":
			pip.set_anchors_preset(PRESET_CENTER_BOTTOM)
			pip.offset_left = -3
			pip.offset_right = 3
			pip.offset_top = -inset - 6
			pip.offset_bottom = -inset
		"left":
			pip.set_anchors_preset(PRESET_CENTER_LEFT)
			pip.offset_left = inset
			pip.offset_right = inset + 6
			pip.offset_top = -3
			pip.offset_bottom = 3
		"right":
			pip.set_anchors_preset(PRESET_CENTER_RIGHT)
			pip.offset_left = -inset - 6
			pip.offset_right = -inset
			pip.offset_top = -3
			pip.offset_bottom = 3
	add_child(pip)


func _add_corner_scroll(sign: Vector2) -> void:
	## Compact corner scroll: L-bracket + worn leaf curves (aged foil, not shiny chrome).
	var host := Control.new()
	host.set_anchors_preset(PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(host)
	var root := Node2D.new()
	root.z_index = 30
	host.add_child(root)
	var sx: float = sign.x
	var sy: float = sign.y
	# Outer L plate
	var outer := Polygon2D.new()
	outer.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(sx * 48, 0), Vector2(sx * 48, sy * 2.5),
		Vector2(sx * 2.5, sy * 2.5), Vector2(sx * 2.5, sy * 48), Vector2(0, sy * 48)
	])
	outer.color = GOLD_DIM
	root.add_child(outer)
	# Mid scroll step
	var mid := Polygon2D.new()
	mid.polygon = PackedVector2Array([
		Vector2(sx * 6, sy * 6), Vector2(sx * 36, sy * 6), Vector2(sx * 36, sy * 9),
		Vector2(sx * 9, sy * 9), Vector2(sx * 9, sy * 36), Vector2(sx * 6, sy * 36)
	])
	mid.color = GOLD
	root.add_child(mid)
	# Inner worn highlight (partial — aged metal catch-light)
	var hi := Polygon2D.new()
	hi.polygon = PackedVector2Array([
		Vector2(sx * 10, sy * 10), Vector2(sx * 28, sy * 10), Vector2(sx * 28, sy * 12),
		Vector2(sx * 12, sy * 12), Vector2(sx * 12, sy * 28), Vector2(sx * 10, sy * 28)
	])
	hi.color = Color(0.82, 0.7, 0.42, 0.35)
	root.add_child(hi)
	# Corner diamond
	var d := Polygon2D.new()
	d.polygon = PackedVector2Array([
		Vector2(sx * 16, sy * 4), Vector2(sx * 20, sy * 8),
		Vector2(sx * 16, sy * 12), Vector2(sx * 12, sy * 8)
	])
	d.color = GOLD
	root.add_child(d)
	# Leaf curl
	var leaf := Polygon2D.new()
	leaf.polygon = PackedVector2Array([
		Vector2(sx * 22, sy * 14), Vector2(sx * 34, sy * 16), Vector2(sx * 30, sy * 22),
		Vector2(sx * 24, sy * 18)
	])
	leaf.color = Color(GOLD.r, GOLD.g, GOLD.b, 0.75)
	root.add_child(leaf)

	host.resized.connect(func():
		_place_corner(root, sx, sy, host.size)
	)
	call_deferred("_place_corner", root, sx, sy, get_viewport_rect().size)


func _place_corner(root: Node2D, sx: float, sy: float, sz: Vector2) -> void:
	if not is_instance_valid(root):
		return
	if sz.x < 8.0:
		sz = get_viewport_rect().size
	root.position = Vector2(
		20.0 if sx > 0 else sz.x - 20.0,
		20.0 if sy > 0 else sz.y - 20.0
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
	b.custom_minimum_size = Vector2(276, 42)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color(0.9, 0.82, 0.58))
	b.add_theme_color_override("font_hover_color", Color(0.98, 0.9, 0.7))
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.1, 0.08, 0.07, 0.75)
	n.set_corner_radius_all(2)
	n.border_color = GOLD_DIM
	n.set_border_width_all(1)
	n.content_margin_left = 12
	n.content_margin_right = 12
	n.content_margin_top = 7
	n.content_margin_bottom = 7
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.16, 0.12, 0.08, 0.88)
	h.border_color = GOLD
	var pr := n.duplicate() as StyleBoxFlat
	pr.bg_color = Color(0.12, 0.09, 0.06, 0.9)
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
