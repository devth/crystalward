extends Camera2D
## Centroid follow of wardens; roam-friendly; dynamic zoom; juice offset safe.

@export var follow_speed: float = 5.5
@export var crystal_path: NodePath
@export var crystal_pull: float = 0.06
@export var max_distance_from_crystal: float = 1500.0
@export var world_bound: float = 1800.0
@export var zoom_min: float = 0.55
@export var zoom_max: float = 0.85
@export var base_zoom: float = 0.7

var _crystal: Node2D
var _zoom_target: float = 0.7


func _ready() -> void:
	if crystal_path:
		_crystal = get_node_or_null(crystal_path) as Node2D
	position_smoothing_enabled = false
	_zoom_target = base_zoom
	zoom = Vector2(base_zoom, base_zoom)
	if Juice:
		Juice.bind_camera(self)


func _process(delta: float) -> void:
	var wardens := GameState.wardens
	var target := global_position
	var spread := 0.0

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
		# Spread for zoom
		for w in wardens:
			if is_instance_valid(w):
				spread = maxf(spread, w.global_position.distance_to(target))
		if _crystal:
			target = target.lerp(_crystal.global_position, crystal_pull)
			var to_c := target - _crystal.global_position
			if to_c.length() > max_distance_from_crystal:
				target = _crystal.global_position + to_c.normalized() * max_distance_from_crystal

	# Enemy activity pulls zoom out slightly
	var enemy_n := 0
	if get_tree():
		enemy_n = get_tree().get_nodes_in_group("enemies").size()
	var zoom_from_spread := base_zoom - clampf(spread / 900.0, 0.0, 0.2)
	var zoom_from_enemies := clampf(enemy_n * 0.004, 0.0, 0.12)
	_zoom_target = clampf(zoom_from_spread - zoom_from_enemies, zoom_min, zoom_max)
	var z := lerpf(zoom.x, _zoom_target, 1.0 - exp(-3.0 * delta))
	zoom = Vector2(z, z)

	target = GameState.clamp_world_position(target, world_bound)
	global_position = global_position.lerp(target, 1.0 - exp(-follow_speed * delta))
