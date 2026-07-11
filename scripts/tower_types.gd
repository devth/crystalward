extends Node
## Tower catalog + per-player pick + match unlocks.
## Autoloaded as TowerTypes.
## Six unique towers: ground / air / both + dedicated AOE.

signal unlocks_changed
signal selection_changed(player_index: int, type_id: String)

## target: "ground" | "air" | "both"
## special: single | multishot | splash | slow_aura | chain | root
const DEFS := {
	"thornspire": {
		"name": "Thornspire",
		"short": "DPS",
		"target": "ground",
		"target_label": "GND",
		"cost": 25,
		"color": Color(0.35, 0.78, 0.42),
		"desc": "Rapid thorns. Ground only.",
		"damage": 18,
		"fire_rate": 0.36,
		"range": 340.0,
		"role": "dps",
		"channel": "thorn",
		"unlock_tier": 0,
		"special": "multishot",
	},
	"emberfall": {
		"name": "Emberfall",
		"short": "AOE",
		"target": "ground",
		"target_label": "GND",
		"cost": 32,
		"color": Color(0.95, 0.48, 0.22),
		"desc": "Molten splash. Ground packs.",
		"damage": 26,
		"fire_rate": 0.95,
		"range": 300.0,
		"role": "aoe",
		"channel": "shatter",
		"splash": 120.0,
		"unlock_tier": 0,
		"special": "splash",
	},
	"shardbow": {
		"name": "Shardbow",
		"short": "SNIPE",
		"target": "both",
		"target_label": "ALL",
		"cost": 35,
		"color": Color(0.95, 0.82, 0.38),
		"desc": "Long bolts. Hits air & ground.",
		"damage": 48,
		"fire_rate": 0.88,
		"range": 560.0,
		"role": "snipe",
		"channel": "light",
		"unlock_tier": 1,
		"special": "execute",
	},
	"mistvent": {
		"name": "Mistvent",
		"short": "SLOW",
		"target": "both",
		"target_label": "ALL",
		"cost": 28,
		"color": Color(0.62, 0.42, 0.92),
		"desc": "Mist aura slows all foes.",
		"damage": 4,
		"fire_rate": 0.45,
		"range": 300.0,
		"role": "slow",
		"channel": "mist",
		"aura_slow": 0.55,
		"unlock_tier": 2,
		"special": "slow_aura",
	},
	"skyshard": {
		"name": "Skyshard",
		"short": "AIR",
		"target": "air",
		"target_label": "AIR",
		"cost": 38,
		"color": Color(0.55, 0.9, 0.95),
		"desc": "Chain light. Flyers only.",
		"damage": 24,
		"fire_rate": 0.62,
		"range": 480.0,
		"role": "air",
		"channel": "light",
		"chain_count": 3,
		"chain_falloff": 0.72,
		"unlock_tier": 3,
		"special": "chain",
	},
	"rootgate": {
		"name": "Rootgate",
		"short": "ROOT",
		"target": "ground",
		"target_label": "GND",
		"cost": 36,
		"color": Color(0.42, 0.58, 0.32),
		"desc": "Root pulse AOE. Ground only.",
		"damage": 14,
		"fire_rate": 1.0,
		"range": 290.0,
		"role": "control",
		"channel": "thorn",
		"root_duration": 1.15,
		"splash": 90.0,
		"unlock_tier": 4,
		"special": "root",
	},
}

## Unlock order (campaign / wave progression)
const ORDER: Array[String] = [
	"thornspire", "emberfall", "shardbow", "mistvent", "skyshard", "rootgate"
]

## Match-scoped unlocks (reset each battle)
var match_unlocked: Array[String] = []
## Per-player index into match_unlocked
var _player_pick: Array[int] = [0, 0, 0, 0]
## Highest campaign tier permanently known (persists via Campaign)
var campaign_tier: int = 0


func _ready() -> void:
	if Campaign and Campaign.has_method("tower_unlock_tier"):
		campaign_tier = int(Campaign.tower_unlock_tier())
	_reset_match_unlocks(0)


