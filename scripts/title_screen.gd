extends Control
## Title screen — atmospheric entry to Crystalward.


func _ready() -> void:
	if Music:
		Music.play(Music.Track.TITLE)
	_build_ui()


func _build_ui() -> void:
	# Fullscreen root already Control
	set_anchors_preset(PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.06, 0.08, 0.1)
	add_child(bg)

	# Soft gradient poly via ColorRects
	var glow := ColorRect.new()
	glow.set_anchors_preset(PRESET_FULL_RECT)
	glow.color = Color(0.25, 0.35, 0.28, 0.35)
	add_child(glow)

	var center := VBoxContainer.new()
	center.set_anchors_preset(PRESET_CENTER)
	center.offset_left = -220
	center.offset_top = -180
	center.offset_right = 220
	center.offset_bottom = 200
	center.add_theme_constant_override("separation", 14)
	add_child(center)

	var title := Label.new()
	title.text = "CRYSTALWARD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.15, 0.95))
	title.add_theme_constant_override("outline_size", 8)
	center.add_child(title)

	var sub := Label.new()
	sub.text = "Defend the Lightwell"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.65, 0.9, 0.7))
	center.add_child(sub)

	var flavor := Label.new()
	flavor.text = "A forest of thorns, mist, and crystal light.\nCo-op tower defense for 1–2 wardens."
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.add_theme_font_size_override("font_size", 14)
	flavor.add_theme_color_override("font_color", Color(0.8, 0.78, 0.85, 0.85))
	center.add_child(flavor)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	center.add_child(spacer)

	center.add_child(_btn("Play Campaign", _on_play))
	center.add_child(_btn("Quick Battle", _on_quick))
	center.add_child(_btn("Quit", _on_quit))

	var tips := Label.new()
	tips.text = "Switch Pro / Joy-Cons via Bluetooth · Esc pause in-game"
	tips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tips.add_theme_font_size_override("font_size", 12)
	tips.add_theme_color_override("font_color", Color(0.6, 0.58, 0.7, 0.8))
	center.add_child(tips)

	# Decorative floating motes
	if FX:
		var p := FX.spark_particles(self, Color(0.75, 0.55, 1.0, 0.5), 24, "star")
		p.position = Vector2(640, 360)


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 44)
	b.add_theme_font_size_override("font_size", 18)
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
