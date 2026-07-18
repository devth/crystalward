extends Node
## Nightspawn kind catalog — one kind per surge, with tower matchups.
## Autoloaded as EnemyKinds.
## `flying: true` = air unit (Skyshard / air targeting). Ground-only towers miss them.

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
	"shade": {
		"name": "Umbrite Shades",
		"short": "FLYER",
		"blurb": "Air spirits of stagnant essence. Light burns them; ground towers miss.",
		"flying": true,
		"hp_mult": 0.95,
		"speed_mult": 1.15,
		"scale_mult": 1.0,
		"path_slack": 32.0,
		"sep_radius": 52.0,
		"min_path_gap": 78.0,
		"spawn_spacing": 0.9,
		"weak_channels": ["light"],
		"resist_channels": ["thorn", "shatter"],
		"weak_specials": ["chain", "execute", "air", "snipe"],
		"resist_specials": ["root", "splash", "multishot", "aoe"],
		"skin": "shade",
		"color": Color(0.7, 0.45, 0.95),
	},
	"ironclad": {
		"name": "Iron Procession",
		"short": "ARMORED",
		"blurb": "Heavy plate. Arcane Prism (magic) cracks them; physical thorns glance.",
		"flying": false,
		"hp_mult": 1.65,
		"speed_mult": 0.72,
		"scale_mult": 1.18,
		"path_slack": 10.0,
		"sep_radius": 56.0,
		"min_path_gap": 90.0,
		"spawn_spacing": 1.15,
		"weak_channels": ["shatter", "light"],
		"resist_channels": ["thorn"],
		"weak_specials": ["arcane", "splash", "aoe"],
		"resist_specials": ["multishot", "arrow", "briar"],
		"skin": "undead",
		"color": Color(0.65, 0.7, 0.85),
	},
	"gloomwing": {
		"name": "Gloomwings",
		"short": "FLYER",
		"blurb": "Flock of night birds. Skyshard chains; ground AOE misses.",
		"flying": true,
		"hp_mult": 0.82,
		"speed_mult": 1.35,
		"scale_mult": 0.9,
		"path_slack": 36.0,
		"sep_radius": 50.0,
		"min_path_gap": 68.0,
		"spawn_spacing": 0.72,
		"weak_channels": ["light", "mist"],
		"resist_channels": ["thorn", "shatter"],
		"weak_specials": ["chain", "air", "slow_aura", "multishot"],
		"resist_specials": ["root", "splash", "aoe"],
		"skin": "avian",
		"color": Color(0.55, 0.65, 0.95),
		"crystal_damage_mult": 0.9,
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
	"wraith": {
		"name": "Night Wraiths",
		"short": "WRAITH",
		"blurb": "Tough air hunters. Skyshard chains melt them.",
		"flying": true,
		"hp_mult": 1.2,
		"speed_mult": 1.18,
		"scale_mult": 1.08,
		"path_slack": 30.0,
		"sep_radius": 54.0,
		"min_path_gap": 85.0,
		"spawn_spacing": 1.0,
		"weak_channels": ["light"],
		"resist_channels": ["thorn", "shatter"],
		"weak_specials": ["chain", "air", "execute", "snipe"],
		"resist_specials": ["splash", "root", "multishot", "aoe"],
		"skin": "wraith",
		"color": Color(0.55, 0.85, 0.95),
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
	"mothswarm": {
		"name": "Mothswarm",
		"short": "FLYER",
		"blurb": "Pest-cloud flyers. Skyshard multi-hops; thorns can't reach.",
		"flying": true,
		"hp_mult": 0.7,
		"speed_mult": 1.42,
		"scale_mult": 0.85,
		"path_slack": 40.0,
		"sep_radius": 46.0,
		"min_path_gap": 60.0,
		"spawn_spacing": 0.65,
		"weak_channels": ["light", "mist"],
		"resist_channels": ["thorn", "shatter"],
		"weak_specials": ["chain", "air", "multishot", "slow_aura"],
		"resist_specials": ["root", "splash", "aoe", "execute"],
		"skin": "moth",
		"color": Color(0.85, 0.7, 0.95),
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
	## ── Level bosses (phase 10 only) — large, slow, very durable ──────────
	"boss_harrow": {
		"name": "Rootfather Harrow",
		"short": "BOSS",
		"blurb": "Grove-warden poisoned by umbrite. Slow colossus of root and sap.",
		"flying": false,
		"boss": true,
		"hp_mult": 9.5,
		"speed_mult": 0.32,
		"scale_mult": 2.55,
		"path_slack": 4.0,
		"sep_radius": 90.0,
		"min_path_gap": 140.0,
		"spawn_spacing": 99.0,
		"weak_channels": ["light", "shatter"],
		"resist_channels": ["mist"],
		"weak_specials": ["splash", "aoe"],
		"resist_specials": ["slow_aura", "root"],
		"skin": "plant",
		"color": Color(0.35, 0.55, 0.28),
		"crystal_damage_mult": 1.0,
		"leak_lives": 2,
		"intro": "Rootfather Harrow comes — the vale’s own guardian, ruined.",
	},
	"boss_fordwidow": {
		"name": "The Ford-Widow",
		"short": "BOSS",
		"blurb": "Maera the ford-keeper, remade in silt and drowned bronze.",
		"flying": false,
		"boss": true,
		"hp_mult": 10.5,
		"speed_mult": 0.34,
		"scale_mult": 2.45,
		"path_slack": 6.0,
		"sep_radius": 88.0,
		"min_path_gap": 135.0,
		"spawn_spacing": 99.0,
		"weak_channels": ["light", "mist"],
		"resist_channels": ["thorn"],
		"weak_specials": ["chain", "magic_bolt"],
		"resist_specials": ["root"],
		"skin": "aquatic",
		"color": Color(0.40, 0.55, 0.72),
		"crystal_damage_mult": 1.0,
		"leak_lives": 2,
		"intro": "The Ford-Widow walks — Maera of the dusk-bell, still ringing.",
	},
	"boss_mirel": {
		"name": "Bog-Crown Mirel",
		"short": "BOSS",
		"blurb": "Fallen moss-abbot under a crown of living peat.",
		"flying": false,
		"boss": true,
		"hp_mult": 12.0,
		"speed_mult": 0.28,
		"scale_mult": 2.7,
		"path_slack": 4.0,
		"sep_radius": 95.0,
		"min_path_gap": 150.0,
		"spawn_spacing": 99.0,
		"weak_channels": ["light", "shatter"],
		"resist_channels": ["mist", "thorn"],
		"weak_specials": ["splash", "aoe", "execute"],
		"resist_specials": ["slow_aura", "root"],
		"skin": "plant",
		"color": Color(0.28, 0.42, 0.32),
		"crystal_damage_mult": 1.0,
		"leak_lives": 3,
		"intro": "Bog-Crown Mirel rises — the temple’s mistake on root-legs.",
	},
	"boss_vesk": {
		"name": "Marshal Vesk",
		"short": "BOSS",
		"blurb": "Umbrael’s field marshal in umbrite plate. Believes the dusk is mercy.",
		"flying": false,
		"boss": true,
		"hp_mult": 13.5,
		"speed_mult": 0.36,
		"scale_mult": 2.5,
		"path_slack": 3.0,
		"sep_radius": 92.0,
		"min_path_gap": 145.0,
		"spawn_spacing": 99.0,
		"weak_channels": ["light"],
		"resist_channels": ["mist", "thorn"],
		"weak_specials": ["execute", "snipe", "magic_bolt"],
		"resist_specials": ["slow_aura", "root", "multishot"],
		"skin": "demon",
		"color": Color(0.55, 0.35, 0.32),
		"crystal_damage_mult": 1.0,
		"leak_lives": 3,
		"intro": "Marshal Vesk: “Stand aside. The Crystal is killing itself.”",
	},
	"boss_umbrael": {
		"name": "Lord Umbrael",
		"short": "BOSS",
		"blurb": "Traitor of the Castle Court. Umbrite-crowned. The campaign’s end.",
		"flying": false,
		"boss": true,
		"hp_mult": 16.0,
		"speed_mult": 0.30,
		"scale_mult": 2.9,
		"path_slack": 2.0,
		"sep_radius": 100.0,
		"min_path_gap": 160.0,
		"spawn_spacing": 99.0,
		"weak_channels": ["light"],
		"resist_channels": ["thorn", "mist"],
		"weak_specials": ["execute", "snipe", "magic_bolt", "splash"],
		"resist_specials": ["slow_aura", "root", "multishot"],
		"skin": "demon",
		"color": Color(0.42, 0.28, 0.55),
		"crystal_damage_mult": 1.0,
		"leak_lives": 4,
		"intro": "Lord Umbrael comes for the Gate. Hold the tether.",
	},
}

## Wave cycle for phases 1–9. Phase 10 is always the map boss (see Campaign).
const WAVE_ORDER: Array[String] = [
	"thrall",      # 1 ground
	"shade",       # 2 flyer
	"ironclad",    # 3 ground
	"gloomwing",   # 4 flyer
	"skitter",     # 5 ground
	"wraith",      # 6 flyer
	"brute",       # 7 ground
	"mothswarm",   # 8 flyer
	"blight",      # 9 ground
]


func kind_for_wave(wave: int) -> String:
	## Regular phases only. Boss phase is resolved by WaveManager + Campaign.
	if WAVE_ORDER.is_empty():
		return "thrall"
	var i := (maxi(1, wave) - 1) % WAVE_ORDER.size()
	return WAVE_ORDER[i]


func is_boss(kind_id: String) -> bool:
	return bool(def_for(kind_id).get("boss", false))


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
		add.call("Skyshard (AIR)")
		add.call("Shardbow")
	for ch in d.get("weak_channels", []):
		match str(ch):
			"thorn":
				if not bool(d.get("flying", false)):
					add.call("Thornspire")
			"light":
				if not bool(d.get("flying", false)):
					add.call("Shardbow")
			"mist":
				add.call("Mistvent")
			"shatter":
				if not bool(d.get("flying", false)):
					add.call("Emberfall")
	for sp in d.get("weak_specials", []):
		match str(sp):
			"splash", "aoe":
				if not bool(d.get("flying", false)):
					add.call("Emberfall")
			"chain", "air":
				add.call("Skyshard")
			"root", "control":
				if not bool(d.get("flying", false)):
					add.call("Rootgate")
			"slow_aura":
				add.call("Mistvent")
			"multishot":
				if not bool(d.get("flying", false)):
					add.call("Thornspire")
			"execute", "snipe":
				add.call("Shardbow")
	if tips.is_empty():
		return "Best: any tower"
	return "Best: " + ", ".join(tips)
