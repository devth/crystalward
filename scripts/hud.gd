extends CanvasLayer
## HUD + pause / controls screen. Always processes while tree is paused.

signal pause_changed(paused: bool)

var _paused: bool = false
var _msg_tween: Tween

@onready var essence_label: Label = $Root/TopBar/Margin/Top/Essence
@onready var dust_label: Label = $Root/TopBar/Margin/Top/Dust
@onready var crystal_label: Label = $Root/TopBar/Margin/Top/Crystal
@onready var wave_label: Label = $Root/TopBar/Margin/Top/Wave
@onready var message_label: Label = $Root/Message
@onready var end_panel: PanelContainer = $Root/EndPanel
@onready var end_label: Label = $Root/EndPanel/VBox/EndText
@onready var pause_layer: Control = $Root/PauseLayer
@onready var hint_label: Label = $Root/Hint


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Polished indie HUD panels
	if VisualStyle:
		if has_node("Root/TopBar"):
			VisualStyle.style_hud_panel($Root/TopBar as PanelContainer)
		if has_node("Root/PauseLayer/Panel"):
			VisualStyle.style_hud_panel($Root/PauseLayer/Panel as PanelContainer)
		if has_node("Root/EndPanel"):
			VisualStyle.style_hud_panel($Root/EndPanel as PanelContainer)
	else:
		if has_node("Root/TopBar"):
			FX.style_panel_kenney($Root/TopBar as PanelContainer, Color(0.42, 0.38, 0.58, 0.92))
		if has_node("Root/PauseLayer/Panel"):
			FX.style_panel_kenney($Root/PauseLayer/Panel as PanelContainer, Color(0.48, 0.42, 0.68, 0.96))
		if has_node("Root/EndPanel"):
			FX.style_panel_kenney($Root/EndPanel as PanelContainer, Color(0.5, 0.4, 0.7, 0.95))

	GameState.essence_changed.connect(_on_essence)
	GameState.crystal_dust_changed.connect(_on_dust)
	GameState.crystal_hp_changed.connect(_on_crystal)
	GameState.wave_changed.connect(_on_wave)
	GameState.game_over.connect(_on_game_over)
	GameState.message.connect(_on_message)
	end_panel.visible = false
	pause_layer.visible = false
	if GameState.has_signal("wave_phase_changed"):
		GameState.wave_phase_changed.connect(_on_wave_phase)
	_on_essence(GameState.essence)
	_on_dust(GameState.crystal_dust)
	_on_crystal(GameState.crystal_hp, GameState.crystal_max_hp)
	_on_wave(GameState.current_wave, GameState.waves_to_win)
	hint_label.text = "Scroll zoom · Z/X tower · Q build · E gather/sell · C attack · F fairy · T wave"
	hint_label.modulate = Color(1, 1, 1, 0.55)
	_ensure_minimap()
	_ensure_call_wave_ui()
	_ensure_burst_hud()
	_ensure_tower_loadout()
	if TowerTypes and TowerTypes.has_signal("unlocks_changed"):
		TowerTypes.unlocks_changed.connect(_refresh_tower_loadout)
	if TowerTypes and TowerTypes.has_signal("selection_changed"):
		TowerTypes.selection_changed.connect(func(_p, _id): _refresh_tower_loadout())


func _ensure_minimap() -> void:
	if has_node("Root/MinimapHost"):
		return
	var host := Control.new()
	host.name = "MinimapHost"
	host.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	host.offset_left = -168.0
	host.offset_top = 64.0
	host.offset_right = -16.0
	host.offset_bottom = 208.0
	host.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	$Root.add_child(host)
	var mm := Control.new()
	mm.set_script(load("res://scripts/minimap.gd"))
	mm.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(mm)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameState.is_game_over:
			return
		toggle_pause()
		get_viewport().set_input_as_handled()
		return

	if _paused:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			toggle_pause()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("restart"):
		_resume_if_needed()
		GameState.reset()
		get_tree().reload_current_scene()
	if event.is_action_pressed("ui_accept") and GameState.is_game_over:
		_resume_if_needed()
		get_tree().change_scene_to_file("res://scenes/map_select.tscn")


