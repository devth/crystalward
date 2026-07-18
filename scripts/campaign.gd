extends Node
## Campaign: 5 levels × 10 playable sub-levels (phases) each.
## "Phase" = a distinct map/stage, NOT a wave.
## Waves inside a stage start small on early levels and grow later.

signal map_selected(map_id: String)
signal progress_changed

const SAVE_PATH := "user://crystalward_campaign.cfg"
const LEVELS_COUNT := 5
const PHASES_PER_LEVEL := 10

## Selected stage id e.g. "vale_03"
var selected_map_id: String = "vale_01"
var unlocked: Dictionary = {"vale_01": true}
var best_stars: Dictionary = {}  # stage_id -> 0..3

## Cached flat stage list
var _stages: Array = []


func _ready() -> void:
	_rebuild_stages()
	load_progress()


func _rebuild_stages() -> void:
	_stages.clear()
	for level_def in level_defs():
		var ch: int = int(level_def.get("chapter", 1))
		var level_id: String = str(level_def.get("id", "vale"))
		var base_look: String = str(level_def.get("look", "homeland"))
		var boss_id: String = str(level_def.get("boss_id", ""))
		var phase_names: Array = level_def.get("phase_names", [])
		var lane_sets: Array = level_def.get("lane_sets", ["single"])
		for p in range(1, PHASES_PER_LEVEL + 1):
			var sid := "%s_%02d" % [level_id, p]
			var is_boss_stage := p == PHASES_PER_LEVEL
			var waves := _waves_for(ch, p)
			var lane: String = str(lane_sets[mini(p - 1, lane_sets.size() - 1)])
			var pname: String = str(phase_names[p - 1]) if p - 1 < phase_names.size() else "Stage %d" % p
			var theme: Color = level_def.get("theme", Color.WHITE) as Color
			# Slight per-phase tint drift so sub-maps feel distinct
			var tshift := 1.0 + (float(p) - 5.5) * 0.008
			theme = Color(
				clampf(theme.r * tshift, 0.85, 1.12),
				clampf(theme.g * (2.0 - tshift * 0.5), 0.85, 1.12),
				clampf(theme.b * (1.0 + (float(p) * 0.004)), 0.85, 1.15)
			)
			_stages.append({
				"id": sid,
				"level_id": level_id,
				"chapter": ch,
				"phase": p,  # sub-level index 1..10 within the level
				"name": "%s" % pname,
				"level_name": str(level_def.get("name", "Level")),
				"blurb": str(level_def.get("phase_blurbs", {}).get(p, level_def.get("blurb", ""))),
				"story": str(level_def.get("story", "")),
				"difficulty": ch,
				"waves": waves,
				"start_essence": _essence_for(ch, p),
				"lives": _lives_for(ch),
				"enemy_count_scale": _count_scale(ch, p),
				"enemy_hp_scale": _hp_scale(ch, p),
				"enemy_speed_scale": _speed_scale(ch),
				"elites": ch >= 3 and p >= 4,
				"first_wave_delay": maxf(8.0, 18.0 - float(ch) * 1.5),
				"calm_between_waves": maxf(8.0, 16.0 - float(ch) * 1.2),
				"theme": theme,
				"lane_set": lane,
				"look": base_look,
				"boss_id": boss_id if is_boss_stage else "",
				"has_boss": is_boss_stage,
				"display": "L%d–%d · %s" % [ch, p, pname],
			})


