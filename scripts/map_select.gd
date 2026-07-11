extends Control
## Campaign map select — unlock path, stars, difficulty.


func _ready() -> void:
	if Music:
		Music.play(Music.Track.MAP_SELECT)
	_build()


func _build() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.09, 0.11)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(PRESET_FULL_RECT)
	root.offset_left = 40
	root.offset_top = 30
	root.offset_right = -40
	root.offset_bottom = -30
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var title := Label.new()
	title.text = "Campaign — Paths of the Soft Dark"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	root.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	if Campaign == null:
		return
	for m in Campaign.maps():
		list.add_child(_map_row(m))

	var back := Button.new()
	back.text = "← Back to Title"
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/title.tscn")
	)
	root.add_child(back)


func _map_row(m: Dictionary) -> Control:
	var id: String = str(m.get("id"))
	var unlocked: bool = Campaign.is_unlocked(id)
	var stars: int = int(Campaign.best_stars.get(id, 0))

	var panel := PanelContainer.new()
	if VisualStyle:
		VisualStyle.style_hud_panel(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	panel.add_child(h)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)

	var name_l := Label.new()
	var lock := "" if unlocked else "  🔒"
	name_l.text = "%s%s" % [m.get("name"), lock]
	name_l.add_theme_font_size_override("font_size", 20)
	name_l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85) if unlocked else Color(0.5, 0.5, 0.55))
	info.add_child(name_l)

	var blurb := Label.new()
	blurb.text = str(m.get("blurb", ""))
	blurb.add_theme_font_size_override("font_size", 13)
	blurb.add_theme_color_override("font_color", Color(0.7, 0.75, 0.7))
	info.add_child(blurb)

	var meta := Label.new()
	var star_s := ""
	for i in 3:
		star_s += "★" if i < stars else "☆"
	meta.text = "Difficulty %d/5 · %d waves · Best %s" % [m.get("difficulty"), m.get("waves"), star_s]
	meta.add_theme_font_size_override("font_size", 12)
	meta.add_theme_color_override("font_color", Color(0.85, 0.75, 0.45))
	info.add_child(meta)

	var play := Button.new()
	play.text = "Enter" if unlocked else "Locked"
	play.disabled = not unlocked
	play.custom_minimum_size = Vector2(100, 40)
	play.pressed.connect(func() -> void:
		Campaign.select_map(id)
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	h.add_child(play)
	return panel
