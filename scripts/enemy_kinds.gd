extends Node
## Nightspawn kind catalog — one kind per surge, with tower matchups.
## Autoloaded as EnemyKinds.

## kind_id -> definition
## weak_channels / resist_channels use tower "channel" (thorn, light, mist, hex, shatter)
## weak_specials / resist_specials use tower "special" (multishot, execute, splash, root, chain, …)
const KINDS := {
	"thrall": {
		"name": "Briar Thralls",
		"short": "SWARM",
		"blurb": "Pack runners. Thorns & pulses shred them; snipes waste shots.",
		"hp_mult": 0.72,
		"speed_mult": 1.22,
		"scale_mult": 0.92,
		"path_slack": 22.0,
		"sep_radius": 48.0,
		"min_path_gap": 70.0,
		"spawn_spacing": 0.85,
		"weak_channels": ["thorn", "shatter"],
		"resist_channels": ["light"],
		"weak_specials": ["multishot", "splash"],
		"resist_specials": ["execute", "snipe"],
		"skin": "pest",
		"color": Color(0.55, 0.85, 0.45),
	},
	"ironclad": {
		"name": "Iron Procession",
		"short": "ARMORED",
		"blurb": "Thick plates. Bonehowl/shatter cracks them; thorns glance off.",
		"hp_mult": 1.65,
		"speed_mult": 0.72,
		"scale_mult": 1.18,
		"path_slack": 10.0,
		"sep_radius": 56.0,
		"min_path_gap": 90.0,
		"spawn_spacing": 1.15,
		"weak_channels": ["shatter"],
		"resist_channels": ["thorn"],
		"weak_specials": ["splash", "pulse"],
		"resist_specials": ["multishot"],
		"skin": "undead",
		"color": Color(0.65, 0.7, 0.85),
	},
	"skitter": {
		"name": "Skitter Host",
		"short": "SWIFT",
		"blurb": "Too fast to pin. Mist & roots hold them; pure DPS trails behind.",
		"hp_mult": 0.85,
		"speed_mult": 1.55,
		"scale_mult": 0.88,
		"path_slack": 26.0,
		"sep_radius": 52.0,
		"min_path_gap": 75.0,
		"spawn_spacing": 0.7,
		"weak_channels": ["mist", "thorn"],
		"resist_channels": ["light"],
		"weak_specials": ["root", "aura_slow"],
		"resist_specials": ["execute"],
		"skin": "beast",
		"color": Color(0.9, 0.7, 0.35),
	},
	"shade": {
		"name": "Soft Dark",
		"short": "SHADE",
		"blurb": "Half-spirit. Light, hex, and marks burn them; roots pass through.",
		"hp_mult": 1.05,
		"speed_mult": 1.05,
		"scale_mult": 1.0,
		"path_slack": 18.0,
		"sep_radius": 50.0,
		"min_path_gap": 80.0,
		"spawn_spacing": 0.95,
		"weak_channels": ["light", "hex"],
		"resist_channels": ["thorn"],
		"weak_specials": ["mark", "execute", "chain"],
		"resist_specials": ["root", "multishot"],
		"skin": "demon",
		"color": Color(0.7, 0.45, 0.95),
	},
	"brute": {
		"name": "Siege Brutes",
		"short": "BRUTE",
		"blurb": "Heavy crystal-eaters. Snipes & executes; slows barely touch them.",
		"hp_mult": 1.85,
		"speed_mult": 0.78,
		"scale_mult": 1.32,
		"path_slack": 8.0,
		"sep_radius": 64.0,
		"min_path_gap": 100.0,
		"spawn_spacing": 1.35,
		"weak_channels": ["light"],
		"resist_channels": ["mist"],
		"weak_specials": ["execute", "snipe", "mark"],
		"resist_specials": ["aura_slow", "root"],
		"skin": "demon",
		"color": Color(0.95, 0.4, 0.35),
		"crystal_damage_mult": 1.5,
	},
	"blight": {
		"name": "Blight Spores",
		"short": "BLIGHT",
		"blurb": "Soft bodies in a cloud. Hex & thorns; splash is messy but weak.",
		"hp_mult": 0.95,
		"speed_mult": 1.1,
		"scale_mult": 0.95,
		"path_slack": 24.0,
		"sep_radius": 46.0,
		"min_path_gap": 65.0,
		"spawn_spacing": 0.75,
		"weak_channels": ["hex", "thorn"],
		"resist_channels": ["shatter"],
		"weak_specials": ["mark", "multishot"],
		"resist_specials": ["splash"],
		"skin": "slime",
		"color": Color(0.45, 0.85, 0.55),
	},
	"wraith": {
		"name": "Night Wraiths",
		"short": "WRAITH",
		"blurb": "Arc-hungry spirits. Skyshard chains melt them; solid thorns fade.",
		"hp_mult": 1.15,
		"speed_mult": 1.12,
		"scale_mult": 1.05,
		"path_slack": 20.0,
		"sep_radius": 54.0,
		"min_path_gap": 85.0,
		"spawn_spacing": 1.0,
		"weak_channels": ["light"],
		"resist_channels": ["thorn", "shatter"],
		"weak_specials": ["chain", "execute"],
		"resist_specials": ["splash", "multishot"],
		"skin": "undead",
		"color": Color(0.55, 0.85, 0.95),
	},
}