func toggle_pause() -> void:
	_paused = not _paused
	get_tree().paused = _paused
	pause_layer.visible = _paused
	hint_label.visible = not _paused
	pause_changed.emit(_paused)


func _resume_if_needed() -> void:
	if _paused:
		_paused = false
		get_tree().paused = false
		pause_layer.visible = false


func _ensure_tower_loadout() -> void:
	if has_node("Root/TowerLoadout"):
		_refresh_tower_loadout()
		return
	var host := HBoxContainer.new()
	host.name = "TowerLoadout"
	host.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	host.offset_top = -72.0
	host.offset_bottom = -28.0
	host.offset_left = 16.0
	host.offset_right = -16.0
	host.alignment = BoxContainer.ALIGNMENT_CENTER
	host.add_theme_constant_override("separation", 8)
	$Root.add_child(host)
	_refresh_tower_loadout()


func _refresh_tower_loadout() -> void:
	var host := get_node_or_null("Root/TowerLoadout") as HBoxContainer
	if host == null or TowerTypes == null:
		return
	for c in host.get_children():
		c.queue_free()
	var unlocked: Array[String] = TowerTypes.unlocked_ids()
	var selected: String = TowerTypes.selected_id_for(0)
	for id in unlocked:
		var d: Dictionary = TowerTypes.def_for(id)
		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		var col: Color = d.get("color", Color.WHITE) as Color
		var is_sel := id == selected
		style.bg_color = Color(col.r * 0.25, col.g * 0.25, col.b * 0.3, 0.88 if is_sel else 0.55)
		style.border_color = col if is_sel else Color(col.r, col.g, col.b, 0.45)
		style.set_border_width_all(2 if is_sel else 1)
		style.set_corner_radius_all(6)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		panel.add_theme_stylebox_override("panel", style)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		var name_l := Label.new()
		name_l.text = str(d.get("short", "?"))
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_l.add_theme_font_size_override("font_size", 12)
		name_l.add_theme_color_override("font_color", col.lightened(0.25))
		var layer_l := Label.new()
		var tgt := str(d.get("target_label", "ALL"))
		layer_l.text = tgt
		layer_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layer_l.add_theme_font_size_override("font_size", 9)
		match str(d.get("target", "both")):
			"air":
				layer_l.add_theme_color_override("font_color", Color(0.65, 0.9, 1.0, 0.95))
			"ground":
				layer_l.add_theme_color_override("font_color", Color(0.55, 0.9, 0.5, 0.95))
			_:
				layer_l.add_theme_color_override("font_color", Color(0.95, 0.9, 0.55, 0.95))
		var cost_l := Label.new()
		cost_l.text = "%d✦" % int(d.get("cost", 0))
		cost_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_l.add_theme_font_size_override("font_size", 10)
		cost_l.add_theme_color_override("font_color", Color(1, 0.9, 0.65, 0.9))
		v.add_child(name_l)
		v.add_child(layer_l)
		v.add_child(cost_l)
		panel.add_child(v)
		# Click to select (P1)
		panel.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				TowerTypes.set_player_pick_id(0, id)
				_refresh_tower_loadout()
		)
		host.add_child(panel)
	# Locked next teaser
	var next_id := ""
	for id in TowerTypes.all_ids():
		if not TowerTypes.is_unlocked(id):
			next_id = id
			break
	if next_id != "":
		var d2: Dictionary = TowerTypes.def_for(next_id)
		var lock := Label.new()
		lock.text = "  next: %s (later surge)" % d2.get("name")
		lock.add_theme_font_size_override("font_size", 11)
		lock.add_theme_color_override("font_color", Color(0.75, 0.7, 0.85, 0.55))
		host.add_child(lock)


