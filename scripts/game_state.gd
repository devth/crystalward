extends Node
## Shared game state: bank, crystal, waves, win/lose.

signal essence_changed(value: int)
signal crystal_dust_changed(value: int)
signal crystal_hp_changed(current: int, maximum: int)
signal wave_changed(wave: int, total: int)
signal game_over(won: bool)
signal message(text: String)

const TOWER_COST_ESSENCE := 25
const TOWER_QUEUE_TIME := 2.0
const ESSENCE_PER_GATHER := 5
const GATHER_PROGRESS_RATE := 1.2  ## progress units per second per warden
const GATHER_NEED := 1.0
const STARTING_ESSENCE := 55
const STARTING_DUST := 0
const CRYSTAL_MAX_HP := 120
const WAVES_TO_WIN := 8

## Soft playable bounds (half-extent). Players and camera clamp inside this rect.
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

## Living wardens (Node2D) for centroid camera.
var wardens: Array[Node2D] = []


func _ready() -> void:
	reset()


func reset() -> void:
	is_game_over = false
	won = false
	essence = STARTING_ESSENCE
	crystal_dust = STARTING_DUST
	crystal_hp = CRYSTAL_MAX_HP
	crystal_max_hp = CRYSTAL_MAX_HP
	current_wave = 0
	wardens.clear()
	crystal_hp_changed.emit(crystal_hp, crystal_max_hp)
	wave_changed.emit(current_wave, waves_to_win)


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


func add_essence(amount: int) -> void:
	if is_game_over:
		return
	essence += amount


func add_crystal_dust(amount: int) -> void:
	if is_game_over:
		return
	crystal_dust += amount


func damage_crystal(amount: int) -> void:
	if is_game_over:
		return
	crystal_hp = maxi(0, crystal_hp - amount)
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
		_end_game(true)


func _end_game(victory: bool) -> void:
	is_game_over = true
	won = victory
	game_over.emit(victory)
	if victory:
		message.emit("Dawn breaks — the Crystal endures!")
		if Sfx:
			Sfx.win()
		if Juice:
			Juice.flash(Color(0.85, 0.75, 1.0, 0.45), 0.4)
			Juice.shake(12.0)
	else:
		message.emit("The Crystal is shattered...")
		if Sfx:
			Sfx.lose()
		if Juice:
			Juice.flash(Color(0.6, 0.05, 0.15, 0.5), 0.5)
			Juice.shake(16.0)
