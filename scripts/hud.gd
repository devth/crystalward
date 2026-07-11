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
	_on_essence(GameState.essence)
	_on_dust(GameState.crystal_dust)
	_on_crystal(GameState.crystal_hp, GameState.crystal_max_hp)
	_on_wave(GameState.current_wave, GameState.waves_to_win)
	hint_label.text = "Esc / Start — Pause & Controls · Paths glow — nightspawn march them"
	_ensure_minimap()


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


func _on_essence(v: int) -> void:
	essence_label.text = "Essence  %d" % v


func _on_dust(v: int) -> void:
	dust_label.text = "Dust  %d" % v


func _on_crystal(cur: int, mx: int) -> void:
	crystal_label.text = "Crystal  %d/%d" % [cur, mx]


func _on_wave(w: int, total: int) -> void:
	wave_label.text = "Surge  %d/%d" % [w, total]


func _on_message(text: String) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	if _msg_tween and _msg_tween.is_valid():
		_msg_tween.kill()
	_msg_tween = create_tween()
	_msg_tween.tween_interval(1.8)
	_msg_tween.tween_property(message_label, "modulate:a", 0.0, 0.7)


func _on_game_over(won: bool) -> void:
	_resume_if_needed()
	end_panel.visible = true
	end_label.text = "VICTORY\nThe Crystal endures" if won else "DEFEAT\nThe light is gone"
	end_label.modulate = Color(0.85, 0.75, 1.0) if won else Color(0.95, 0.4, 0.45)
