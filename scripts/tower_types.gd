extends Node
## Tower catalog + per-player pick + match unlocks.
## Autoloaded as TowerTypes.
## Start small; new towers unlock each surge / campaign tier.

signal unlocks_changed
signal selection_changed(player_index: int, type_id: String)

## type_id -> definition
## unlock_tier: 0 = always at match start on glade; higher tiers unlock with waves / maps
const DEFS := {
	"thornspire": {
		"name": "Thornspire",
		"short": "DPS",
		"cost": 25,
		"color": Color(0.35, 0.78, 0.42),
		"desc": "Rapid thorns. Melts packs.",
		"damage": 16,
		"fire_rate": 0.38,
		"range": 340.0,
		"role": "dps",
		"channel": "thorn",
		"unlock_tier": 0,
		"special": "multishot",  # hits 2 nearest
	},
	"shardbow": {
		"name": "Shardbow",
		"short": "SNIPE",
		"cost": 35,
		"color": Color(0.95, 0.82, 0.38),
		"desc": "Long crystal bolts. Elites first.",
		"damage": 42,
		"fire_rate": 0.82,
		"range": 540.0,
		"role": "snipe",
		"channel": "light",
		"unlock_tier": 0,
		"special": "execute",  # bonus vs low HP / elite
	},
	"mistvent": {
		"name": "Mistvent",
		"short": "SLOW",
		"cost": 28,
		"color": Color(0.62, 0.42, 0.92),
		"desc": "Violet mist. Slows the road.",
		"damage": 5,
		"fire_rate": 0.4,
		"range": 300.0,
		"role": "slow",
		"channel": "mist",
		"aura_slow": 0.55,
		"unlock_tier": 1,
		"special": "aura_slow",
	},
	"hex_lantern": {
		"name": "Hex Lantern",
		"short": "MARK",
		"cost": 32,
		"color": Color(0.92, 0.32, 0.78),
		"desc": "Marks foes. Allies hit harder.",
		"damage": 9,
		"fire_rate": 0.52,
		"range": 380.0,
		"role": "mark",
		"channel": "hex",
		"mark_mult": 1.45,
		"unlock_tier": 2,
		"special": "mark",
	},
	"hearthstone": {
		"name": "Hearthstone",
		"short": "BUFF",
		"cost": 30,
		"color": Color(0.98, 0.55, 0.28),
		"desc": "Amber warmth. Allies attack faster.",
		"damage": 6,
		"fire_rate": 0.7,
		"range": 320.0,
		"role": "buff",
		"channel": "light",
		"aura_haste": 0.32,
		"unlock_tier": 3,
		"special": "haste",
	},
	"bonehowl": {
		"name": "Bonehowl",
		"short": "PULSE",
		"cost": 36,
		"color": Color(0.72, 0.78, 0.98),
		"desc": "Shatter pulse. Splashes the lane.",
		"damage": 28,
		"fire_rate": 1.0,
		"range": 320.0,
		"role": "pulse",
		"channel": "shatter",
		"splash": 100.0,
		"unlock_tier": 4,
		"special": "splash",
	},
	"rootgate": {
		"name": "Rootgate",
		"short": "ROOT",
		"cost": 38,
		"color": Color(0.42, 0.58, 0.32),
		"desc": "Living roots. Snare packs briefly.",
		"damage": 12,
		"fire_rate": 0.9,
		"range": 300.0,
		"role": "root",
		"channel": "thorn",
		"root_duration": 1.1,
		"splash": 70.0,
		"unlock_tier": 5,
		"special": "root",
	},
	"skyshard": {
		"name": "Skyshard",
		"short": "ARC",
		"cost": 40,
		"color": Color(0.55, 0.9, 0.95),
		"desc": "Chain lightning of light. Leaps foes.",
		"damage": 20,
		"fire_rate": 0.7,
		"range": 400.0,
		"role": "chain",
		"channel": "light",
		"chain_count": 3,
		"chain_falloff": 0.7,
		"unlock_tier": 6,
		"special": "chain",
	},
}

## Unlock order (campaign / wave progression)
const ORDER: Array[String] = [
	"thornspire", "shardbow", "mistvent", "hex_lantern",
	"hearthstone", "bonehowl", "rootgate", "skyshard"
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
	# Map difficulty also opens the next tier early on harder stages
	start_tier = mini(ORDER.size() - 1, maxi(start_tier, map_difficulty - 1))
	# Always at least Thornspire + Shardbow
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
	# Wave 1: starter set already. Wave 2+ unlocks next if available.
	var want_tier := maxi(1, wave)  # wave 2 -> tier 2 etc. but cap by campaign+wave
	# Soft unlock: every wave past 1 opens one more type
	var target_count := mini(ORDER.size(), 2 + (wave - 1))
	# Respect campaign ceiling + 1 for discovery on current map
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
