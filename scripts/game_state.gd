extends Node
## Shared game state — Kingdom Rush economy/lives/wave cadence + Crystalward co-op.

# Preload so reward_kill works without relying on global class_name cache (new scripts).
const _LootDrop = preload("res://scripts/loot_drop.gd")

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
const FAIRY_COST_ESSENCE := 20
const FAIRY_MAX := 6  ## shared cap for co-op

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
var fairies: Array[Node2D] = []


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
	# Fairies are match-scoped. Wardens are scene players — do not wipe them.
	# (Players _ready before Main, so clearing here orphaned the camera follow list.)
	fairies.clear()
	for i in range(wardens.size() - 1, -1, -1):
		if not is_instance_valid(wardens[i]) or not wardens[i].is_inside_tree():
			wardens.remove_at(i)
	crystal_hp_changed.emit(crystal_hp, crystal_max_hp)
	wave_changed.emit(current_wave, waves_to_win)
	stars_changed.emit(stars)


func register_warden(w: Node2D) -> void:
	if w not in wardens:
		wardens.append(w)


func unregister_warden(w: Node2D) -> void:
	wardens.erase(w)


func register_fairy(f: Node2D) -> void:
	if f not in fairies:
		fairies.append(f)


func unregister_fairy(f: Node2D) -> void:
	fairies.erase(f)


func fairy_count() -> int:
	var alive: Array[Node2D] = []
	for f in fairies:
		if is_instance_valid(f):
			alive.append(f)
	fairies = alive
	return fairies.size()


func can_spawn_fairy() -> bool:
	return not is_game_over and fairy_count() < FAIRY_MAX and essence >= FAIRY_COST_ESSENCE


func try_spawn_fairy(at: Vector2, owner_index: int = 0) -> Node2D:
	if fairy_count() >= FAIRY_MAX:
		message.emit("Max fairies (%d)" % FAIRY_MAX)
		return null
	if not try_spend_essence(FAIRY_COST_ESSENCE):
		return null
	var scene: PackedScene = load("res://scenes/helper_fairy.tscn") as PackedScene
	if scene == null:
		add_essence(FAIRY_COST_ESSENCE)
		return null
	var fairy: Node2D = scene.instantiate() as Node2D
	if fairy == null:
		add_essence(FAIRY_COST_ESSENCE)
		return null
	fairy.set("owner_index", owner_index)
	var parent := get_tree().current_scene
	if parent == null:
		fairy.queue_free()
		add_essence(FAIRY_COST_ESSENCE)
		return null
	parent.add_child(fairy)
	fairy.global_position = at + Vector2(randf_range(-20, 20), randf_range(-30, -10))
	message.emit("Fairy helper! (%d/%d) — loots & gathers" % [fairy_count(), FAIRY_MAX])
	if Sfx:
		Sfx.gather()
	if Juice:
		Juice.flash(Color(0.7, 0.9, 1.0, 0.2), 0.1)
	FloatingText.spawn(parent, at + Vector2(0, -24), "Fairy!", Color(0.85, 0.9, 1.0))
	return fairy


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
	crystal_dust = crystal_dust + amount


func try_spend_crystal_dust(amount: int) -> bool:
	## Spend dust (map powers unlock). Always uses setter so HUD signals fire.
	if amount <= 0:
		return true
	if crystal_dust < amount:
		return false
	crystal_dust = crystal_dust - amount
	return true


func reward_kill(elite: bool = false, world_pos: Vector2 = Vector2.ZERO) -> void:
	if is_game_over:
		return
	enemies_killed += 1
	# Spawn ground loot (fairies / players collect) instead of auto-bank only
	var tree := get_tree()
	var parent: Node = tree.current_scene if tree else null
	if parent == null or world_pos == Vector2.ZERO:
		# Fallback: instant credit
		var bounty := ESSENCE_PER_ELITE if elite else ESSENCE_PER_KILL
		add_essence(bounty)
		return
	var ess_amt := ESSENCE_PER_ELITE if elite else ESSENCE_PER_KILL
	# Elite drops extra shards
	var drops := 2 if elite else 1
	for i in drops:
		var offset := Vector2(randf_range(-16, 16), randf_range(-12, 12))
		_LootDrop.spawn_essence(parent, world_pos + offset, ess_amt if i == 0 else maxi(1, ess_amt / 2))
	if elite or randf() < 0.22:
		_LootDrop.spawn_dust(parent, world_pos + Vector2(randf_range(-10, 10), randf_range(-8, 8)), 1 if not elite else 2)


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