## Order used when assigning kinds to waves (cycles).
const WAVE_ORDER: Array[String] = [
	"thrall", "ironclad", "skitter", "shade", "brute", "blight", "wraith"
]


func kind_for_wave(wave: int) -> String:
	if WAVE_ORDER.is_empty():
		return "thrall"
	var i := (maxi(1, wave) - 1) % WAVE_ORDER.size()
	return WAVE_ORDER[i]


func def_for(kind_id: String) -> Dictionary:
	return KINDS.get(kind_id, KINDS["thrall"])


func display_name(kind_id: String) -> String:
	return str(def_for(kind_id).get("name", kind_id))


func blurb(kind_id: String) -> String:
	return str(def_for(kind_id).get("blurb", ""))


## Damage multiplier for a tower profile vs this kind.
func damage_mult(kind_id: String, channel: String, special: String, role: String) -> float:
	var d: Dictionary = def_for(kind_id)
	var mult := 1.0
	var weak_ch: Array = d.get("weak_channels", [])
	var res_ch: Array = d.get("resist_channels", [])
	var weak_sp: Array = d.get("weak_specials", [])
	var res_sp: Array = d.get("resist_specials", [])
	if channel in weak_ch:
		mult *= 1.55
	if channel in res_ch:
		mult *= 0.52
	if special in weak_sp or role in weak_sp:
		mult *= 1.35
	if special in res_sp or role in res_sp:
		mult *= 0.6
	return clampf(mult, 0.35, 2.4)


func matchup_hint(kind_id: String) -> String:
	var d: Dictionary = def_for(kind_id)
	var tips: Array[String] = []
	var seen: Dictionary = {}
	var add := func(s: String) -> void:
		if not seen.has(s):
			seen[s] = true
			tips.append(s)
	for ch in d.get("weak_channels", []):
		match str(ch):
			"thorn":
				add.call("Thornspire")
			"light":
				add.call("Shardbow")
			"mist":
				add.call("Mistvent")
			"hex":
				add.call("Hex Lantern")
			"shatter":
				add.call("Bonehowl")
	for sp in d.get("weak_specials", []):
		match str(sp):
			"splash", "pulse":
				add.call("Bonehowl")
			"chain":
				add.call("Skyshard")
			"root", "aura_slow":
				add.call("Rootgate/Mist")
			"multishot":
				add.call("Thornspire")
			"execute", "snipe":
				add.call("Shardbow")
			"mark":
				add.call("Hex Lantern")
	if tips.is_empty():
		return "Best: any tower"
	return "Best: " + ", ".join(tips)