func _ensure_call_wave_ui() -> void:
	## Kingdom Rush–style next-wave panel: timer bar, monster type, call-early bonus.
	if has_node("Root/WavePrep"):
		return
	# Remove legacy button if present
	if has_node("Root/CallWaveBtn"):
		$Root/CallWaveBtn.queue_free()

	var panel := PanelContainer.new()
	panel.name = "WavePrep"
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 16.0
	panel.offset_top = 72.0
	panel.offset_right = 340.0
	panel.offset_bottom = 210.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.14, 0.88)
	style.border_color = Color(0.75, 0.55, 0.95, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	$Root.add_child(panel)

	var v := VBoxContainer.new()
	v.name = "VBox"
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	var title := Label.new()
	title.name = "Title"
	title.text = "NEXT SURGE"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.85, 0.8, 0.95, 0.85))
	v.add_child(title)

	var kind_row := HBoxContainer.new()
	kind_row.name = "KindRow"
	kind_row.add_theme_constant_override("separation", 8)
	v.add_child(kind_row)

	var swatch := ColorRect.new()
	swatch.name = "Swatch"
	swatch.custom_minimum_size = Vector2(14, 36)
	swatch.color = Color(0.7, 0.4, 0.9)
	kind_row.add_child(swatch)

	var kind_col := VBoxContainer.new()
	kind_col.name = "KindCol"
	kind_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kind_col.add_theme_constant_override("separation", 0)
	kind_row.add_child(kind_col)

	var kind_name := Label.new()
	kind_name.name = "KindName"
	kind_name.text = "—"
	kind_name.add_theme_font_size_override("font_size", 16)
	kind_name.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	kind_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	kind_name.add_theme_constant_override("outline_size", 3)
	kind_col.add_child(kind_name)

	var kind_hint := Label.new()
	kind_hint.name = "KindHint"
	kind_hint.text = ""
	kind_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kind_hint.add_theme_font_size_override("font_size", 11)
	kind_hint.add_theme_color_override("font_color", Color(0.75, 0.9, 0.7, 0.9))
	kind_col.add_child(kind_hint)

	var timer_lab := Label.new()
	timer_lab.name = "TimerLabel"
	timer_lab.text = "Next in —"
	timer_lab.add_theme_font_size_override("font_size", 13)
	timer_lab.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	v.add_child(timer_lab)

	var bar := ProgressBar.new()
	bar.name = "TimerBar"
	bar.custom_minimum_size = Vector2(0, 14)
	bar.max_value = 1.0
	bar.value = 1.0
	bar.show_percentage = false
	# Fill style
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.55, 0.25, 0.95)
	fill.set_corner_radius_all(4)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.1, 0.18, 0.95)
	bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	v.add_child(bar)

	var btn := Button.new()
	btn.name = "CallBtn"
	btn.text = "⚔ CALL EARLY  +✦  (T)"
	btn.custom_minimum_size = Vector2(0, 34)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(_on_call_wave_pressed)
	v.add_child(btn)

	_refresh_wave_prep()


func _on_call_wave_pressed() -> void:
	var wm := get_tree().get_first_node_in_group("wave_manager")
	if wm and wm.has_method("call_early_wave"):
		wm.call("call_early_wave")
	_refresh_wave_prep()


func _on_wave_phase(_phase: String, _seconds_left: float) -> void:
	_refresh_wave_prep()


