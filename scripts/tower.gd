extends Node2D
class_name DefenseTower
## Auto-fires at nearest nightspawn in range.

@export var fire_range: float = 160.0
@export var fire_rate: float = 0.55
@export var damage: int = 14

var _cd: float = 0.0

func _ready() -> void:
	add_to_group("towers")
	z_index = int(global_position.y)
	if has_node("RangeHint"):
		($RangeHint as CanvasItem).modulate.a = 0.12


func _process(delta: float) -> void:
	if GameState.is_game_over:
		return
	_cd = maxf(0.0, _cd - delta)
	if _cd > 0.0:
		return
	var target := _find_target()
	if target:
		_cd = fire_rate
		if target.has_method("take_damage"):
			target.take_damage(damage)
		_muzzle_flash(target.global_position)


func _find_target() -> Node2D:
	var best: Node2D = null
	var best_d := fire_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D:
			var d: float = global_position.distance_to(e.global_position)
			if d < best_d:
				best_d = d
				best = e
	return best


func _muzzle_flash(to: Vector2) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(0.95, 0.85, 0.4, 0.9)
	line.points = PackedVector2Array([Vector2.ZERO, to - global_position])
	line.z_index = 100
	add_child(line)
	var tw := create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.12)
	tw.tween_callback(line.queue_free)
