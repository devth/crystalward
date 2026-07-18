extends Control
## Campaign select: 5 levels × 10 sub-level maps (phases).


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
	root.offset_left = 36
	root.offset_top = 24
	root.offset_right = -36
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var title := Label.new()
	title.text = "Campaign — Road of Wounds"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	root.add_child(title)
	var sub := Label.new()
	sub.text = "5 levels · 10 maps each · waves grow as levels rise · last map of each level is a boss stage"
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.7, 0.75, 0.72, 0.9))
	root.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)

	if Campaign == null:
		return

	# Group stages under level headers
	var by_level: Dictionary = {}  # chapter -> Array of stage dicts
	for m in Campaign.maps():
		var ch: int = int(m.get("chapter", 1))
		if not by_level.has(ch):
			by_level[ch] = []
		by_level[ch].append(m)

	var chapters: Array = by_level.keys()
	chapters.sort()
	for ch in chapters:
		var stages: Array = by_level[ch]
		if stages.is_empty():
			continue
		var level_name: String = str(stages[0].get("level_name", "Level %d" % ch))
		var header := Label.new()
		header.text = "Level %d · %s" % [ch, level_name]
		header.add_theme_font_size_override("font_size", 20)
		header.add_theme_color_override("font_color", Color(0.85, 0.78, 0.95))
		list.add_child(header)

		for m in stages:
			list.add_child(_stage_row(m))

	var powers_btn := Button.new()
	powers_btn.text = "✦ Powers & Auras (spend dust)"
	powers_btn.pressed.connect(func() -> void:
		_open_powers()
	)
	root.add_child(powers_btn)

	var back := Button.new()
	back.text = "← Back to Title"
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/title.tscn")
	)
	root.add_child(back)


func _open_powers() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var dim := ColorRect.new()
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	layer.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(PRESET_CENTER)
	panel.offset_left = -260
	panel.offset_top = -220
	panel.offset_right = 260
	panel.offset_bottom = 220
	if VisualStyle:
		VisualStyle.style_hud_panel(panel)
	layer.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var title := Label.new()
	title.text = "Powers  ·  Dust: %d" % (GameState.crystal_dust if GameState else 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	v.add_child(title)
	if Powers:
		for id in Powers.CATALOG.keys():
			var def: Dictionary = Powers.CATALOG[id]
			var row := HBoxContainer.new()
			var lab := Label.new()
			var status := "ON" if Powers.has(id) else ("owned" if Powers.is_unlocked(id) else "%d✦" % int(def.get("cost_dust", 0)))
			lab.text = "%s — %s [%s]" % [def.get("name"), def.get("desc"), status]
			lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_child(lab)
			var b := Button.new()
			if Powers.is_unlocked(id):
				b.text = "Equip" if not Powers.is_equipped(id) else "Unequip"
				if id == "double_jump":
					b.text = "Always"
					b.disabled = true
				else:
					var capt := str(id)
					b.pressed.connect(func() -> void:
						Powers.toggle_equip(capt)
						layer.queue_free()
						_open_powers()
					)
			else:
				b.text = "Unlock"
				var capt2 := str(id)
				b.pressed.connect(func() -> void:
					Powers.try_unlock(capt2)
					layer.queue_free()
					_open_powers()
				)
			row.add_child(b)
			v.add_child(row)
	var close := Button.new()
	close.text = "Close"
	close.pressed.connect(layer.queue_free)
	v.add_child(close)


func _stage_row(m: Dictionary) -> Control:
	var id: String = str(m.get("id"))
	var unlocked: bool = Campaign.is_unlocked(id)
	var stars: int = int(Campaign.best_stars.get(id, 0))
	var ph: int = int(m.get("phase", 1))
	var waves: int = int(m.get("waves", 4))
	var is_boss: bool = bool(m.get("has_boss", false))

	var panel := PanelContainer.new()
	if VisualStyle:
		VisualStyle.style_hud_panel(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	panel.add_child(h)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)

	var name_l := Label.new()
	var lock := "" if unlocked else "  🔒"
	var boss_tag := "  ☠ BOSS" if is_boss else ""
	name_l.text = "  %d. %s%s%s" % [ph, m.get("name"), boss_tag, lock]
	name_l.add_theme_font_size_override("font_size", 16)
	name_l.add_theme_color_override(
		"font_color",
		Color(0.95, 0.85, 0.55) if is_boss and unlocked else (Color(0.92, 0.9, 0.88) if unlocked else Color(0.45, 0.45, 0.5))
	)
	info.add_child(name_l)

	var blurb := Label.new()
	blurb.text = "     %s" % str(m.get("blurb", ""))
	blurb.add_theme_font_size_override("font_size", 12)
	blurb.add_theme_color_override("font_color", Color(0.65, 0.7, 0.68))
	info.add_child(blurb)

	var meta := Label.new()
	var star_s := ""
	for i in 3:
		star_s += "★" if i < stars else "☆"
	meta.text = "     %d waves · Best %s" % [waves, star_s]
	meta.add_theme_font_size_override("font_size", 11)
	meta.add_theme_color_override("font_color", Color(0.8, 0.72, 0.45))
	info.add_child(meta)

	var play := Button.new()
	play.text = "Play" if unlocked else "Locked"
	play.disabled = not unlocked
	play.custom_minimum_size = Vector2(90, 36)
	play.pressed.connect(func() -> void:
		Campaign.select_map(id)
		Campaign.save_progress()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	h.add_child(play)
	return panel
