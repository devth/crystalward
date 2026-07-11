extends Node
## Central paths + loaders for vendored third-party textures (CC0 / CC-BY).
## Autoloaded as `AssetPaths`. Missing files return null so gameplay can fall back.

const PARTICLE_DIR := "res://assets/third_party/kenney_particle_pack/PNG (Transparent)/"
const UI_GREY_DIR := "res://assets/third_party/kenney_ui_pack/PNG/Grey/Default/"
const FOREST_DIR := "res://assets/third_party/seasons_of_forest_free/textures/"
const DAWNLIKE_CHAR_DIR := "res://assets/third_party/dawnlike/Characters/"
const DAWNLIKE_OBJ_DIR := "res://assets/third_party/dawnlike/Objects/"
const SMOKE_DIR := "res://assets/third_party/kenney_smoke_particles/PNG/"
const ROGUELIKE_DIR := "res://assets/third_party/kenney_roguelike_caves_dungeons/Spritesheet/"
const SCENERY_DIR := "res://assets/third_party/misc_dark_fantasy_scenery/"
const ITEMS_DIR := "res://assets/third_party/dark_fantasy_items/"
const CREATURES_DIR := "res://assets/third_party/assorted_32x32_creatures/"
const GROTESQUE_DIR := "res://assets/third_party/grotesque_surreal_creature/"
const CRITTERS_DIR := "res://assets/third_party/critters_32x32_cc0/"
const HAUNTED_DIR := "res://assets/third_party/haunted_forest_trees/"
const BOTANICAL_DIR := "res://assets/third_party/oga_plants/"
const LIMBO_DIR := "res://assets/third_party/limbo_land_monsters/"
const KENNEY_TDS_DIR := "res://assets/third_party/kenney_top_down_shooter/"
const KENNEY_CHAR_DIR := "res://assets/third_party/kenney_platformer_characters/"

# Kenney Particle Pack — soft FX stamps
const PARTICLE_CIRCLE_SOFT := PARTICLE_DIR + "circle_05.png"
const PARTICLE_CIRCLE := PARTICLE_DIR + "circle_01.png"
const PARTICLE_SPARK := PARTICLE_DIR + "spark_05.png"
const PARTICLE_GLOW := PARTICLE_DIR + "light_01.png"
const PARTICLE_STAR := PARTICLE_DIR + "star_01.png"
const PARTICLE_MAGIC := PARTICLE_DIR + "magic_05.png"
const PARTICLE_SMOKE := PARTICLE_DIR + "smoke_04.png"
const PARTICLE_FLARE := PARTICLE_DIR + "flare_01.png"

# Kenney Smoke Particles
const SMOKE_WHITE_PUFF := SMOKE_DIR + "White puff/whitePuff00.png"
const SMOKE_FLASH := SMOKE_DIR + "Flash/flash00.png"

# Kenney UI (grey set — reads as dark fantasy under purple modulate)
const UI_BUTTON_RECT := UI_GREY_DIR + "button_rectangle_depth_flat.png"
const UI_BUTTON_SQUARE := UI_GREY_DIR + "button_square_depth_flat.png"
const UI_SLIDER_H := UI_GREY_DIR + "slide_horizontal_grey.png"

# Seasons of Forest free sample
const FOREST_TREES := FOREST_DIR + "trees.png"
const FOREST_STONES := FOREST_DIR + "stones.png"
const FOREST_BUSHES := FOREST_DIR + "bushes.png"
const FOREST_GRASS := FOREST_DIR + "grass.png"
const FOREST_GRASS_DIRT := FOREST_DIR + "grass_dirt.png"

# DawnLike (CC-BY 4.0) — 16×16 atlas sheets (frame 0 / 1 for walk flip)
const DAWNLIKE_DEMON0 := DAWNLIKE_CHAR_DIR + "Demon0.png"
const DAWNLIKE_DEMON1 := DAWNLIKE_CHAR_DIR + "Demon1.png"
const DAWNLIKE_UNDEAD0 := DAWNLIKE_CHAR_DIR + "Undead0.png"
const DAWNLIKE_UNDEAD1 := DAWNLIKE_CHAR_DIR + "Undead1.png"
const DAWNLIKE_PEST0 := DAWNLIKE_CHAR_DIR + "Pest0.png"
const DAWNLIKE_PEST1 := DAWNLIKE_CHAR_DIR + "Pest1.png"
const DAWNLIKE_QUADRAPED0 := DAWNLIKE_CHAR_DIR + "Quadraped0.png"
const DAWNLIKE_QUADRAPED1 := DAWNLIKE_CHAR_DIR + "Quadraped1.png"
const DAWNLIKE_ELEMENTAL0 := DAWNLIKE_CHAR_DIR + "Elemental0.png"
const DAWNLIKE_ELEMENTAL1 := DAWNLIKE_CHAR_DIR + "Elemental1.png"
const DAWNLIKE_HUMANOID0 := DAWNLIKE_CHAR_DIR + "Humanoid0.png"
const DAWNLIKE_HUMANOID1 := DAWNLIKE_CHAR_DIR + "Humanoid1.png"
const DAWNLIKE_PLANT0 := DAWNLIKE_CHAR_DIR + "Plant0.png"
const DAWNLIKE_PLANT1 := DAWNLIKE_CHAR_DIR + "Plant1.png"
const DAWNLIKE_SLIME0 := DAWNLIKE_CHAR_DIR + "Slime0.png"
const DAWNLIKE_SLIME1 := DAWNLIKE_CHAR_DIR + "Slime1.png"
const DAWNLIKE_REPTILE0 := DAWNLIKE_CHAR_DIR + "Reptile0.png"
const DAWNLIKE_REPTILE1 := DAWNLIKE_CHAR_DIR + "Reptile1.png"
const DAWNLIKE_MISC0 := DAWNLIKE_CHAR_DIR + "Misc0.png"
const DAWNLIKE_MISC1 := DAWNLIKE_CHAR_DIR + "Misc1.png"
const DAWNLIKE_AQUATIC0 := DAWNLIKE_CHAR_DIR + "Aquatic0.png"
const DAWNLIKE_AVIAN0 := DAWNLIKE_CHAR_DIR + "Avian0.png"
const DAWNLIKE_TREE0 := DAWNLIKE_OBJ_DIR + "Tree0.png"
const DAWNLIKE_TREE1 := DAWNLIKE_OBJ_DIR + "Tree1.png"

