extends Node
## Multi-map campaign progress + stage definitions.
## Autoloaded as Campaign.

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
	return [
		{
			"id": "glade",
			"name": "Lightwell Glade",
			"blurb": "A soft meadow. Learn the paths.",
			"difficulty": 1,
			"waves": 6,
			"start_essence": 90,
			"theme": Color(1.05, 1.04, 0.98),
			"lane_set": "simple",
		},
		{
			"id": "thorns",
			"name": "Western Thorns",
			"blurb": "Winding briars. Swift thralls.",
			"difficulty": 2,
			"waves": 7,
			"start_essence": 80,
			"theme": Color(0.98, 1.05, 0.95),
			"lane_set": "cross",
		},
		{
			"id": "ruins",
			"name": "Eastern Ruins",
			"blurb": "Broken stones. Armored march.",
			"difficulty": 3,
			"waves": 8,
			"start_essence": 75,
			"theme": Color(1.0, 0.96, 1.02),
			"lane_set": "diagonal",
		},
		{
			"id": "bog",
			"name": "Southern Bog",
			"blurb": "Mist and mire. Slow death.",
			"difficulty": 3,
			"waves": 8,
			"start_essence": 70,
			"theme": Color(0.95, 1.02, 0.98),
			"lane_set": "winding",
		},
		{
			"id": "march",
			"name": "Northern March",
			"blurb": "Long roads. Many gates.",
			"difficulty": 4,
			"waves": 9,
			"start_essence": 70,
			"theme": Color(0.98, 0.98, 1.04),
			"lane_set": "full",
		},
		{
			"id": "conjunction",
			"name": "Conjunction Peak",
			"blurb": "All paths converge. Endure.",
			"difficulty": 5,
			"waves": 10,
			"start_essence": 65,
			"theme": Color(1.02, 0.95, 1.05),
			"lane_set": "full",
		},
	]


func get_map(id: String) -> Dictionary:
	for m in maps():
		if m.get("id") == id:
			return m
	return maps()[0]


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
	# Unlock next
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
	else:
		unlocked = {"glade": true}
	if not unlocked.has("glade"):
		unlocked["glade"] = true
	best_stars = cfg.get_value("campaign", "stars", {})


func save_progress() -> void:
	var cfg := ConfigFile.new()
	var ids: Array = []
	for k in unlocked.keys():
		if unlocked[k]:
			ids.append(k)
	cfg.set_value("campaign", "unlocked", ids)
	cfg.set_value("campaign", "stars", best_stars)
	cfg.save(SAVE_PATH)
