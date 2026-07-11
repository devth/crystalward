extends Node
## Spawns nightspawn along PathNetwork lanes in surges.

@export var enemy_scene: PackedScene
@export var spawn_point_paths: Array[NodePath] = []
@export var calm_between_waves: float = 7.0
@export var first_wave_delay: float = 5.0

enum Phase { WAIT_FIRST, SPAWNING, IN_WAVE, CALM, DONE }

var _wave: int = 0
var _phase: Phase = Phase.WAIT_FIRST
var _timer: float = 0.0
var _to_spawn: int = 0
var _spawn_cd: float = 0.0
var _elites_left: int = 0


func _ready() -> void:
	_timer = first_wave_delay
	_phase = Phase.WAIT_FIRST
	GameState.message.emit("Wardens — gather Essence. The soft dark gathers…")


func refresh_spawn_points() -> void:
	# Lanes are authoritative now; markers optional fallback.
	pass


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
				var elite := false
				if _elites_left > 0 and (_to_spawn == 1 or randf() < 0.12):
					elite = true
					_elites_left -= 1
				_spawn_one(elite)
				_to_spawn -= 1
				_spawn_cd = maxf(0.16, 0.36 - _wave * 0.02)
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
					GameState.message.emit("Surge cleared — fortify. Next in %ds" % int(calm_between_waves))
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
	var names := [
		"Thrall Tide", "Iron Procession", "Wild Hunt", "Soft Dark",
		"Winged Blight", "Lieutenant's Host", "Conjunction Eve", "Dawn's Last Stand"
	]
	var label: String = names[mini(_wave - 1, names.size() - 1)]
	GameState.message.emit("Surge %d — %s" % [_wave, label])
	if Sfx:
		Sfx.wave_start()
	if Juice:
		Juice.flash(Color(0.4, 0.2, 0.55, 0.25), 0.2)
		Juice.shake(4.0)

	_to_spawn = 8 + _wave * 5
	_elites_left = 1 if _wave >= 2 else 0
	if _wave >= 4:
		_elites_left = 2
	if _wave >= 6:
		_elites_left = 3
	_spawn_cd = 0.0
	_phase = Phase.SPAWNING


func _spawn_one(elite: bool = false) -> void:
	if enemy_scene == null:
		return
	var lane: PackedVector2Array = PathNetwork.random_lane() if PathNetwork else PackedVector2Array()
	var e: Node2D = enemy_scene.instantiate() as Node2D
	if e == null:
		return
	e.set("max_hp", 28 + _wave * 10)
	e.set("move_speed", 52.0 + _wave * 5.5)
	e.set("crystal_damage", 6 + _wave)
	if e.has_method("assign_lane") and lane.size() > 0:
		# assign before ready by setting property then calling after add
		pass
	get_parent().add_child(e)
	if e.has_method("assign_lane") and lane.size() > 0:
		e.call("assign_lane", lane)
	if elite and e.has_method("make_elite"):
		e.call("make_elite")
		GameState.message.emit("An Elite walks the path…")
