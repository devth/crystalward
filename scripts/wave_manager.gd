extends Node
## Kingdom Rush–style wave cadence: prep timer, call-early bonus, lane spawns.

@export var enemy_scene: PackedScene
@export var spawn_point_paths: Array[NodePath] = []
@export var calm_between_waves: float = 12.0
@export var first_wave_delay: float = 8.0

enum Phase { WAIT_FIRST, SPAWNING, IN_WAVE, CALM, DONE }

var _wave: int = 0
var _phase: Phase = Phase.WAIT_FIRST
var _timer: float = 0.0
var _to_spawn: int = 0
var _spawn_cd: float = 0.0
var _elites_left: int = 0
var _can_call_early: bool = false


func _ready() -> void:
	add_to_group("wave_manager")
	_timer = first_wave_delay
	_phase = Phase.WAIT_FIRST
	_can_call_early = true
	GameState.message.emit("Build your defenses — Call next surge early for bonus Essence!")
	GameState.wave_phase_changed.emit("prep", _timer)


func refresh_spawn_points() -> void:
	pass


func can_call_early() -> bool:
	return _can_call_early and not GameState.is_game_over and (_phase == Phase.WAIT_FIRST or _phase == Phase.CALM)


func call_early_wave() -> bool:
	if not can_call_early():
		return false
	var bonus := GameState.EARLY_WAVE_BONUS + int(_timer)  # more time left = more gold, KR-style
	bonus = mini(bonus, 25)
	GameState.add_essence(bonus)
	GameState.message.emit("Early surge! +%d Essence" % bonus)
	if Juice:
		Juice.flash(Color(1.0, 0.85, 0.3, 0.3), 0.15)
	_can_call_early = false
	_timer = 0.0
	if _phase == Phase.WAIT_FIRST or _phase == Phase.CALM:
		_begin_wave()
	return true


func get_prep_seconds() -> float:
	if _phase == Phase.WAIT_FIRST or _phase == Phase.CALM:
		return maxf(0.0, _timer)
	return 0.0


func get_phase_name() -> String:
	match _phase:
		Phase.WAIT_FIRST, Phase.CALM:
			return "prep"
		Phase.SPAWNING, Phase.IN_WAVE:
			return "combat"
		_:
			return "done"


func _process(delta: float) -> void:
	if GameState.is_game_over:
		return

	match _phase:
		Phase.WAIT_FIRST:
			_timer -= delta
			_can_call_early = true
			GameState.wave_phase_changed.emit("prep", maxf(0.0, _timer))
			if _timer <= 0.0:
				_can_call_early = false
				_begin_wave()
		Phase.SPAWNING:
			_can_call_early = false
			_spawn_cd -= delta
			if _spawn_cd <= 0.0 and _to_spawn > 0:
				var elite := false
				if _elites_left > 0 and (_to_spawn == 1 or randf() < 0.12):
					elite = true
					_elites_left -= 1
				_spawn_one(elite)
				_to_spawn -= 1
				_spawn_cd = maxf(0.14, 0.34 - _wave * 0.02)
			if _to_spawn <= 0:
				_phase = Phase.IN_WAVE
				GameState.wave_phase_changed.emit("combat", 0.0)
		Phase.IN_WAVE:
			_can_call_early = false
			if get_tree().get_nodes_in_group("enemies").is_empty():
				GameState.notify_wave_cleared()
				if GameState.is_game_over:
					_phase = Phase.DONE
				elif _wave >= GameState.waves_to_win:
					_phase = Phase.DONE
				else:
					_phase = Phase.CALM
					_timer = calm_between_waves
					_can_call_early = true
					GameState.message.emit("Wave clear! Fortify — next in %ds (or Call Early)" % int(calm_between_waves))
					GameState.wave_phase_changed.emit("prep", _timer)
		Phase.CALM:
			_timer -= delta
			_can_call_early = true
			GameState.wave_phase_changed.emit("prep", maxf(0.0, _timer))
			if _timer <= 0.0:
				_can_call_early = false
				_begin_wave()
		Phase.DONE:
			_can_call_early = false


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
	GameState.message.emit("⚔ SURGE %d — %s" % [_wave, label])
	if Sfx:
		Sfx.wave_start()
	if Juice:
		Juice.flash(Color(0.95, 0.4, 0.25, 0.28), 0.22)
		Juice.shake(5.0)

	_to_spawn = 8 + _wave * 5
	_elites_left = 1 if _wave >= 2 else 0
	if _wave >= 4:
		_elites_left = 2
	if _wave >= 6:
		_elites_left = 3
	_spawn_cd = 0.0
	_phase = Phase.SPAWNING
	_can_call_early = false
	GameState.wave_phase_changed.emit("combat", 0.0)


func _spawn_one(elite: bool = false) -> void:
	if enemy_scene == null:
		return
	var lane: PackedVector2Array = PathNetwork.random_lane() if PathNetwork else PackedVector2Array()
	var e: Node2D = enemy_scene.instantiate() as Node2D
	if e == null:
		return
	e.set("max_hp", 28 + _wave * 10)
	e.set("move_speed", 52.0 + _wave * 5.5)
	e.set("crystal_damage", 8)  # lives-style leak
	get_parent().add_child(e)
	if e.has_method("assign_lane") and lane.size() > 0:
		e.call("assign_lane", lane)
	if elite and e.has_method("make_elite"):
		e.call("make_elite")
		GameState.message.emit("⚠ Elite on the path!")
