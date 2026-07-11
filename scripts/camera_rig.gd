extends Camera2D
## Free-explore camera: pans with wardens across the map.
## No crystal leash — you walk, the camera follows.

@export var follow_speed: float = 7.5
@export var crystal_path: NodePath
@export var world_bound: float = 1800.0
@export var look_ahead: float = 90.0  ## pan slightly in move direction
@export var zoom_min: float = 0.62
@export var zoom_max: float = 0.95
@export var base_zoom: float = 0.82

var _crystal: Node2D
var _zoom_target: float = 0.72
var _smoothed_target: Vector2 = Vector2.ZERO
var _has_target: bool = false


func _ready() -> void:
	if crystal_path:
		_crystal = get_node_or_null(crystal_path) as Node2D
	position_smoothing_enabled = false
	_zoom_target = base_zoom
	zoom = Vector2(base_zoom, base_zoom)
	if Juice:
		Juice.bind_camera(self)


func _process(delta: float) -> void:
	var wardens := _follow_targets()
	var target := global_position
	var spread := 0.0
	var lead := Vector2.ZERO

	if wardens.is_empty():
		if _crystal:
			target = _crystal.global_position
	else:
		var sum := Vector2.ZERO
		var vel_sum := Vector2.ZERO
		var n := 0
		for w in wardens:
			sum += w.global_position
			n += 1
			if w is CharacterBody2D:
				vel_sum += (w as CharacterBody2D).velocity
		target = sum / float(n)
		# Look ahead in travel direction so exploring feels open
		if vel_sum.length() > 40.0:
			lead = vel_sum.normalized() * look_ahead
		target += lead
		for w in wardens:
			spread = maxf(spread, w.global_position.distance_to(sum / float(n)))

	# Dynamic zoom: pull out when players split or map is busy
	var enemy_n := 0
	if get_tree():
		enemy_n = get_tree().get_nodes_in_group("enemies").size()
	var zoom_from_spread := base_zoom - clampf(spread / 800.0, 0.0, 0.22)
	var zoom_from_enemies := clampf(enemy_n * 0.003, 0.0, 0.1)
	_zoom_target = clampf(zoom_from_spread - zoom_from_enemies, zoom_min, zoom_max)
	var z := lerpf(zoom.x, _zoom_target, 1.0 - exp(-3.2 * delta))
	zoom = Vector2(z, z)

	# Soft world clamp so we can explore to the map edge without showing void forever
	var margin := 220.0 / maxf(0.35, zoom.x)
	var bound := world_bound - margin * 0.25
	target = GameState.clamp_world_position(target, bound) if GameState else target

	if not _has_target:
		_smoothed_target = target
		global_position = target
		_has_target = true
	else:
		# Smooth pan that keeps up while exploring
		var t := 1.0 - exp(-follow_speed * delta)
		_smoothed_target = _smoothed_target.lerp(target, t)
		global_position = _smoothed_target


func _follow_targets() -> Array[Node2D]:
	var out: Array[Node2D] = []
	if GameState:
		for w in GameState.wardens:
			if is_instance_valid(w) and w.is_inside_tree():
				out.append(w)
	# Fallback: group scan if registry was wiped mid-match
	if out.is_empty() and get_tree():
		for n in get_tree().get_nodes_in_group("wardens"):
			if n is Node2D and is_instance_valid(n):
				out.append(n as Node2D)
	return out