# OpenGameArt / Kenney packs (CC0 unless noted)
const MISC_DARK_SCENERY := SCENERY_DIR + "misc_scenery.png"
const DARK_FANTASY_ITEMS := ITEMS_DIR + "00_items.png"
const ASSORTED_CREATURES := CREATURES_DIR + "creatures_3.png"
const ASSORTED_CREATURES_HI := CREATURES_DIR + "creatures_3-export_1.png"
const GROTESQUE_CREATURE := GROTESQUE_DIR + "Pixel_Creature2_png.png"  # CC-BY 3.0
const CRITTERS_SHEET := CRITTERS_DIR + "anymals_32_for_edit.png"
const CRITTERS_SHEET_B := CRITTERS_DIR + "anymals_the_second_colle.png"
const HAUNTED_TREES := HAUNTED_DIR + "spooky_trees.png"
## CC0 plant/flower atlas (OpenGameArt “Flowers” — 78 plants)
const BOTANICAL_PLANTS := BOTANICAL_DIR + "plants.png"
const LIMBO_IDLE_1 := LIMBO_DIR + "idle/frame-1.png"
const LIMBO_IDLE_2 := LIMBO_DIR + "idle/frame-2.png"
const KENNEY_ZOMBIE_STAND := KENNEY_TDS_DIR + "PNG/Zombie 1/zoimbie1_stand.png"

# Kenney roguelike dungeon spritesheet
const ROGUELIKE_DUNGEON := ROGUELIKE_DIR + "roguelikeDungeon_transparent.png"

## Soft playable world rect (± half-extent).
const WORLD_BOUND := 1800.0
const WORLD_FLOOR_EXTENT := 2200.0

var _cache: Dictionary = {}


func has_file(path: String) -> bool:
	if path.is_empty():
		return false
	var global := ProjectSettings.globalize_path(path)
	return FileAccess.file_exists(path) or FileAccess.file_exists(global)


func load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _cache.has(path):
		return _cache[path] as Texture2D

	# Prefer fully imported Godot textures when .import metadata exists.
	var import_sidecar := path + ".import"
	if FileAccess.file_exists(import_sidecar) and ResourceLoader.exists(path):
		var res: Resource = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
		if res is Texture2D:
			_cache[path] = res
			return res as Texture2D

	# Raw PNG load — works headless / pre-import without error spam.
	var global := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(global):
		return null
	var img := Image.new()
	if img.load(global) != OK:
		return null
	var tex := ImageTexture.create_from_image(img)
	_cache[path] = tex
	return tex


func atlas_region(path: String, region: Rect2) -> Texture2D:
	var base := load_texture(path)
	if base == null:
		return null
	var key := "%s@%s" % [path, str(region)]
	if _cache.has(key):
		return _cache[key] as Texture2D
	var at := AtlasTexture.new()
	at.atlas = base
	at.region = region
	at.filter_clip = false
	_cache[key] = at
	return at


## DawnLike character cell (16×16 grid).
func dawnlike_cell(path: String, col: int, row: int, cell: int = 16) -> Texture2D:
	return atlas_region(path, Rect2(col * cell, row * cell, cell, cell))


## Frame pair for simple walk flip (sheet0 / sheet1).
func dawnlike_frames(path0: String, path1: String, col: int, row: int) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	var a := dawnlike_cell(path0, col, row)
	var b := dawnlike_cell(path1, col, row)
	if a:
		out.append(a)
	if b:
		out.append(b)
	return out


## Load a Kenney platformer character pose (80×110, 2.5D side view).
func kenney_pose(folder: String, prefix: String, pose: String) -> Texture2D:
	return load_texture("%s%s/%s_%s.png" % [KENNEY_CHAR_DIR, folder, prefix, pose])


