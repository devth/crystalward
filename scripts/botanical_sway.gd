extends Node
## Gentle wind sway for botanical props (Legend forest breeze).
## Only rotates the parent — never rewrites scale (sprites keep intentional scale).

var _phase: float = 0.0
var _speed: float = 1.2
var _amp: float = 0.06


func _ready() -> void:
	var p := get_parent()
	if p and p.has_meta("sway_phase"):
		_phase = float(p.get_meta("sway_phase"))
	else:
		_phase = randf() * TAU
	_speed = randf_range(0.9, 1.6)
	_amp = randf_range(0.04, 0.09)


func _process(delta: float) -> void:
	_phase += delta * _speed
	var p := get_parent() as Node2D
	if p == null:
		return
	# Rotation only — do not touch scale (would break make_pixel_sprite / flower sc).
	p.rotation = sin(_phase) * _amp
