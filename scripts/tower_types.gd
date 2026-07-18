extends Node
## Tower catalog + match unlocks + upgrade caps.
## Autoloaded as TowerTypes.
##
## Level 1 (Homeland): only 3 starters. Phases 1–5 max Lv1.
## Later phases unlock Lv2 one type at a time. Extra towers unlock by chapter.

signal unlocks_changed
signal selection_changed(player_index: int, type_id: String)
signal upgrade_caps_changed

## target: "ground" | "air" | "both"
## channel: thorn (physical) | light (magic) | shatter (anti-armor magic)
const DEFS := {
	## ── Chapter 1 starters ─────────────────────────────────────────────
	"arrow": {
		"name": "Arrow Tower",
		"short": "ARROW",
		"target": "both",
		"target_label": "ALL",
		"cost": 22,
		"color": Color(0.62, 0.48, 0.32),
		"desc": "Rustic bow. Hits air and ground.",
		"damage": 6,
		"fire_rate": 0.58,
		"range": 340.0,
		"role": "dps",
		"channel": "thorn",
		"special": "arrow",
		"unlock_chapter": 1,
		"unlock_phase": 1,
	},
	"briar": {
		"name": "Briar Spire",
		"short": "GND",
		"target": "ground",
		"target_label": "GND",
		"cost": 26,
		"color": Color(0.38, 0.62, 0.36),
		"desc": "Ground thorns. Cannot hit flyers.",
		"damage": 9,
		"fire_rate": 0.72,
		"range": 300.0,
		"role": "dps",
		"channel": "thorn",
		"special": "briar",
		"unlock_chapter": 1,
		"unlock_phase": 1,
	},
	"arcane": {
		"name": "Arcane Prism",
		"short": "MAG",
		"target": "both",
		"target_label": "ALL",
		"cost": 28,
		"color": Color(0.58, 0.48, 0.88),
		"desc": "Magic bolts. Strong vs heavy armor.",
		"damage": 7,
		"fire_rate": 0.85,
		"range": 320.0,
		"role": "dps",
		"channel": "shatter",
		"special": "arcane",
		"unlock_chapter": 1,
		"unlock_phase": 1,
	},
	## ── Later unlocks (logical road) ───────────────────────────────────
	"garrison": {
		"name": "Garrison",
		"short": "GAR",
		"target": "ground",
		"target_label": "GND",
		"cost": 30,
		"color": Color(0.68, 0.52, 0.42),
		"desc": "Soldiers leave the pad and block ground foes.",
		"damage": 6,
		"fire_rate": 0.6,
		"range": 220.0,
		"role": "garrison",
		"channel": "thorn",
		"special": "soldiers",
		"soldier_count": 2,
		"soldier_hp": 42,
		"soldier_damage": 5,
		"soldier_range": 52.0,
		"respawn": 5.5,
		"rally_dist": 70.0,
		"unlock_chapter": 2,
		"unlock_phase": 1,
	},
	"ballista": {
		"name": "Shard Ballista",
		"short": "SNIPE",
		"target": "both",
		"target_label": "ALL",
		"cost": 36,
		"color": Color(0.88, 0.72, 0.38),
		"desc": "Heavy long bolts. Slow, hard hits.",
		"damage": 16,
		"fire_rate": 1.15,
		"range": 480.0,
		"role": "snipe",
		"channel": "light",
		"special": "snipe",
		"unlock_chapter": 3,
		"unlock_phase": 1,
	},
	"mortar": {
		"name": "Ember Mortar",
		"short": "AOE",
		"target": "ground",
		"target_label": "GND",
		"cost": 38,
		"color": Color(0.9, 0.48, 0.28),
		"desc": "Lobbed splash. Ground packs only.",
		"damage": 14,
		"fire_rate": 1.2,
		"range": 310.0,
		"role": "aoe",
		"channel": "shatter",
		"special": "splash",
		"splash": 90.0,
		"unlock_chapter": 4,
		"unlock_phase": 1,
	},
}