func _refresh_wave_prep() -> void:
	var panel := get_node_or_null("Root/WavePrep") as PanelContainer
	if panel == null:
		return
	if GameState and GameState.is_game_over:
		panel.visible = false
		return

	var wm := get_tree().get_first_node_in_group("wave_manager")
	if wm == null:
		panel.visible = false
		return

	var prep := false
	if wm.has_method("is_prep"):
		prep = bool(wm.call("is_prep"))
	elif wm.has_method("get_phase_name"):
		prep = str(wm.call("get_phase_name")) == "prep"

	var done := false
	if wm.has_method("is_done"):
		done = bool(wm.call("is_done"))

	if done:
		panel.visible = false
		return

	panel.visible = true
	var title: Label = panel.get_node_or_null("VBox/Title")
	var kind_name: Label = panel.get_node_or_null("VBox/KindRow/KindCol/KindName")
	var kind_hint: Label = panel.get_node_or_null("VBox/KindRow/KindCol/KindHint")
	var swatch: ColorRect = panel.get_node_or_null("VBox/KindRow/Swatch")
	var timer_lab: Label = panel.get_node_or_null("VBox/TimerLabel")
	var bar: ProgressBar = panel.get_node_or_null("VBox/TimerBar")
	var btn: Button = panel.get_node_or_null("VBox/CallBtn")

	var next_n := 1
	if wm.has_method("get_next_wave_number"):
		next_n = int(wm.call("get_next_wave_number"))
	var kind_id := "thrall"
	if wm.has_method("get_next_kind_id"):
		kind_id = str(wm.call("get_next_kind_id"))
	elif wm.has_method("get_wave_kind"):
		kind_id = str(wm.call("get_wave_kind"))

	var d: Dictionary = {}
	if EnemyKinds:
		d = EnemyKinds.def_for(kind_id)
	var col: Color = d.get("color", Color(0.75, 0.5, 0.9)) as Color
	var nname: String = str(d.get("name", kind_id))
	var short: String = str(d.get("short", ""))
	var hint: String = ""
	if EnemyKinds and EnemyKinds.has_method("matchup_hint"):
		hint = str(EnemyKinds.matchup_hint(kind_id))

	if title:
		if prep:
			title.text = "NEXT SURGE  ·  WAVE %d" % next_n
		else:
			title.text = "SURGE ACTIVE  ·  WAVE %d" % next_n
	var flying := bool(d.get("flying", false))
	if kind_name:
		var tag := short
		if flying and short != "FLYER" and short != "WRAITH":
			tag = "AIR · %s" % short if short != "" else "AIR"
		elif flying and short == "":
			tag = "AIR"
		kind_name.text = nname if tag == "" else "%s  [%s]" % [nname, tag]
		kind_name.add_theme_color_override("font_color", col.lightened(0.25))
	if kind_hint:
		var base_hint := hint if prep else str(d.get("blurb", ""))
		if flying:
			kind_hint.text = "✈ FLYING — ground towers miss  ·  " + base_hint
		else:
			kind_hint.text = base_hint
	if swatch:
		swatch.color = col

	var secs := 0.0
	var ratio := 0.0
	if wm.has_method("get_prep_seconds"):
		secs = float(wm.call("get_prep_seconds"))
	if wm.has_method("get_prep_ratio"):
		ratio = float(wm.call("get_prep_ratio"))

	if timer_lab:
		if prep:
			timer_lab.text = "Arrives in  %.0f s" % ceilf(secs)
			timer_lab.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
		else:
			timer_lab.text = "Enemies on the path"
			timer_lab.add_theme_color_override("font_color", Color(0.95, 0.45, 0.4))
	if bar:
		bar.visible = prep
		if prep:
			bar.value = ratio
			var fill := bar.get_theme_stylebox("fill")
			if fill is StyleBoxFlat:
				var f2 := (fill as StyleBoxFlat).duplicate() as StyleBoxFlat
				# Shift amber → red as time runs out
				f2.bg_color = Color(0.85, 0.55, 0.25).lerp(Color(0.95, 0.3, 0.35), 1.0 - ratio)
				bar.add_theme_stylebox_override("fill", f2)

	if btn:
		if prep:
			var bonus := 0
			if wm.has_method("preview_early_bonus"):
				bonus = int(wm.call("preview_early_bonus"))
			btn.visible = true
			btn.disabled = false
			btn.text = "⚔ CALL EARLY  +%d✦  (T)" % bonus
		else:
			btn.visible = true
			btn.disabled = true
			btn.text = "⚔ FIGHTING…"


func _on_essence(v: int) -> void:
	essence_label.text = "💰 %d" % v


func _on_dust(v: int) -> void:
	var fc := 0
	var fmax := 6
	if GameState:
		if GameState.has_method("fairy_count"):
			fc = GameState.fairy_count()
		fmax = GameState.FAIRY_MAX
	dust_label.text = "✦ %d · ✧%d/%d" % [v, fc, fmax]


