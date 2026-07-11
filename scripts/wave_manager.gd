extends Node
## Spawns nightspawn surges toward the crystal.

@export var enemy_scene: PackedScene
@export var spawn_point_paths: Array[NodePath] = []
@export var calm_between_waves: float = 6.0
@export var first_wave_delay: float = 3.0

enum Phase { WAIT_FIRST, SPAWNING, IN_WAVE, CALM, DONE }

var _wave: int = 0
var _phase: Phase = Phase.WAIT_FIRST
var _timer: float = 0.0
var _to_spawn: int = 0
var _spawn_cd: float = 0.0
var _spawn_points: Array[Marker2D] = []


func _ready() -> void:
	refresh_spawn_points()
	_timer = first_wave_delay
	_phase = Phase.WAIT_FIRST


## Collect markers from export paths plus all Marker2D under ../Spawns (large map).
func refresh_spawn_points() -> void:
	_spawn_points.clear()
	var seen: Dictionary = {}
	for p in spawn_point_paths:
		var n := get_node_or_null(p)
		if n is Marker2D and not seen.has(n):
			_spawn_points.append(n)
			seen[n] = true
	var spawns_root := get_node_or_null("../Spawns")
	if spawns_root:
		for c in spawns_root.get_children():
			if c is Marker2D and not seen.has(c):
				_spawn_points.append(c)
				seen[c] = true
	print("WaveManager spawn points: ", _spawn_points.size())


func _process(delta: float) -> void:
	if GameState.is_game_over:
		return

	match _phase:
		Phase.WAIT_FIRST:
			_timer -= delta
			if _timer <= 0.0:
				_begin_wave()
		Phase.SPAWNING:
			_spawn_cd -= delta
			if _spawn_cd <= 0.0 and _to_spawn > 0:
				_spawn_one()
				_to_spawn -= 1
				_spawn_cd = 0.32
			if _to_spawn <= 0:
				_phase = Phase.IN_WAVE
		Phase.IN_WAVE:
			if get_tree().get_nodes_in_group("enemies").is_empty():
				GameState.notify_wave_cleared()
				if GameState.is_game_over:
					_phase = Phase.DONE
				elif _wave >= GameState.waves_to_win:
					_phase = Phase.DONE
				else:
					_phase = Phase.CALM
					_timer = calm_between_waves
					GameState.message.emit("Surge cleared — next in %ds" % int(calm_between_waves))
		Phase.CALM:
			_timer -= delta
			if _timer <= 0.0:
				_begin_wave()
		Phase.DONE:
			pass


func _begin_wave() -> void:
	_wave += 1
	if _wave > GameState.waves_to_win:
		_phase = Phase.DONE
		return
	GameState.set_wave(_wave)
	GameState.message.emit("Surge %d approaches!" % _wave)
	# Slightly more enemies on the bigger map
	_to_spawn = 6 + _wave * 4
	_spawn_cd = 0.0
	_phase = Phase.SPAWNING


func _spawn_one() -> void:
	if enemy_scene == null:
		return
	if _spawn_points.is_empty():
		refresh_spawn_points()
	if _spawn_points.is_empty():
		return
	var marker: Marker2D = _spawn_points[randi() % _spawn_points.size()]
	var e: Node2D = enemy_scene.instantiate() as Node2D
	if e == null:
		return
	# Scale difficulty before enter tree so enemy._ready() picks up max_hp.
	e.set("max_hp", 30 + _wave * 8)
	e.set("move_speed", 55.0 + _wave * 6.0)
	get_parent().add_child(e)
	e.global_position = marker.global_position + Vector2(randf_range(-36, 36), randf_range(-36, 36))