## Unlock / pick order
const ORDER: Array[String] = [
	"arrow", "briar", "arcane", "garrison", "ballista", "mortar"
]

## Match state
var match_unlocked: Array[String] = []
var _player_pick: Array[int] = [0, 0, 0, 0]
var campaign_tier: int = 1
var match_chapter: int = 1
## Highest upgrade level any tower may reach this match (floor)
var match_level_floor: int = 1
## Per-type max level (allows L2 one type at a time on ch.1)
var _type_max_level: Dictionary = {}  # id -> int


func _ready() -> void:
	if Campaign and Campaign.has_method("tower_unlock_tier"):
		campaign_tier = int(Campaign.tower_unlock_tier())
	_reset_match_unlocks()


func begin_match(map_difficulty: int = 1) -> void:
	if Campaign and Campaign.has_method("tower_unlock_tier"):
		campaign_tier = int(Campaign.tower_unlock_tier())
	var m: Dictionary = {}
	if Campaign:
		m = Campaign.current_map()
	match_chapter = int(m.get("chapter", map_difficulty))
	if match_chapter <= 1:
		match_level_floor = 1
	elif match_chapter == 2:
		match_level_floor = 2
	else:
		match_level_floor = mini(3, match_chapter)
	_reset_match_unlocks()
	# Apply per-type caps for chapter
	if match_chapter <= 1:
		for id in match_unlocked:
			_type_max_level[id] = 1
	else:
		for id in match_unlocked:
			_type_max_level[id] = match_level_floor
	unlocks_changed.emit()
	upgrade_caps_changed.emit()


func _reset_match_unlocks() -> void:
	match_unlocked.clear()
	_type_max_level.clear()
	for id in ORDER:
		var d: Dictionary = DEFS[id]
		var need_ch := int(d.get("unlock_chapter", 1))
		var need_ph := int(d.get("unlock_phase", 1))
		# At match start: towers from earlier chapters + this chapter phase 1
		if need_ch < match_chapter or (need_ch == match_chapter and need_ph <= 1):
			match_unlocked.append(id)
			_type_max_level[id] = 1
	if match_unlocked.is_empty():
		match_unlocked.append("arrow")
		_type_max_level["arrow"] = 1
	for i in _player_pick.size():
		_player_pick[i] = mini(_player_pick[i], match_unlocked.size() - 1)


func on_wave_started(wave: int) -> void:
	## Mid-match: unlock towers whose unlock_phase has arrived; raise upgrade caps.
	var unlocked_any := false
	for id in ORDER:
		if id in match_unlocked:
			continue
		var d: Dictionary = DEFS[id]
		var need_ch := int(d.get("unlock_chapter", 99))
		var need_ph := int(d.get("unlock_phase", 99))
		if need_ch < match_chapter or (need_ch == match_chapter and need_ph <= wave):
			match_unlocked.append(id)
			_type_max_level[id] = maxi(1, match_level_floor)
			unlocked_any = true
			if GameState:
				GameState.message.emit("✦ Tower unlocked: %s — %s" % [d.get("name"), d.get("desc")])

	# Chapter 1: phases 1–5 stay Lv1; phase 6+ grant Lv2 to one starter type at a time
	if match_chapter <= 1:
		_apply_chapter1_upgrade_schedule(wave)
	elif match_chapter == 2 and wave >= 6:
		# Mid ch.2: open Lv3 for one type at a time
		_grant_level_cap_for_next_type(3, wave)
	elif match_chapter >= 3 and wave >= 4:
		for id in match_unlocked:
			_type_max_level[id] = maxi(int(_type_max_level.get(id, 1)), 3)

	if unlocked_any:
		unlocks_changed.emit()
	upgrade_caps_changed.emit()