## Level shells (places). Each expands to 10 sub-level maps.
func level_defs() -> Array:
	return [
		{
			"id": "vale",
			"chapter": 1,
			"name": "Homeland Vale",
			"blurb": "Gentle meadows. Ten roads through the vale before Harrow.",
			"story": "Umbrite is thin. Hold each Lightwell tether on the way to the grove.",
			"look": "homeland",
			"theme": Color(1.08, 1.06, 0.98),
			"boss_id": "boss_harrow",
			"lane_sets": [
				"single", "single", "single", "single", "single",
				"single", "single", "single", "single", "single",
			],
			"phase_names": [
				"Briar Lane",
				"Pollen Rise",
				"Mossbrook Bend",
				"Sunny Knoll",
				"Well-Ring Meadow",
				"Thornfence Path",
				"Elder Stump",
				"Gelfling Garden",
				"Amber Orchard",
				"Harrow's Root",
			],
			"phase_blurbs": {
				1: "First road. Learn the Lightwell and the pads.",
				2: "A gentle climb. Essence wells between the flowers.",
				3: "The brook still runs clean.",
				4: "Open ground. Easy sight lines.",
				5: "Ring-stones of an old gathering.",
				6: "Briars thicken. Upgrade Arrow towers if you can.",
				7: "The stump where children once played.",
				8: "Homestead gardens — still tended.",
				9: "Orchard on the way to the great oak.",
				10: "The grove-warden waits. Rootfather Harrow.",
			},
		},
		{
			"id": "veil",
			"chapter": 2,
			"name": "Twinveil Crossing",
			"blurb": "Mist rivers. Ten fords and merges. Phase 10: the Ford-Widow.",
			"story": "Umbrael needs the crossing. Split your light across both mouths.",
			"look": "twinveil",
			"theme": Color(0.96, 1.02, 1.06),
			"boss_id": "boss_fordwidow",
			"lane_sets": [
				"dual", "dual", "dual", "dual", "dual",
				"dual", "dual", "dual", "dual", "dual",
			],
			"phase_names": [
				"South Mouth",
				"East Mouth",
				"Reed Flats",
				"Bell-Stone Ford",
				"Mist Braid",
				"Ferry Ruin",
				"Twin Cairns",
				"Widow's Pier",
				"Deep Channel",
				"Maera's Bell",
			],
		},
		{
			"id": "mire",
			"chapter": 3,
			"name": "Crosswind Mire",
			"blurb": "Peat roads and chokes. Ten sinks. Phase 10: Bog-Crown Mirel.",
			"story": "Temple land gone wrong. Hold the dry ridge.",
			"look": "mire",
			"theme": Color(0.92, 1.0, 0.96),
			"boss_id": "boss_mirel",
			"lane_sets": [
				"cross", "cross", "meander", "cross", "cross",
				"meander", "cross", "cross", "meander", "cross",
			],
			"phase_names": [
				"Peat Gate",
				"Choir Sink",
				"Lantern Ridge",
				"Black Pool",
				"Temple Steps",
				"Crosswind Spine",
				"Mask Fen",
				"Goldreed Path",
				"Abbot's Cell",
				"Mirel's Crown",
			],
		},
		{
			"id": "march",
			"chapter": 4,
			"name": "Western March",
			"blurb": "Long military roads. Ten posts. Phase 10: Marshal Vesk.",
			"story": "Armies pass here. Starve one serpent or both.",
			"look": "march",
			"theme": Color(0.98, 0.96, 1.05),
			"boss_id": "boss_vesk",
			"lane_sets": [
				"winding", "winding", "winding", "winding", "winding",
				"winding", "winding", "winding", "winding", "winding",
			],
			"phase_names": [
				"Mile Marker I",
				"Broken Wagon",
				"Watchfire Hollow",
				"Split Road",
				"Iron Cairn",
				"Supply Cut",
				"Long Dusk",
				"Vesk's Camp",
				"Siege Grade",
				"Marshal's Line",
			],
		},
		{
			"id": "gate",
			"chapter": 5,
			"name": "Nightfall Gate",
			"blurb": "Castle approaches. Ten approaches. Phase 10: Lord Umbrael.",
			"story": "Break the traitor or the last Lightwell dies.",
			"look": "gate",
			"theme": Color(1.02, 0.94, 1.08),
			"boss_id": "boss_umbrael",
			"lane_sets": [
				"dual", "dual", "meander", "winding", "full",
				"full", "full", "full", "full", "full",
			],
			"phase_names": [
				"Outer Curtain",
				"Banner Walk",
				"Barbican Road",
				"Moat Bridge",
				"Three Portals",
				"Court Stairs",
				"Umbrite Gallery",
				"Fire Shaft View",
				"Conjunction Court",
				"Lord Umbrael",
			],
		},
	]


func _waves_for(chapter: int, phase: int) -> int:
	## Waves per battle: start small, grow by level and late sub-levels.
	## Ch1: 3–5, Ch2: 4–6, Ch3: 5–7, Ch4: 6–8, Ch5: 7–9
	var base := 2 + chapter  # ch1→3, ch5→7
	var late := 0
	if phase >= 8:
		late = 2
	elif phase >= 5:
		late = 1
	return mini(10, base + late)


func _essence_for(chapter: int, phase: int) -> int:
	var e := 200 - chapter * 18 - phase * 2
	return clampi(e, 80, 200)


