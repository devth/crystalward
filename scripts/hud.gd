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
	hint_label.text = "F fairy · loot auto · walk-over pickups · Z/X towers · Q build · T wave"
	_ensure_minimap()
	_ensure_call_wave_ui()


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


func _ensure_call_wave_ui() -> void:
	if has_node("Root/CallWaveBtn"):
		return
	var btn := Button.new()
	btn.name = "CallWaveBtn"
	btn.text = "⚔ CALL WAVE  (T)"
	btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	btn.offset_left = -120.0
	btn.offset_top = -72.0
	btn.offset_right = 120.0
	btn.offset_bottom = -36.0
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(_on_call_wave_pressed)
	$Root.add_child(btn)


func _on_call_wave_pressed() -> void:
	var wm := get_tree().get_first_node_in_group("wave_manager")
	if wm and wm.has_method("call_early_wave"):
		wm.call("call_early_wave")


func _on_wave_phase(phase: String, seconds_left: float) -> void:
	if not has_node("Root/CallWaveBtn"):
		return
	var btn: Button = $Root/CallWaveBtn
	if phase == "prep":
		btn.visible = true
		btn.text = "⚔ CALL WAVE +gold  (%.0fs)" % seconds_left
		btn.disabled = false
	else:
		btn.text = "⚔ WAVE INCOMING"
		btn.disabled = true


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
	# KR-style lives
	var hearts := ""
	for i in mini(cur, 20):
		hearts += "♥"
	if cur > 20:
		hearts += "+%d" % (cur - 20)
	crystal_label.text = "Lives %s" % (hearts if cur > 0 else "☠")
	crystal_label.add_theme_color_override("font_color", Color(0.95, 0.35, 0.4) if cur <= 5 else Color(0.95, 0.55, 0.6))


func _on_wave(w: int, total: int) -> void:
	wave_label.text = "Wave  %d/%d" % [w, total]


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
