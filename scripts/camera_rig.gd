extends Camera2D
## Centroid follow of wardens; soft bias toward crystal; large roam radius.

@export var follow_speed: float = 4.0
@export var crystal_path: NodePath
@export var crystal_pull: float = 0.08
@export var max_distance_from_crystal: float = 1400.0
@export var world_bound: float = 1800.0

var _crystal: Node2D


func _ready() -> void:
	if crystal_path:
		_crystal = get_node_or_null(crystal_path) as Node2D
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed


func _process(delta: float) -> void:
	var wardens := GameState.wardens
	var target := global_position
	if wardens.is_empty():
		if _crystal:
			target = _crystal.global_position
	else:
		var sum := Vector2.ZERO
		var n := 0
		for w in wardens:
			if is_instance_valid(w):
				sum += w.global_position
				n += 1
		if n > 0:
			target = sum / float(n)
		if _crystal:
			target = target.lerp(_crystal.global_position, crystal_pull)
			var to_c := target - _crystal.global_position
			if to_c.length() > max_distance_from_crystal:
				target = _crystal.global_position + to_c.normalized() * max_distance_from_crystal

	# Soft world clamp so the camera stays on the ritual forest.
	target = Vector2(
		clampf(target.x, -world_bound, world_bound),
		clampf(target.y, -world_bound, world_bound)
	)
	global_position = global_position.lerp(target, 1.0 - exp(-follow_speed * delta))
