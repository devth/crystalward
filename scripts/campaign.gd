extends Node
## Multi-map campaign progress + stage definitions.
## Autoloaded as Campaign.
## 5 levels × 10 phases each; unique look/feel, escalating epic scale.

signal map_selected(map_id: String)
signal progress_changed

const SAVE_PATH := "user://crystalward_campaign.cfg"
const PHASES_PER_LEVEL := 10

## Selected map for the next battle.
var selected_map_id: String = "glade"
var unlocked: Dictionary = {"glade": true}  # map_id -> true
var best_stars: Dictionary = {}  # map_id -> 0..3


func _ready() -> void:
	load_progress()


func maps() -> Array:
	## Five chapters on the Road of Wounds. Each has 10 phases (waves).
	## look: visual theme key for ground / grade / props.
	return [
		{
			"id": "glade",
			"chapter": 1,
			"name": "Homeland Vale",
			"blurb": "Gentle Gelfling meadow. Soft paths. The Crystal still sings pure.",
			"story": "The Soft Dark is only a rumor in the pollen. One road. Ten soft lessons.",
			"difficulty": 1,
			"waves": PHASES_PER_LEVEL,
			"start_essence": 180,
			"lives": 28,
			"enemy_count_scale": 0.42,
			"enemy_hp_scale": 0.52,
			"enemy_speed_scale": 0.70,
			"elites": false,
			"first_wave_delay": 18.0,
			"calm_between_waves": 16.0,
			"theme": Color(1.08, 1.06, 0.98),
			"lane_set": "single",
			"look": "homeland",
		},
		{
			"id": "thorns",
			"chapter": 2,
			"name": "Twinveil Crossing",
			"blurb": "Mist-rivers braid. Two roads meet at the well. Split your light.",
			"story": "The dusk learns your names. Hold both mouths of the river.",
			"difficulty": 2,
			"waves": PHASES_PER_LEVEL,
			"start_essence": 140,
			"lives": 24,
			"enemy_count_scale": 0.62,
			"enemy_hp_scale": 0.72,
			"enemy_speed_scale": 0.82,
			"elites": false,
			"first_wave_delay": 14.0,
			"calm_between_waves": 14.0,
			"theme": Color(0.96, 1.02, 1.06),
			"lane_set": "dual",
			"look": "twinveil",
		},
		{
			"id": "bog",
			"chapter": 3,
			"name": "Crosswind Mire",
			"blurb": "Night-flowers open. Diagonal roads share one dry throat.",
			"story": "Beauty as bait. The Soft Dark perfumes the marsh.",
			"difficulty": 3,
			"waves": PHASES_PER_LEVEL,
			"start_essence": 115,
			"lives": 20,
			"enemy_count_scale": 0.85,
			"enemy_hp_scale": 0.95,
			"enemy_speed_scale": 0.92,
			"elites": true,
			"first_wave_delay": 12.0,
			"calm_between_waves": 12.0,
			"theme": Color(0.92, 1.0, 0.96),
			"lane_set": "cross",
			"look": "mire",
		},
		{
			"id": "march",
			"chapter": 4,
			"name": "Western March",
			"blurb": "Two long serpents across the dusk-heath. Little shared cover.",
			"story": "Umbrael’s highway. The light grows tired. Choose which serpent to starve.",
			"difficulty": 4,
			"waves": PHASES_PER_LEVEL,
			"start_essence": 100,
			"lives": 18,
			"enemy_count_scale": 1.0,
			"enemy_hp_scale": 1.1,
			"enemy_speed_scale": 1.0,
			"elites": true,
			"first_wave_delay": 10.0,
			"calm_between_waves": 11.0,
			"theme": Color(0.98, 0.96, 1.05),
			"lane_set": "winding",
			"look": "march",
		},
		{
			"id": "conjunction",
			"chapter": 5,
			"name": "Nightfall Gate",
			"blurb": "Three portals. Conjunction. Hold until the Crystal knits.",
			"story": "The Gloaming Court arrives. Endure, or Thren forgets the sun.",
			"difficulty": 5,
			"waves": PHASES_PER_LEVEL,
			"start_essence": 90,
			"lives": 16,
			"enemy_count_scale": 1.15,
			"enemy_hp_scale": 1.25,
			"enemy_speed_scale": 1.06,
			"elites": true,
			"first_wave_delay": 10.0,
			"calm_between_waves": 10.0,
			"theme": Color(1.02, 0.94, 1.08),
			"lane_set": "full",
			"look": "gate",
		},
	]


func get_map(id: String) -> Dictionary:
	for m in maps():
		if m.get("id") == id:
			return m
	return maps()[0]


func current_map() -> Dictionary:
	return get_map(selected_map_id)


func current_look() -> String:
	return str(current_map().get("look", "homeland"))


func tower_unlock_tier() -> int:
	## How far into the tower catalog permanent campaign progress has opened.
	var tier := 1
	var list := maps()
	for i in list.size():
		var mid: String = str(list[i].get("id"))
		if is_unlocked(mid):
			tier = maxi(tier, i + 1)
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
	var list := maps()
	for i in list.size():
		if list[i].get("id") == map_id and i + 1 < list.size():
			var next_id: String = list[i + 1].get("id")
			unlocked[next_id] = true
	save_progress()
	progress_changed.emit()


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		unlocked = {"glade": true}
		return
	var u = cfg.get_value("campaign", "unlocked", ["glade"])
	unlocked.clear()
	if u is Array:
		for id in u:
			unlocked[str(id)] = true
	elif u is Dictionary:
		for k in u:
			unlocked[str(k)] = true
	else:
		unlocked = {"glade": true}
	if not unlocked.has("glade"):
		unlocked["glade"] = true
	# Drop obsolete map ids from older 6-map saves
	var valid: Dictionary = {}
	for m in maps():
		valid[str(m.get("id"))] = true
	var cleaned: Dictionary = {}
	for k in unlocked.keys():
		if valid.has(str(k)) and unlocked[k]:
			cleaned[str(k)] = true
	if cleaned.is_empty():
		cleaned = {"glade": true}
	unlocked = cleaned
	best_stars = cfg.get_value("campaign", "stars", {})
	if best_stars == null or not (best_stars is Dictionary):
		best_stars = {}


func save_progress() -> void:
	var cfg := ConfigFile.new()
	var ids: Array = []
	for k in unlocked.keys():
		if unlocked[k]:
			ids.append(k)
	cfg.set_value("campaign", "unlocked", ids)
	cfg.set_value("campaign", "stars", best_stars)
	cfg.save(SAVE_PATH)