func _kenney_anim_set(folder: String, prefix: String) -> Dictionary:
	var stand := kenney_pose(folder, prefix, "stand")
	var idle := kenney_pose(folder, prefix, "idle")
	var w1 := kenney_pose(folder, prefix, "walk1")
	var w2 := kenney_pose(folder, prefix, "walk2")
	var jump := kenney_pose(folder, prefix, "jump")
	var fall := kenney_pose(folder, prefix, "fall")
	var a1 := kenney_pose(folder, prefix, "action1")
	var a2 := kenney_pose(folder, prefix, "action2")
	var idle_frames: Array[Texture2D] = []
	if stand:
		idle_frames.append(stand)
	if idle and idle != stand:
		idle_frames.append(idle)
	if idle_frames.is_empty() and w1:
		idle_frames.append(w1)
	var walk_frames: Array[Texture2D] = []
	if w1:
		walk_frames.append(w1)
	if w2:
		walk_frames.append(w2)
	if walk_frames.is_empty():
		walk_frames = idle_frames.duplicate()
	return {
		"idle": idle_frames,
		"walk": walk_frames,
		"jump": [jump] if jump else idle_frames,
		"fall": [fall] if fall else ([jump] if jump else idle_frames),
		"attack": ([a1, a2] if a1 and a2 else (idle_frames)),
		# Backward-compat: simple frame flip list = walk
		"frames": walk_frames if not walk_frames.is_empty() else idle_frames,
	}


## 2.5D warden skins (Kenney Platformer Characters — CC0).
## Returns anim dict: idle/walk/jump/fall/attack arrays + scale + modulate.
func warden_skin(player_index: int) -> Dictionary:
	var folder := "Adventurer"
	var prefix := "adventurer"
	var modulate := Color(1.0, 1.0, 1.0)
	if player_index == 0:
		folder = "Soldier"
		prefix = "soldier"
		modulate = Color(0.85, 1.0, 0.92)  # slight teal-iron tint for P1
	else:
		folder = "Adventurer"
		prefix = "adventurer"
		modulate = Color(1.0, 0.92, 0.88)  # warm for P2
	var anim := _kenney_anim_set(folder, prefix)
	# Fallback to Female if missing
	if (anim.get("frames") as Array).is_empty():
		anim = _kenney_anim_set("Female", "female")
		modulate = Color(0.95, 0.9, 1.0)
	anim["modulate"] = modulate
	anim["scale"] = 1.25  # 80×110 — punchy 2.5D silhouette on the field
	anim["style"] = "kenney_25d"
	return anim


## Nightspawn skins — zombie 2.5D walk cycle + tint variants.
func random_enemy_skin() -> Dictionary:
	var anim := _kenney_anim_set("Zombie", "zombie")
	var modulate := Color(0.85, 0.75, 0.9)
	var roll := randi() % 100
	if roll < 35:
		modulate = Color(0.75, 0.9, 0.7)  # moss thrall
	elif roll < 60:
		modulate = Color(0.9, 0.55, 0.55)  # blood thrall
	elif roll < 80:
		modulate = Color(0.65, 0.7, 0.95)  # night thrall
	else:
		modulate = Color(0.95, 0.85, 0.55)  # cursed thrall
	if (anim.get("frames") as Array).is_empty():
		# Last resort: dawnlike (tiny) so something shows
		var frames := dawnlike_frames(DAWNLIKE_DEMON0, DAWNLIKE_DEMON1, 0, 0)
		return {"frames": frames, "walk": frames, "idle": frames, "modulate": modulate, "scale": 3.2, "style": "dawnlike"}
	anim["modulate"] = modulate
	anim["scale"] = 1.0
	anim["style"] = "kenney_25d"
	return anim


func particle_texture(kind: String = "circle_soft") -> Texture2D:
	var path := PARTICLE_CIRCLE_SOFT
	match kind:
		"circle_soft", "soft", "circle":
			path = PARTICLE_CIRCLE_SOFT
		"spark":
			path = PARTICLE_SPARK
		"glow", "light":
			path = PARTICLE_GLOW
		"star":
			path = PARTICLE_STAR
		"magic":
			path = PARTICLE_MAGIC
		"smoke":
			path = PARTICLE_SMOKE
		"flare":
			path = PARTICLE_FLARE
		"puff":
			path = SMOKE_WHITE_PUFF
		"flash":
			path = SMOKE_FLASH
		_:
			path = PARTICLE_CIRCLE_SOFT
	var tex := load_texture(path)
	if tex == null and path != PARTICLE_CIRCLE_SOFT:
		tex = load_texture(PARTICLE_CIRCLE_SOFT)
	return tex


func make_pixel_sprite(tex: Texture2D, scale_mul: float = 3.0, centered: bool = true) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = centered
	s.scale = Vector2(scale_mul, scale_mul)
	return s


func clamp_to_world(pos: Vector2, bound: float = WORLD_BOUND) -> Vector2:
	return Vector2(clampf(pos.x, -bound, bound), clampf(pos.y, -bound, bound))