func _on_crystal(cur: int, mx: int) -> void:
	# Clean KR lives — number, not a wall of hearts
	crystal_label.text = "♥  %d / %d" % [cur, mx]
	crystal_label.add_theme_color_override(
		"font_color",
		Color(0.95, 0.35, 0.4) if cur <= 5 else Color(0.95, 0.72, 0.75)
	)


func _on_wave(w: int, total: int) -> void:
	wave_label.text = "Wave  %d / %d" % [w, total]


func _on_message(text: String) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	if _msg_tween and _msg_tween.is_valid():
		_msg_tween.kill()
	_msg_tween = create_tween()
	_msg_tween.tween_interval(1.8)
	_msg_tween.tween_property(message_label, "modulate:a", 0.0, 0.7)


func _process(_delta: float) -> void:
	if dust_label and GameState and not _paused:
		_on_dust(GameState.crystal_dust)
	_update_burst_hud()
	# Smooth timer bar during prep
	if has_node("Root/WavePrep") and not _paused:
		_refresh_wave_prep()


func _ensure_burst_hud() -> void:
	if has_node("Root/BurstHud"):
		return
	var box := HBoxContainer.new()
	box.name = "BurstHud"
	box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	box.offset_left = 16.0
	box.offset_top = -56.0
	box.offset_right = 420.0
	box.offset_bottom = -16.0
	box.add_theme_constant_override("separation", 12)
	$Root.add_child(box)
	for id in ["sprint", "sky", "dire"]:
		var lab := Label.new()
		lab.name = id
		lab.add_theme_font_size_override("font_size", 13)
		lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lab.add_theme_constant_override("outline_size", 3)
		box.add_child(lab)


func _update_burst_hud() -> void:
	if not has_node("Root/BurstHud"):
		return
	var warden: Node = null
	if GameState and GameState.wardens.size() > 0:
		warden = GameState.wardens[0]
	if warden == null or not warden.has_method("get_burst_status"):
		return
	var st: Dictionary = warden.call("get_burst_status")
	var box: HBoxContainer = $Root/BurstHud
	_set_burst_label(box.get_node_or_null("sprint"), "1 Rush", st.get("sprint_t", 0.0), st.get("sprint_cd", 0.0), Color(1.0, 0.85, 0.3))
	_set_burst_label(box.get_node_or_null("sky"), "2 Sky", st.get("sky_t", 0.0), st.get("sky_cd", 0.0), Color(0.6, 0.85, 1.0))
	_set_burst_label(box.get_node_or_null("dire"), "3 Dire", 0.0, st.get("dire_cd", 0.0), Color(1.0, 0.4, 0.35))


func _set_burst_label(lab: Label, title: String, active_t: float, cd: float, col: Color) -> void:
	if lab == null:
		return
	if active_t > 0.0:
		lab.text = "%s %.1fs" % [title, active_t]
		lab.add_theme_color_override("font_color", col)
	elif cd > 0.0:
		lab.text = "%s CD %.0f" % [title, cd]
		lab.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	else:
		lab.text = "%s READY" % title
		lab.add_theme_color_override("font_color", col.lightened(0.2))


func _on_game_over(won: bool) -> void:
	_resume_if_needed()
	end_panel.visible = true
	if won:
		var star_s := ""
		for i in GameState.stars:
			star_s += "★"
		while star_s.length() < 3:
			star_s += "☆"
		end_label.text = "VICTORY\n%s\nThe Crystal endures\n%d killed · %d leaked\n\nR retry · Enter map select" % [
			star_s, GameState.enemies_killed, GameState.enemies_leaked
		]
		end_label.modulate = Color(1.0, 0.9, 0.45)
	else:
		end_label.text = "DEFEAT\nThe light is gone\nWave %d\n\nR retry · Enter map select" % GameState.current_wave
		end_label.modulate = Color(0.95, 0.4, 0.45)
