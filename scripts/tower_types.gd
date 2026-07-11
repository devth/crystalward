extends Node
## Tower type catalog (Kingdom Rush roles × Crystalward fantasy).
## Autoloaded as TowerTypes.

## type_id -> definition
const DEFS := {
	# Ranges sized for the large path map (pads ~55px off-road; path runs 1000+ px).
	"thornspire": {
		"name": "Thornspire",
		"short": "DPS",
		"cost": 25,
		"color": Color(0.35, 0.7, 0.4),
		"desc": "Green thorns. Melts swarms.",
		"damage": 18,
		"fire_rate": 0.42,
		"range": 340.0,
		"role": "dps",
		"channel": "thorn",
	},
	"shardbow": {
		"name": "Shardbow",
		"short": "SNIPE",
		"cost": 35,
		"color": Color(0.95, 0.8, 0.4),
		"desc": "Long shots. Priority elites.",
		"damage": 38,
		"fire_rate": 0.78,
		"range": 520.0,
		"role": "snipe",
		"channel": "light",
	},
	"mistvent": {
		"name": "Mistvent",
		"short": "SLOW",
		"cost": 28,
		"color": Color(0.65, 0.4, 0.9),
		"desc": "Mist aura. Slows the path.",
		"damage": 6,
		"fire_rate": 0.32,
		"range": 300.0,
		"role": "slow",
		"channel": "mist",
		"aura_slow": 0.5,
	},
	"hex_lantern": {
		"name": "Hex Lantern",
		"short": "MARK",
		"cost": 32,
		"color": Color(0.9, 0.35, 0.75),
		"desc": "Marks foes. Allies hit harder.",
		"damage": 8,
		"fire_rate": 0.5,
		"range": 380.0,
		"role": "mark",
		"channel": "hex",
		"mark_mult": 1.4,
	},
	"hearthstone": {
		"name": "Hearthstone",
		"short": "BUFF",
		"cost": 30,
		"color": Color(0.95, 0.55, 0.3),
		"desc": "Warmth aura. +attack speed.",
		"damage": 5,
		"fire_rate": 0.65,
		"range": 320.0,
		"role": "buff",
		"channel": "light",
		"aura_haste": 0.28,
	},
	"bonehowl": {
		"name": "Bonehowl",
		"short": "PULSE",
		"cost": 34,
		"color": Color(0.7, 0.75, 0.95),
		"desc": "Shatter pulse. Cracks armor.",
		"damage": 26,
		"fire_rate": 0.95,
		"range": 320.0,
		"role": "pulse",
		"channel": "shatter",
		"splash": 90.0,
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