func _apply_chapter1_upgrade_schedule(wave: int) -> void:
	## Phases 1–5: all max 1. Phase 6+: unlock Lv2 on arrow, then briar, then arcane.
	if wave <= 5:
		for id in match_unlocked:
			_type_max_level[id] = 1
		return
	var starters: Array[String] = ["arrow", "briar", "arcane"]
	var slots := wave - 5  # phase 6 → 1 type, phase 7 → 2, phase 8+ → all 3
	for i in starters.size():
		var id: String = starters[i]
		if id not in match_unlocked:
			continue
		var prev := int(_type_max_level.get(id, 1))
		if i < slots:
			_type_max_level[id] = 2
			if prev < 2 and GameState and i == slots - 1:
				GameState.message.emit("⬆ %s can upgrade to Level 2" % def_for(id).get("name"))
		else:
			_type_max_level[id] = 1


func _grant_level_cap_for_next_type(cap: int, wave: int) -> void:
	var starters: Array[String] = ["arrow", "briar", "arcane", "garrison"]
	var idx := clampi(wave - 6, 0, starters.size() - 1)
	for i in range(idx + 1):
		var id: String = starters[i]
		if id in match_unlocked:
			var prev := int(_type_max_level.get(id, 1))
			_type_max_level[id] = maxi(prev, cap)
			if prev < cap and GameState and i == idx:
				GameState.message.emit("⬆ %s can upgrade to Level %d" % [def_for(id).get("name"), cap])


func max_level_for(type_id: String) -> int:
	return clampi(int(_type_max_level.get(type_id, match_level_floor)), 1, GameState.TOWER_MAX_LEVEL if GameState else 3)


func can_upgrade(type_id: String, current_level: int) -> bool:
	return current_level < max_level_for(type_id)


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
		return "arrow"
	var i := clampi(player_index, 0, _player_pick.size() - 1)
	var idx := clampi(_player_pick[i], 0, match_unlocked.size() - 1)
	return match_unlocked[idx]


func selected_def_for(player_index: int = 0) -> Dictionary:
	return def_for(selected_id_for(player_index))


func selected_id() -> String:
	return selected_id_for(0)


func selected_def() -> Dictionary:
	return selected_def_for(0)


func cycle_for_player(player_index: int, dir: int = 1) -> String:
	if match_unlocked.is_empty():
		return "arrow"
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
	return DEFS.get(id, DEFS["arrow"])


func cost_for(id: String) -> int:
	return int(def_for(id).get("cost", 25))


func all_ids() -> Array[String]:
	var out: Array[String] = []
	for id in ORDER:
		out.append(id)
	return out


func target_label(id: String) -> String:
	return str(def_for(id).get("target_label", "ALL"))


## Legacy branch API (unused for starters; kept so old callers don't crash)
const BRANCH_PHYSICAL := "physical"
const BRANCH_MAGICAL := "magical"
const BRANCHES: Array[String] = [BRANCH_PHYSICAL, BRANCH_MAGICAL]
var _player_branch: Array[int] = [0, 0, 0, 0]
signal branch_changed(player_index: int, branch: String)

func selected_branch_for(player_index: int = 0) -> String:
	var i := clampi(player_index, 0, _player_branch.size() - 1)
	return BRANCHES[clampi(_player_branch[i], 0, BRANCHES.size() - 1)]

func cycle_branch_for_player(player_index: int, dir: int = 1) -> String:
	var i := clampi(player_index, 0, _player_branch.size() - 1)
	_player_branch[i] = (_player_branch[i] + dir) % BRANCHES.size()
	if _player_branch[i] < 0:
		_player_branch[i] = BRANCHES.size() - 1
	var b := BRANCHES[_player_branch[i]]
	branch_changed.emit(i, b)
	return b

func branch_label(branch: String) -> String:
	return "MAG" if branch == BRANCH_MAGICAL else "PHYS"

func branch_color(branch: String) -> Color:
	return Color(0.68, 0.48, 0.88) if branch == BRANCH_MAGICAL else Color(0.48, 0.78, 0.58)
