extends Node
## Tower catalog + per-player pick + match unlocks.
## Autoloaded as TowerTypes.
## Starter lines: Garrison (path blockers), Dualshot (air+ground DPS → phys/magic),
## Groundspike (slow heavy ground → AOE).

signal unlocks_changed
signal selection_changed(player_index: int, type_id: String)
signal branch_changed(player_index: int, branch: String)

## target: "ground" | "air" | "both"
## special: dual_bolt | soldiers | single | splash | multishot | magic_bolt
const DEFS := {
	"garrison": {
		"name": "Garrison",
		"short": "GAR",
		"target": "ground",
		"target_label": "GND",
		"cost": 28,
		"color": Color(0.72, 0.55, 0.38),
		"desc": "Soldiers leave the pad and block ground foes.",
		"damage": 10,
		"fire_rate": 0.55,
		"range": 220.0,
		"role": "garrison",
		"channel": "thorn",
		"unlock_tier": 0,
		"special": "soldiers",
		"soldier_count": 2,
		"soldier_hp": 48,
		"soldier_damage": 9,
		"soldier_range": 52.0,
		"respawn": 5.0,
		"rally_dist": 70.0,
	},
	"dualshot": {
		"name": "Aetherbow",
		"short": "DPS",
		"target": "both",
		"target_label": "ALL",
		"cost": 24,
		"color": Color(0.55, 0.78, 0.95),
		"desc": "Hits air & ground. Upgrade → Physical or Magical.",
		"damage": 11,
		"fire_rate": 0.48,
		"range": 380.0,
		"role": "dps",
		"channel": "light",
		"unlock_tier": 0,
		"special": "dual_bolt",
		"branchable": true,
	},
	"groundspike": {
		"name": "Groundspike",
		"short": "GND",
		"target": "ground",
		"target_label": "GND",
		"cost": 30,
		"color": Color(0.42, 0.72, 0.38),
		"desc": "Slow heavy ground hits. Upgrade → AOE splash.",
		"damage": 34,
		"fire_rate": 0.95,
		"range": 300.0,
		"role": "dps",
		"channel": "thorn",
		"unlock_tier": 0,
		"special": "single",
		"splash": 0.0,
	},
}

## Unlock order (campaign / wave progression)
const ORDER: Array[String] = [
	"garrison", "dualshot", "groundspike"
]

## DPS upgrade branches for Aetherbow (L1 → L2)
const BRANCH_PHYSICAL := "physical"
const BRANCH_MAGICAL := "magical"
const BRANCHES: Array[String] = [BRANCH_PHYSICAL, BRANCH_MAGICAL]

## Match-scoped unlocks (reset each battle)
var match_unlocked: Array[String] = []
## Per-player index into match_unlocked
var _player_pick: Array[int] = [0, 0, 0, 0]
## Per-player Aetherbow upgrade branch preference
var _player_branch: Array[int] = [0, 0, 0, 0]
## Highest campaign tier permanently known (persists via Campaign)
var campaign_tier: int = 0


func _ready() -> void:
	if Campaign and Campaign.has_method("tower_unlock_tier"):
		campaign_tier = int(Campaign.tower_unlock_tier())
	_reset_match_unlocks(0)


func begin_match(map_difficulty: int = 1) -> void:
	## Starters always available; later maps keep all three open.
	if Campaign and Campaign.has_method("tower_unlock_tier"):
		campaign_tier = int(Campaign.tower_unlock_tier())
	var start_tier := mini(campaign_tier, ORDER.size() - 1)
	start_tier = mini(ORDER.size() - 1, maxi(start_tier, map_difficulty - 1))
	# Always open the full starter trio
	start_tier = maxi(ORDER.size() - 1, start_tier)
	_reset_match_unlocks(start_tier)
	unlocks_changed.emit()


func _reset_match_unlocks(max_tier: int) -> void:
	match_unlocked.clear()
	for id in ORDER:
		var d: Dictionary = DEFS[id]
		if int(d.get("unlock_tier", 0)) <= max_tier:
			match_unlocked.append(id)
	if match_unlocked.is_empty():
		match_unlocked.append("dualshot")
	for i in _player_pick.size():
		_player_pick[i] = mini(_player_pick[i], match_unlocked.size() - 1)


func on_wave_started(wave: int) -> void:
	## Starter trio is fully unlocked; no mid-match tower drip for now.
	var target_count := mini(ORDER.size(), ORDER.size())
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
	# Silence unused param for headless scripts
	if wave < 0:
		pass


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
		return "dualshot"
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
		return "dualshot"
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


func selected_branch_for(player_index: int = 0) -> String:
	var i := clampi(player_index, 0, _player_branch.size() - 1)
	var bi := clampi(_player_branch[i], 0, BRANCHES.size() - 1)
	return BRANCHES[bi]


func cycle_branch_for_player(player_index: int, dir: int = 1) -> String:
	var i := clampi(player_index, 0, _player_branch.size() - 1)
	var n := BRANCHES.size()
	_player_branch[i] = (_player_branch[i] + dir) % n
	if _player_branch[i] < 0:
		_player_branch[i] = n - 1
	var b := BRANCHES[_player_branch[i]]
	branch_changed.emit(i, b)
	return b


func branch_label(branch: String) -> String:
	match branch:
		BRANCH_MAGICAL:
			return "MAG"
		_:
			return "PHYS"


func branch_color(branch: String) -> Color:
	match branch:
		BRANCH_MAGICAL:
			return Color(0.72, 0.48, 0.95)
		_:
			return Color(0.55, 0.85, 0.45)


func def_for(id: String) -> Dictionary:
	return DEFS.get(id, DEFS["dualshot"])


func cost_for(id: String) -> int:
	return int(def_for(id).get("cost", 25))


func all_ids() -> Array[String]:
	var out: Array[String] = []
	for id in ORDER:
		out.append(id)
	return out


func target_label(id: String) -> String:
	return str(def_for(id).get("target_label", "ALL"))
