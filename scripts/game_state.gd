extends Node
## Shared game state — Kingdom Rush economy/lives/wave cadence + Crystalward co-op.

signal essence_changed(value: int)
signal crystal_dust_changed(value: int)
signal crystal_hp_changed(current: int, maximum: int)
signal wave_changed(wave: int, total: int)
signal wave_phase_changed(phase: String, seconds_left: float)
signal game_over(won: bool)
signal message(text: String)
signal stars_changed(stars: int)

const TOWER_COST_ESSENCE := 25
const TOWER_UPGRADE_COST := 30  ## per level
const TOWER_MAX_LEVEL := 3
const TOWER_QUEUE_TIME := 1.6  ## snappier, KR-like
const TOWER_SELL_REFUND := 0.6  ## 60% essence back
const ESSENCE_PER_GATHER := 5
const GATHER_PROGRESS_RATE := 1.2
const GATHER_NEED := 1.0
const ESSENCE_PER_KILL := 2
const ESSENCE_PER_ELITE := 8
const EARLY_WAVE_BONUS := 12
const STARTING_ESSENCE := 80  ## KR gives room to open with a few towers
const STARTING_DUST := 0
const CRYSTAL_MAX_HP := 20  ## "lives" feel — each leak costs 1 (scaled)
const CRYSTAL_DAMAGE_PER_LEAK := 1
const WAVES_TO_WIN := 8
const WORLD_BOUND := 1800.0

var essence: int = STARTING_ESSENCE:
	set(v):
		essence = maxi(0, v)
		essence_changed.emit(essence)

var crystal_dust: int = STARTING_DUST:
	set(v):
		crystal_dust = maxi(0, v)
		crystal_dust_changed.emit(crystal_dust)

var crystal_hp: int = CRYSTAL_MAX_HP
var crystal_max_hp: int = CRYSTAL_MAX_HP
var current_wave: int = 0
var waves_to_win: int = WAVES_TO_WIN
var is_game_over: bool = false
var won: bool = false
var stars: int = 0
var enemies_leaked: int = 0
var enemies_killed: int = 0
var essence_earned: int = 0

var wardens: Array[Node2D] = []


func _ready() -> void:
	reset()


func reset() -> void:
	## Resets match state only. Does not touch Campaign progress/unlocks.
	is_game_over = false
	won = false
	essence = STARTING_ESSENCE
	crystal_dust = STARTING_DUST
	crystal_hp = CRYSTAL_MAX_HP
	crystal_max_hp = CRYSTAL_MAX_HP
	current_wave = 0
	waves_to_win = WAVES_TO_WIN  # campaign map may override after reset
	stars = 0
	enemies_leaked = 0
	enemies_killed = 0
	essence_earned = 0
	wardens.clear()
	crystal_hp_changed.emit(crystal_hp, crystal_max_hp)
	wave_changed.emit(current_wave, waves_to_win)
	stars_changed.emit(stars)


func register_warden(w: Node2D) -> void:
	if w not in wardens:
		wardens.append(w)


func unregister_warden(w: Node2D) -> void:
	wardens.erase(w)


func clamp_world_position(pos: Vector2, bound: float = WORLD_BOUND) -> Vector2:
	return Vector2(clampf(pos.x, -bound, bound), clampf(pos.y, -bound, bound))


func try_spend_essence(amount: int) -> bool:
	if is_game_over:
		return false
	if essence < amount:
		message.emit("Not enough Essence (%d)" % amount)
		return false
	essence -= amount
	return true


func add_essence(amount: int, show_msg: bool = false) -> void:
	if is_game_over or amount == 0:
		return
	essence += amount
	if amount > 0:
		essence_earned += amount
	if show_msg:
		message.emit("+%d Essence" % amount)


func add_crystal_dust(amount: int) -> void:
	if is_game_over:
		return
	crystal_dust += amount


func reward_kill(elite: bool = false, world_pos: Vector2 = Vector2.ZERO) -> void:
	if is_game_over:
		return
	enemies_killed += 1
	var bounty := ESSENCE_PER_ELITE if elite else ESSENCE_PER_KILL
	add_essence(bounty)
	if world_pos != Vector2.ZERO:
		var tree := get_tree()
		if tree and tree.current_scene:
			FloatingText.spawn(tree.current_scene, world_pos + Vector2(0, -20), "+%d" % bounty, Color(1.0, 0.9, 0.35))


func damage_crystal(amount: int) -> void:
	if is_game_over:
		return
	# Kingdom Rush lives: each enemy leak costs exactly 1 life.
	# crystal_damage (e.g. 8) is a leak event flag — not raw HP damage.
	if amount <= 0:
		return
	var dmg := CRYSTAL_DAMAGE_PER_LEAK
	enemies_leaked += 1
	crystal_hp = maxi(0, crystal_hp - dmg)
	crystal_hp_changed.emit(crystal_hp, crystal_max_hp)
	if crystal_hp <= 0:
		_end_game(false)


func set_wave(n: int) -> void:
	current_wave = n
	wave_changed.emit(current_wave, waves_to_win)


func notify_wave_cleared() -> void:
	if is_game_over:
		return
	if current_wave >= waves_to_win:
		_compute_stars()
		_end_game(true)


func _compute_stars() -> void:
	# KR-like: 3 stars if few leaks, 2 if some, 1 if many
	if enemies_leaked <= 2:
		stars = 3
	elif enemies_leaked <= 8:
		stars = 2
	else:
		stars = 1
	stars_changed.emit(stars)


func _end_game(victory: bool) -> void:
	is_game_over = true
	won = victory
	if victory:
		_compute_stars()
	game_over.emit(victory)
	if victory:
		message.emit("Victory! %d★ — The Crystal endures" % stars)
		if Sfx:
			Sfx.win()
		if Juice:
			Juice.flash(Color(0.85, 0.75, 1.0, 0.45), 0.4)
			Juice.shake(12.0)
	else:
		message.emit("Defeat — the light is gone")
		if Sfx:
			Sfx.lose()
		if Juice:
			Juice.flash(Color(0.6, 0.05, 0.15, 0.5), 0.5)
			Juice.shake(16.0)
