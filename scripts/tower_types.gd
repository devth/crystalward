extends Node
## Tower type catalog (Kingdom Rush roles × Crystalward fantasy).
## Autoloaded as TowerTypes.

## type_id -> definition
const DEFS := {
	"thornspire": {
		"name": "Thornspire",
		"short": "DPS",
		"cost": 25,
		"color": Color(0.35, 0.7, 0.4),
		"desc": "Green thorns. Melts swarms.",
		"damage": 16,
		"fire_rate": 0.48,
		"range": 160.0,
		"role": "dps",
		"channel": "thorn",
	},
	"shardbow": {
		"name": "Shardbow",
		"short": "SNIPE",
		"cost": 35,
		"color": Color(0.95, 0.8, 0.4),
		"desc": "Long shots. Priority elites.",
		"damage": 32,
		"fire_rate": 0.85,
		"range": 260.0,
		"role": "snipe",
		"channel": "light",
	},
	"mistvent": {
		"name": "Mistvent",
		"short": "SLOW",
		"cost": 28,
		"color": Color(0.65, 0.4, 0.9),
		"desc": "Mist aura. Slows the path.",
		"damage": 4,
		"fire_rate": 0.35,
		"range": 140.0,
		"role": "slow",
		"channel": "mist",
		"aura_slow": 0.45,
	},
	"hex_lantern": {
		"name": "Hex Lantern",
		"short": "MARK",
		"cost": 32,
		"color": Color(0.9, 0.35, 0.75),
		"desc": "Marks foes. Allies hit harder.",
		"damage": 6,
		"fire_rate": 0.55,
		"range": 180.0,
		"role": "mark",
		"channel": "hex",
		"mark_mult": 1.35,
	},
	"hearthstone": {
		"name": "Hearthstone",
		"short": "BUFF",
		"cost": 30,
		"color": Color(0.95, 0.55, 0.3),
		"desc": "Warmth aura. +attack speed.",
		"damage": 3,
		"fire_rate": 0.7,
		"range": 150.0,
		"role": "buff",
		"channel": "light",
		"aura_haste": 0.25,
	},
	"bonehowl": {
		"name": "Bonehowl",
		"short": "PULSE",
		"cost": 34,
		"color": Color(0.7, 0.75, 0.95),
		"desc": "Shatter pulse. Cracks armor.",
		"damage": 22,
		"fire_rate": 1.1,
		"range": 150.0,
		"role": "pulse",
		"channel": "shatter",
		"splash": 55.0,
	},
}

const ORDER: Array[String] = [
	"thornspire", "shardbow", "mistvent", "hex_lantern", "hearthstone", "bonehowl"
]

var selected_index: int = 0


func selected_id() -> String:
	return ORDER[selected_index % ORDER.size()]


func selected_def() -> Dictionary:
	return DEFS[selected_id()]


func cycle(dir: int = 1) -> void:
	selected_index = (selected_index + dir) % ORDER.size()
	if selected_index < 0:
		selected_index = ORDER.size() - 1


func def_for(id: String) -> Dictionary:
	return DEFS.get(id, DEFS["thornspire"])


func cost_for(id: String) -> int:
	return int(def_for(id).get("cost", 25))
