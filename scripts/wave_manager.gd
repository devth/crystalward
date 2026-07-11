extends Node
## Kingdom Rush–style wave cadence: one enemy kind per surge, spaced packs.

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
var _wave_kind: String = "thrall"
var _spawn_spacing: float = 0.9
var _prep_total: float = 8.0  ## full prep duration for UI bar (1.0 → 0.0)


func _ready() -> void:
	add_to_group("wave_manager")
	_timer = first_wave_delay
	_prep_total = maxf(0.1, first_wave_delay)
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
	var bonus := preview_early_bonus()
	GameState.add_essence(bonus)
	GameState.message.emit("Early surge! +%d Essence" % bonus)
	if Juice:
		Juice.flash(Color(1.0, 0.85, 0.3, 0.3), 0.15)
	_can_call_early = false
	_timer = 0.0
	if _phase == Phase.WAIT_FIRST or _phase == Phase.CALM:
		_begin_wave()
	return true


func preview_early_bonus() -> int:
	## KR-style: more time left = more gold
	if not can_call_early():
		return 0
	var bonus := GameState.EARLY_WAVE_BONUS + int(_timer)
	return mini(bonus, 25)


func get_prep_seconds() -> float:
	if _phase == Phase.WAIT_FIRST or _phase == Phase.CALM:
		return maxf(0.0, _timer)
	return 0.0


func get_prep_total() -> float:
	return maxf(0.1, _prep_total)


func get_prep_ratio() -> float:
	## 1.0 at start of prep → 0.0 when wave fires
	if _phase != Phase.WAIT_FIRST and _phase != Phase.CALM:
		return 0.0
	return clampf(_timer / get_prep_total(), 0.0, 1.0)


func get_phase_name() -> String:
	match _phase:
		Phase.WAIT_FIRST, Phase.CALM:
			return "prep"
		Phase.SPAWNING, Phase.IN_WAVE:
			return "combat"
		_:
			return "done"


func get_wave_kind() -> String:
	return _wave_kind


func get_next_wave_number() -> int:
	## Wave that will start when prep ends (or current if already fighting).
	if _phase == Phase.WAIT_FIRST or _phase == Phase.CALM:
		return _wave + 1
	return _wave


func get_next_kind_id() -> String:
	if EnemyKinds == null:
		return _wave_kind
	if _phase == Phase.WAIT_FIRST or _phase == Phase.CALM:
		return EnemyKinds.kind_for_wave(_wave + 1)
	return _wave_kind


func is_prep() -> bool:
	return _phase == Phase.WAIT_FIRST or _phase == Phase.CALM


func is_done() -> bool:
	return _phase == Phase.DONE


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
				if _elites_left > 0 and (_to_spawn == 1 or randf() < 0.1):
					elite = true
					_elites_left -= 1
				_spawn_one(elite)
				_to_spawn -= 1
				_spawn_cd = _spawn_spacing
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
					_prep_total = maxf(0.1, calm_between_waves)
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
	if TowerTypes and TowerTypes.has_method("on_wave_started"):
		TowerTypes.on_wave_started(_wave)

	# One kind per surge
	_wave_kind = EnemyKinds.kind_for_wave(_wave) if EnemyKinds else "thrall"
	var kind_def: Dictionary = EnemyKinds.def_for(_wave_kind) if EnemyKinds else {}
	_spawn_spacing = float(kind_def.get("spawn_spacing", 0.9))

	var map := _map_def()
	var kind_name: String = str(kind_def.get("name", "Nightspawn"))
	var hint: String = EnemyKinds.matchup_hint(_wave_kind) if EnemyKinds else ""
	GameState.message.emit("⚔ SURGE %d — %s" % [_wave, kind_name])
	if hint != "":
		# Brief matchup tip so players know which towers to lean on
		GameState.message.emit(hint)
	if Sfx:
		Sfx.wave_start()
	if Juice:
		var col: Color = kind_def.get("color", Color(0.95, 0.4, 0.25)) as Color
		Juice.flash(Color(col.r, col.g, col.b, 0.28), 0.22)
		Juice.shake(3.0 if int(map.get("difficulty", 3)) <= 1 else 5.0)

	var count_scale := float(map.get("enemy_count_scale", 1.0))
	var base_count := 5 + _wave * 3
	_to_spawn = maxi(3, int(round(float(base_count) * count_scale)))
	# Fewer units for brutes so they don't still blob
	if float(kind_def.get("hp_mult", 1.0)) > 1.4:
		_to_spawn = maxi(3, int(round(float(_to_spawn) * 0.75)))

	if map.get("elites", true) == false or int(map.get("difficulty", 3)) <= 1:
		_elites_left = 0
	else:
		_elites_left = 0
		if _wave >= 3:
			_elites_left = 1
		if _wave >= 6:
			_elites_left = 2

	# Map difficulty stretches spacing slightly
	if count_scale < 0.7:
		_spawn_spacing = maxf(_spawn_spacing, 1.0)
	_spawn_cd = 0.15
	_phase = Phase.SPAWNING
	_can_call_early = false
	GameState.wave_phase_changed.emit("combat", 0.0)


func _map_def() -> Dictionary:
	if Campaign:
		return Campaign.get_map(Campaign.selected_map_id)
	return {}


func _spawn_one(elite: bool = false) -> void:
	if enemy_scene == null:
		return
	if PathNetwork and PathNetwork.lane_count() == 0:
		PathNetwork.rebuild(PathNetwork.active_lane_set)
	var map := _map_def()
	var lane: PackedVector2Array = PathNetwork.random_lane() if PathNetwork else PackedVector2Array()
	var e: Node2D = enemy_scene.instantiate() as Node2D
	if e == null:
		return
	var hp_s := float(map.get("enemy_hp_scale", 1.0))
	var spd_s := float(map.get("enemy_speed_scale", 1.0))
	var base_hp := maxi(12, int((26 + _wave * 7) * hp_s))
	var base_spd := maxf(28.0, (48.0 + _wave * 3.8) * spd_s)
	# Configure kind BEFORE add_child so _ready builds correct visuals
	if e.has_method("configure_kind"):
		e.call("configure_kind", _wave_kind, base_hp, base_spd)
	else:
		e.set("max_hp", base_hp)
		e.set("move_speed", base_spd)
	e.set("crystal_damage", 8)

	var host: Node = get_parent().get_node_or_null("World")
	if host == null:
		host = get_parent()
	host.add_child(e)
	if e.has_method("assign_lane") and lane.size() > 0:
		e.call("assign_lane", lane)
	if elite and e.has_method("make_elite"):
		e.call("make_elite")
		GameState.message.emit("⚠ Elite %s!" % (EnemyKinds.display_name(_wave_kind) if EnemyKinds else "spawn"))
