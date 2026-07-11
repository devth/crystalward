extends Node2D
## Lightwell / Crystal — shared lose condition.

@onready var _hp_bar: ProgressBar = $HpBar
@onready var _glow: Polygon2D = $Glow


func _ready() -> void:
	add_to_group("crystal")
	GameState.crystal_hp_changed.connect(_on_hp)
	_on_hp(GameState.crystal_hp, GameState.crystal_max_hp)
	z_index = int(global_position.y)


func _process(_delta: float) -> void:
	_glow.modulate.a = 0.55 + 0.25 * sin(Time.get_ticks_msec() * 0.004)


func _on_hp(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	var t := float(current) / float(maxi(1, maximum))
	_glow.color = Color(0.95, 0.75, 0.25).lerp(Color(0.6, 0.1, 0.2), 1.0 - t)


func get_hurtbox_position() -> Vector2:
	return global_position
