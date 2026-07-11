extends CanvasLayer
## Shared bank, crystal, wave, messages, controls help.

@onready var essence_label: Label = $Root/Top/Essence
@onready var dust_label: Label = $Root/Top/Dust
@onready var crystal_label: Label = $Root/Top/Crystal
@onready var wave_label: Label = $Root/Top/Wave
@onready var message_label: Label = $Root/Message
@onready var end_panel: PanelContainer = $Root/EndPanel
@onready var end_label: Label = $Root/EndPanel/VBox/EndText
@onready var help_label: Label = $Root/Help


func _ready() -> void:
	GameState.essence_changed.connect(_on_essence)
	GameState.crystal_dust_changed.connect(_on_dust)
	GameState.crystal_hp_changed.connect(_on_crystal)
	GameState.wave_changed.connect(_on_wave)
	GameState.game_over.connect(_on_game_over)
	GameState.message.connect(_on_message)
	end_panel.visible = false
	_on_essence(GameState.essence)
	_on_dust(GameState.crystal_dust)
	_on_crystal(GameState.crystal_hp, GameState.crystal_max_hp)
	_on_wave(GameState.current_wave, GameState.waves_to_win)
	help_label.text = "P1: WASD move · E gather · Q build · Space attack\nP2: Arrows · . gather · , build · / attack · R restart"


func _on_essence(v: int) -> void:
	essence_label.text = "Essence: %d" % v


func _on_dust(v: int) -> void:
	dust_label.text = "Crystal dust: %d" % v


func _on_crystal(cur: int, mx: int) -> void:
	crystal_label.text = "Crystal: %d/%d" % [cur, mx]


func _on_wave(w: int, total: int) -> void:
	wave_label.text = "Surge: %d/%d" % [w, total]


func _on_message(text: String) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(message_label, "modulate:a", 0.0, 0.6)


func _on_game_over(won: bool) -> void:
	end_panel.visible = true
	end_label.text = "VICTORY\nThe Crystal endures" if won else "DEFEAT\nThe light is gone"
	end_label.modulate = Color(0.95, 0.85, 0.4) if won else Color(0.9, 0.35, 0.4)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		GameState.reset()
		get_tree().reload_current_scene()
