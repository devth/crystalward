extends Node
## Nightspawn kind catalog — one kind per surge, with tower matchups.
## Autoloaded as EnemyKinds.
## `flying: true` = air unit (Skyshard / air targeting).

## kind_id -> definition
const KINDS := {
	"thrall": {
		"name": "Briar Thralls",
		"short": "SWARM",
		"blurb": "Ground pack. Thorns & Emberfall shred them.",
		"flying": false,
		"hp_mult": 0.72,
		"speed_mult": 1.22,
		"scale_mult": 0.92,
		"path_slack": 22.0,
		"sep_radius": 48.0,
		"min_path_gap": 70.0,
		"spawn_spacing": 0.85,
		"weak_channels": ["thorn", "shatter"],
		"resist_channels": ["light"],
		"weak_specials": ["multishot", "splash", "aoe"],
		"resist_specials": ["execute", "snipe", "chain"],
		"skin": "pest",
		"color": Color(0.55, 0.85, 0.45),
	},
	"ironclad": {
		"name": "Iron Procession",
		"short": "ARMORED",
		"blurb": "Ground armor. Emberfall cracks plates; thorns glance.",
		"flying": false,
		"hp_mult": 1.65,
		"speed_mult": 0.72,
		"scale_mult": 1.18,
		"path_slack": 10.0,
		"sep_radius": 56.0,
		"min_path_gap": 90.0,
		"spawn_spacing": 1.15,
		"weak_channels": ["shatter"],
		"resist_channels": ["thorn"],
		"weak_specials": ["splash", "aoe"],
		"resist_specials": ["multishot"],
		"skin": "undead",
		"color": Color(0.65, 0.7, 0.85),
	},
	"skitter": {
		"name": "Skitter Host",
		"short": "SWIFT",
		"blurb": "Ground speedsters. Mist & roots hold them.",
		"flying": false,
		"hp_mult": 0.85,
		"speed_mult": 1.55,
		"scale_mult": 0.88,
		"path_slack": 26.0,
		"sep_radius": 52.0,
		"min_path_gap": 75.0,
		"spawn_spacing": 0.7,
		"weak_channels": ["mist", "thorn"],
		"resist_channels": ["light"],
		"weak_specials": ["root", "slow_aura", "control"],
		"resist_specials": ["execute"],
		"skin": "beast",
		"color": Color(0.9, 0.7, 0.35),
	},
	"shade": {
		"name": "Soft Dark",
		"short": "FLYER",
		"blurb": "Air spirits. Skyshard & light burn them; roots miss.",
		"flying": true,
		"hp_mult": 1.0,
		"speed_mult": 1.12,
		"scale_mult": 1.0,
		"path_slack": 28.0,
		"sep_radius": 52.0,
		"min_path_gap": 80.0,
		"spawn_spacing": 0.95,
		"weak_channels": ["light"],
		"resist_channels": ["thorn", "shatter"],
		"weak_specials": ["chain", "execute", "air", "snipe"],
		"resist_specials": ["root", "splash", "multishot", "aoe"],
		"skin": "demon",
		"color": Color(0.7, 0.45, 0.95),
	},
	"brute": {
		"name": "Siege Brutes",
		"short": "BRUTE",
		"blurb": "Heavy ground. Shardbow executes; slows barely stick.",
		"flying": false,
		"hp_mult": 1.85,
		"speed_mult": 0.78,
		"scale_mult": 1.32,
		"path_slack": 8.0,
		"sep_radius": 64.0,
		"min_path_gap": 100.0,
		"spawn_spacing": 1.35,
		"weak_channels": ["light"],
		"resist_channels": ["mist"],
		"weak_specials": ["execute", "snipe"],
		"resist_specials": ["slow_aura", "root"],
		"skin": "demon",
		"color": Color(0.95, 0.4, 0.35),
		"crystal_damage_mult": 1.5,
	},
	"blight": {
		"name": "Blight Spores",
		"short": "BLIGHT",
		"blurb": "Ground cloud. Thorns & splash melt them.",
		"flying": false,
		"hp_mult": 0.95,
		"speed_mult": 1.1,
		"scale_mult": 0.95,
		"path_slack": 24.0,
		"sep_radius": 46.0,
		"min_path_gap": 65.0,
		"spawn_spacing": 0.75,
		"weak_channels": ["thorn", "shatter"],
		"resist_channels": [],
		"weak_specials": ["splash", "multishot", "aoe"],
		"resist_specials": ["chain"],
		"skin": "slime",
		"color": Color(0.45, 0.85, 0.55),
	},
	"wraith": {
		"name": "Night Wraiths",
		"short": "WRAITH",
		"blurb": "Air hunters. Skyshard chains melt them.",
		"flying": true,
		"hp_mult": 1.15,
		"speed_mult": 1.18,
		"scale_mult": 1.05,
		"path_slack": 30.0,
		"sep_radius": 54.0,
		"min_path_gap": 85.0,
		"spawn_spacing": 1.0,
		"weak_channels": ["light"],
		"resist_channels": ["thorn", "shatter"],
		"weak_specials": ["chain", "air", "execute"],
		"resist_specials": ["splash", "root", "multishot", "aoe"],
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


func is_flying(kind_id: String) -> bool:
	return bool(def_for(kind_id).get("flying", false))


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
	if bool(d.get("flying", false)):
		add.call("Skyshard")
		add.call("Shardbow")
	for ch in d.get("weak_channels", []):
		match str(ch):
			"thorn":
				add.call("Thornspire")
			"light":
				if not bool(d.get("flying", false)):
					add.call("Shardbow")
			"mist":
				add.call("Mistvent")
			"shatter":
				add.call("Emberfall")
	for sp in d.get("weak_specials", []):
		match str(sp):
			"splash", "aoe":
				add.call("Emberfall")
			"chain", "air":
				add.call("Skyshard")
			"root", "control":
				add.call("Rootgate")
			"slow_aura":
				add.call("Mistvent")
			"multishot":
				add.call("Thornspire")
			"execute", "snipe":
				add.call("Shardbow")
	if tips.is_empty():
		return "Best: any tower"
	return "Best: " + ", ".join(tips)
