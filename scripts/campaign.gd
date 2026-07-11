extends Node
## Multi-map campaign progress + stage definitions.
## Autoloaded as Campaign.
## Kingdom Rush–style map progression: lanes & pressure ramp map-to-map.

signal map_selected(map_id: String)
signal progress_changed

const SAVE_PATH := "user://crystalward_campaign.cfg"

## Selected map for the next battle.
var selected_map_id: String = "glade"
var unlocked: Dictionary = {"glade": true}  # map_id -> true
var best_stars: Dictionary = {}  # map_id -> 0..3


func _ready() -> void:
	load_progress()


func maps() -> Array:
	## Difficulty ladder mirrors KR / PixelJunk Monsters:
	## 1 path → merge dual → split dual → choke dual → long dual → triple.
	return [
		{
			"id": "glade",
			"name": "Lightwell Glade",
			"blurb": "One southern road. Learn the kill-zone.",
			"difficulty": 1,
			"waves": 5,
			"start_essence": 160,
			"lives": 30,
			"enemy_count_scale": 0.45,
			"enemy_hp_scale": 0.55,
			"enemy_speed_scale": 0.72,
			"elites": false,
			"first_wave_delay": 16.0,
			"calm_between_waves": 15.0,
			"theme": Color(1.05, 1.04, 0.98),
			"lane_set": "single",
		},
		{
			"id": "thorns",
			"name": "Twin River Pass",
			"blurb": "South + east roads merge near the well.",
			"difficulty": 2,
			"waves": 6,
			"start_essence": 120,
			"lives": 24,
			"enemy_count_scale": 0.65,
			"enemy_hp_scale": 0.75,
			"enemy_speed_scale": 0.85,
			"elites": false,
			"first_wave_delay": 14.0,
			"calm_between_waves": 14.0,
			"theme": Color(0.98, 1.05, 0.95),
			"lane_set": "dual",
		},
		{
			"id": "ruins",
			"name": "Silveroak Split",
			"blurb": "North and south roads — hold both flanks.",
			"difficulty": 3,
			"waves": 7,
			"start_essence": 105,
			"lives": 22,
			"enemy_count_scale": 0.8,
			"enemy_hp_scale": 0.9,
			"enemy_speed_scale": 0.92,
			"elites": true,
			"first_wave_delay": 12.0,
			"calm_between_waves": 13.0,
			"theme": Color(1.0, 0.96, 1.02),
			"lane_set": "meander",
		},
		{
			"id": "bog",
			"name": "Crosswind Bog",
			"blurb": "Diagonal roads share a mid choke.",
			"difficulty": 3,
			"waves": 7,
			"start_essence": 100,
			"lives": 20,
			"enemy_count_scale": 0.9,
			"enemy_hp_scale": 1.0,
			"enemy_speed_scale": 0.95,
			"elites": true,
			"first_wave_delay": 11.0,
			"calm_between_waves": 12.0,
			"theme": Color(0.95, 1.02, 0.98),
			"lane_set": "cross",
		},
		{
			"id": "march",
			"name": "Western March",
			"blurb": "Two long serpents. Little shared coverage.",
			"difficulty": 4,
			"waves": 8,
			"start_essence": 90,
			"lives": 18,
			"enemy_count_scale": 1.0,
			"enemy_hp_scale": 1.1,
			"enemy_speed_scale": 1.0,
			"elites": true,
			"first_wave_delay": 10.0,
			"calm_between_waves": 12.0,
			"theme": Color(0.98, 0.98, 1.04),
			"lane_set": "winding",
		},
		{
			"id": "conjunction",
			"name": "Nightfall Gate",
			"blurb": "Three portals. Endure the siege.",
			"difficulty": 5,
			"waves": 9,
			"start_essence": 85,
			"lives": 16,
			"enemy_count_scale": 1.1,
			"enemy_hp_scale": 1.2,
			"enemy_speed_scale": 1.05,
			"elites": true,
			"first_wave_delay": 10.0,
			"calm_between_waves": 11.0,
			"theme": Color(1.02, 0.95, 1.05),
			"lane_set": "full",
		},
	]


func get_map(id: String) -> Dictionary:
	for m in maps():
		if m.get("id") == id:
			return m
	return maps()[0]


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