func begin_match(map_difficulty: int = 1) -> void:
	## Starting roster grows with campaign progress + map difficulty.
	if Campaign and Campaign.has_method("tower_unlock_tier"):
		campaign_tier = int(Campaign.tower_unlock_tier())
	var start_tier := mini(campaign_tier, ORDER.size() - 1)
	start_tier = mini(ORDER.size() - 1, maxi(start_tier, map_difficulty - 1))
	# Always at least Thornspire + Emberfall
	start_tier = maxi(1, start_tier)
	_reset_match_unlocks(start_tier)
	unlocks_changed.emit()


func _reset_match_unlocks(max_tier: int) -> void:
	match_unlocked.clear()
	for id in ORDER:
		var d: Dictionary = DEFS[id]
		if int(d.get("unlock_tier", 0)) <= max_tier:
			match_unlocked.append(id)
	if match_unlocked.is_empty():
		match_unlocked.append("thornspire")
	for i in _player_pick.size():
		_player_pick[i] = mini(_player_pick[i], match_unlocked.size() - 1)


func on_wave_started(wave: int) -> void:
	## Each new surge can unlock the next tower in the catalog.
	var target_count := mini(ORDER.size(), 2 + (wave - 1))
	var cap := mini(ORDER.size(), campaign_tier + 2 + wave)
	target_count = mini(target_count, cap)
	var unlocked_any := false
	while match_unlocked.size() < target_count:
		var next_id := _next_locked_id()
		if next_id == "":
			break
		match_unlocked.append(next_id)
		unlocked_any = true
		var d: Dictionary = def_for(next_id)
		if GameState:
			GameState.message.emit("✦ Unlocked tower: %s — %s" % [d.get("name"), d.get("desc")])
	if unlocked_any:
		unlocks_changed.emit()


func _next_locked_id() -> String:
	for id in ORDER:
		if id not in match_unlocked:
			return id
	return ""


func is_unlocked(id: String) -> bool:
	return id in match_unlocked


func unlocked_ids() -> Array[String]:
	var out: Array[String] = []
	for id in match_unlocked:
		out.append(id)
	return out


func unlocked_count() -> int:
	return match_unlocked.size()


func selected_id_for(player_index: int = 0) -> String:
	if match_unlocked.is_empty():
		return "thornspire"
	var i := clampi(player_index, 0, _player_pick.size() - 1)
	var idx := clampi(_player_pick[i], 0, match_unlocked.size() - 1)
	return match_unlocked[idx]


func selected_def_for(player_index: int = 0) -> Dictionary:
	return def_for(selected_id_for(player_index))


## Legacy global API (player 0)
func selected_id() -> String:
	return selected_id_for(0)


func selected_def() -> Dictionary:
	return selected_def_for(0)


func cycle_for_player(player_index: int, dir: int = 1) -> String:
	if match_unlocked.is_empty():
		return "thornspire"
	var i := clampi(player_index, 0, _player_pick.size() - 1)
	var n := match_unlocked.size()
	_player_pick[i] = (_player_pick[i] + dir) % n
	if _player_pick[i] < 0:
		_player_pick[i] = n - 1
	var id := match_unlocked[_player_pick[i]]
	selection_changed.emit(i, id)
	return id


func cycle(dir: int = 1) -> void:
	cycle_for_player(0, dir)


func set_player_pick_id(player_index: int, type_id: String) -> void:
	if type_id not in match_unlocked:
		return
	var i := clampi(player_index, 0, _player_pick.size() - 1)
	var idx := match_unlocked.find(type_id)
	if idx >= 0:
		_player_pick[i] = idx
		selection_changed.emit(i, type_id)


func def_for(id: String) -> Dictionary:
	return DEFS.get(id, DEFS["thornspire"])


func cost_for(id: String) -> int:
	return int(def_for(id).get("cost", 25))


func all_ids() -> Array[String]:
	var out: Array[String] = []
	for id in ORDER:
		out.append(id)
	return out


func target_label(id: String) -> String:
	return str(def_for(id).get("target_label", "ALL"))