func _lives_for(chapter: int) -> int:
	return clampi(30 - chapter * 3, 14, 30)


func _count_scale(chapter: int, phase: int) -> float:
	return clampf(0.35 + float(chapter) * 0.12 + float(phase) * 0.02, 0.35, 1.25)


func _hp_scale(chapter: int, phase: int) -> float:
	return clampf(0.48 + float(chapter) * 0.12 + float(phase) * 0.015, 0.48, 1.35)


func _speed_scale(chapter: int) -> float:
	return clampf(0.68 + float(chapter) * 0.07, 0.68, 1.1)


func maps() -> Array:
	if _stages.is_empty():
		_rebuild_stages()
	return _stages


func levels() -> Array:
	return level_defs()


func get_map(id: String) -> Dictionary:
	for m in maps():
		if m.get("id") == id:
			return m
	return maps()[0] if not maps().is_empty() else {}


func current_map() -> Dictionary:
	return get_map(selected_map_id)


func current_look() -> String:
	return str(current_map().get("look", "homeland"))


func current_chapter() -> int:
	return int(current_map().get("chapter", 1))


func current_phase() -> int:
	## Sub-level index within the level (1–10), not a combat wave.
	return int(current_map().get("phase", 1))


func boss_id_for_map(map_id: String = "") -> String:
	var m: Dictionary = get_map(map_id) if map_id != "" else current_map()
	return str(m.get("boss_id", ""))


func stage_has_boss(map_id: String = "") -> bool:
	var m: Dictionary = get_map(map_id) if map_id != "" else current_map()
	return bool(m.get("has_boss", false))


func tower_unlock_tier() -> int:
	## Highest chapter with any unlocked stage.
	var tier := 1
	for m in maps():
		if is_unlocked(str(m.get("id"))):
			tier = maxi(tier, int(m.get("chapter", 1)))
	return clampi(tier, 1, 7)


func is_unlocked(id: String) -> bool:
	return unlocked.get(id, false) == true


func select_map(id: String) -> void:
	if not is_unlocked(id):
		return
	selected_map_id = id
	map_selected.emit(id)


func record_victory(map_id: String, stars: int) -> void:
	var prev: int = int(best_stars.get(map_id, 0))
	if stars > prev:
		best_stars[map_id] = stars
	# Unlock next stage in sequence
	var list := maps()
	for i in list.size():
		if str(list[i].get("id")) == map_id and i + 1 < list.size():
			var next_id: String = str(list[i + 1].get("id"))
			unlocked[next_id] = true
			break
	save_progress()
	progress_changed.emit()


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		unlocked = {"vale_01": true}
		selected_map_id = "vale_01"
		return
	var u = cfg.get_value("campaign", "unlocked", ["vale_01"])
	unlocked.clear()
	if u is Array:
		for id in u:
			unlocked[str(id)] = true
	elif u is Dictionary:
		for k in u:
			unlocked[str(k)] = true
	else:
		unlocked = {"vale_01": true}
	# Migrate old single-map saves
	if unlocked.has("glade") and not unlocked.has("vale_01"):
		unlocked["vale_01"] = true
	if unlocked.has("thorns"):
		unlocked["veil_01"] = true
	if not unlocked.has("vale_01"):
		unlocked["vale_01"] = true
	var valid: Dictionary = {}
	for m in maps():
		valid[str(m.get("id"))] = true
	var cleaned: Dictionary = {}
	for k in unlocked.keys():
		if valid.has(str(k)) and unlocked[k]:
			cleaned[str(k)] = true
	if cleaned.is_empty():
		cleaned = {"vale_01": true}
	unlocked = cleaned
	best_stars = cfg.get_value("campaign", "stars", {})
	if best_stars == null or not (best_stars is Dictionary):
		best_stars = {}
	var sel = cfg.get_value("campaign", "selected", "vale_01")
	if valid.has(str(sel)):
		selected_map_id = str(sel)
	else:
		selected_map_id = "vale_01"


func save_progress() -> void:
	var cfg := ConfigFile.new()
	var ids: Array = []
	for k in unlocked.keys():
		if unlocked[k]:
			ids.append(k)
	cfg.set_value("campaign", "unlocked", ids)
	cfg.set_value("campaign", "stars", best_stars)
	cfg.set_value("campaign", "selected", selected_map_id)
	cfg.save(SAVE_PATH)
