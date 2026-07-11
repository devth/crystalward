extends Node
## Unlockable creative powers (low gravity, magnet, glide, etc.).
## Autoloaded as Powers. Progress saved with campaign.

signal powers_changed

const SAVE_PATH := "user://crystalward_campaign.cfg"

## id -> definition
const CATALOG := {
	"double_jump": {
		"name": "Sky Step",
		"desc": "Double jump (always on once unlocked).",
		"cost_dust": 0,
		"default": true,
	},
	"low_gravity": {
		"name": "Moonveil",
		"desc": "Low gravity aura — floaty jumps, soft landings.",
		"cost_dust": 3,
		"default": false,
	},
	"crystal_glide": {
		"name": "Crystal Glide",
		"desc": "Hold jump in air to glide slowly.",
		"cost_dust": 4,
		"default": false,
	},
	"pollen_burst": {
		"name": "Pollen Burst",
		"desc": "Landing releases a slow pollen cloud.",
		"cost_dust": 3,
		"default": false,
	},
	"loot_magnet": {
		"name": "Gilded Pull",
		"desc": "Wider loot magnet aura while airborne.",
		"cost_dust": 2,
		"default": false,
	},
	"fairy_haste": {
		"name": "Fairy Bond",
		"desc": "Your fairies fly and gather faster.",
		"cost_dust": 5,
		"default": false,
	},
	"stomp": {
		"name": "Thorn Stomp",
		"desc": "Land from double-jump to damage nearby foes.",
		"cost_dust": 4,
		"default": false,
	},
}

var unlocked: Dictionary = {}  # id -> true
var equipped: Array[String] = ["double_jump"]  ## active set (max 3 extra + double_jump)


func _ready() -> void:
	load_powers()
	if not unlocked.get("double_jump", false):
		unlocked["double_jump"] = true
	if "double_jump" not in equipped:
		equipped.append("double_jump")


func is_unlocked(id: String) -> bool:
	return unlocked.get(id, CATALOG.get(id, {}).get("default", false)) == true


func is_equipped(id: String) -> bool:
	return id in equipped


func has(id: String) -> bool:
	return is_unlocked(id) and is_equipped(id)


func try_unlock(id: String) -> bool:
	if not CATALOG.has(id):
		return false
	if is_unlocked(id):
		return true
	var cost: int = int(CATALOG[id].get("cost_dust", 0))
	if GameState == null:
		return false
	if GameState.crystal_dust < cost:
		GameState.message.emit("Need %d dust for %s" % [cost, CATALOG[id].get("name")])
		return false
	# Explicit spend method — compound -= may not invoke property setter / signal
	if cost > 0 and not GameState.try_spend_crystal_dust(cost):
		return false
	unlocked[id] = true
	if id not in equipped and equipped.size() < 4:
		equipped.append(id)
	save_powers()
	powers_changed.emit()
	GameState.message.emit("Unlocked %s!" % CATALOG[id].get("name"))
	return true


func toggle_equip(id: String) -> void:
	if not is_unlocked(id):
		return
	if id == "double_jump":
		return  # always on
	if id in equipped:
		equipped.erase(id)
	else:
		if equipped.size() >= 4:
			# remove first non-double
			for e in equipped:
				if e != "double_jump":
					equipped.erase(e)
					break
		equipped.append(id)
	save_powers()
	powers_changed.emit()


func load_powers() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		unlocked = {"double_jump": true}
		equipped = ["double_jump"]
		return
	var u = cfg.get_value("powers", "unlocked", ["double_jump"])
	unlocked.clear()
	if u is Array:
		for id in u:
			unlocked[str(id)] = true
	unlocked["double_jump"] = true
	var eq = cfg.get_value("powers", "equipped", ["double_jump"])
	equipped.clear()
	if eq is Array:
		for id in eq:
			equipped.append(str(id))
	if "double_jump" not in equipped:
		equipped.append("double_jump")


func save_powers() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)  # merge with campaign
	var ids: Array = []
	for k in unlocked.keys():
		if unlocked[k]:
			ids.append(k)
	cfg.set_value("powers", "unlocked", ids)
	cfg.set_value("powers", "equipped", equipped)
	cfg.save(SAVE_PATH)


func gravity_scale() -> float:
	return 0.42 if has("low_gravity") else 1.0


func jump_velocity() -> float:
	return 320.0 if has("low_gravity") else 380.0


func max_jumps() -> int:
	return 2 if has("double_jump") else 1


func fairy_speed_mult() -> float:
	return 1.35 if has("fairy_haste") else 1.0


func fairy_gather_mult() -> float:
	return 1.25 if has("fairy_haste") else 1.0
