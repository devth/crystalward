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
const LIMBO_DIR := "res://assets/third_party/limbo_land_monsters/"
const KENNEY_TDS_DIR := "res://assets/third_party/kenney_top_down_shooter/"

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
	at.filter_clip = true
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


## Organic / puppet-like warden skins (Dark Crystal–esque). Prefer elemental/plant/weird over cute humans.
func warden_skin(player_index: int) -> Dictionary:
	# Returns { "frames": Array[Texture2D], "modulate": Color, "scale": float }
	var frames: Array[Texture2D] = []
	var modulate := Color(0.55, 0.75, 0.7)
	var scale_mul := 3.6
	if player_index == 0:
		# Living moss / crystal-flesh elemental
		modulate = Color(0.55, 0.75, 0.7)
		frames = dawnlike_frames(DAWNLIKE_ELEMENTAL0, DAWNLIKE_ELEMENTAL1, 1, 2)
		if frames.is_empty():
			frames = dawnlike_frames(DAWNLIKE_PLANT0, DAWNLIKE_PLANT1, 0, 0)
		if frames.is_empty():
			frames = dawnlike_frames(DAWNLIKE_HUMANOID0, DAWNLIKE_HUMANOID1, 2, 3)
	else:
		# Dark crystalline / gelfling-shadow humanoid
		modulate = Color(0.75, 0.55, 0.85)
		frames = dawnlike_frames(DAWNLIKE_ELEMENTAL0, DAWNLIKE_ELEMENTAL1, 3, 1)
		if frames.is_empty():
			frames = dawnlike_frames(DAWNLIKE_HUMANOID0, DAWNLIKE_HUMANOID1, 4, 2)
		if frames.is_empty():
			frames = dawnlike_frames(DAWNLIKE_MISC0, DAWNLIKE_MISC1, 1, 0)
	return {"frames": frames, "modulate": modulate, "scale": scale_mul}


## Random nightspawn skin — demon/undead/pest/quad/slime/plant + optional packs.
func random_enemy_skin() -> Dictionary:
	var roll := randi() % 100
	var frames: Array[Texture2D] = []
	var modulate := Color(0.72, 0.42, 0.62)
	var scale_mul := 3.4

	if roll < 22:
		var c := randi() % 6
		var r := randi() % 4
		frames = dawnlike_frames(DAWNLIKE_DEMON0, DAWNLIKE_DEMON1, c, r)
		modulate = Color(0.7, 0.35, 0.55)
	elif roll < 40:
		var c2 := randi() % 4
		var r2 := randi() % 3
		frames = dawnlike_frames(DAWNLIKE_UNDEAD0, DAWNLIKE_UNDEAD1, c2, r2)
		modulate = Color(0.55, 0.45, 0.7)
	elif roll < 55:
		var c3 := randi() % 6
		var r3 := randi() % 3
		frames = dawnlike_frames(DAWNLIKE_PEST0, DAWNLIKE_PEST1, c3, r3)
		modulate = Color(0.65, 0.4, 0.5)
		scale_mul = 3.0
	elif roll < 68:
		var c4 := randi() % 6
		var r4 := randi() % 4
		frames = dawnlike_frames(DAWNLIKE_QUADRAPED0, DAWNLIKE_QUADRAPED1, c4, r4)
		modulate = Color(0.6, 0.35, 0.48)
	elif roll < 78:
		var c5 := randi() % 4
		var r5 := randi() % 2
		frames = dawnlike_frames(DAWNLIKE_SLIME0, DAWNLIKE_SLIME1, c5, r5)
		modulate = Color(0.55, 0.3, 0.55)
	elif roll < 86:
		var c6 := randi() % 4
		var r6 := randi() % 2
		frames = dawnlike_frames(DAWNLIKE_PLANT0, DAWNLIKE_PLANT1, c6, r6)
		modulate = Color(0.45, 0.55, 0.4)
	elif roll < 92:
		# Assorted 32×32 organic critters (CC0)
		var sheet := ASSORTED_CREATURES if has_file(ASSORTED_CREATURES) else ASSORTED_CREATURES_HI
		var cell := 32 if sheet == ASSORTED_CREATURES else 64
		var cols := 9 if cell == 32 else 9
		var col := randi() % cols
		var row := randi() % cols
		var tex := atlas_region(sheet, Rect2(col * cell, row * cell, cell, cell))
		if tex:
			frames = [tex] as Array[Texture2D]
		modulate = Color(0.75, 0.5, 0.65)
		scale_mul = 2.4 if cell == 32 else 1.4
	elif roll < 96:
		# Monochrome critters — dark recolor
		var ctex := atlas_region(CRITTERS_SHEET, Rect2((randi() % 6) * 32, (randi() % 8) * 32, 32, 32))
		if ctex:
			frames = [ctex] as Array[Texture2D]
		modulate = Color(0.85, 0.35, 0.55)
		scale_mul = 2.2
	else:
		# Rare grotesque / limbo organic boss-feel (scaled down)
		if has_file(LIMBO_IDLE_1) and randf() < 0.55:
			var l1 := load_texture(LIMBO_IDLE_1)
			var l2 := load_texture(LIMBO_IDLE_2)
			if l1:
				frames = [l1] as Array[Texture2D]
			if l2:
				frames.append(l2)
			modulate = Color(0.65, 0.4, 0.7)
			scale_mul = 0.09
		elif has_file(GROTESQUE_CREATURE):
			var g := load_texture(GROTESQUE_CREATURE)
			if g:
				frames = [g] as Array[Texture2D]
			modulate = Color(0.7, 0.45, 0.6)
			scale_mul = 0.055

	if frames.is_empty():
		frames = dawnlike_frames(DAWNLIKE_DEMON0, DAWNLIKE_DEMON1, 0, 0)
		if frames.is_empty():
			var fb := dawnlike_cell(DAWNLIKE_UNDEAD0, 1, 0)
			if fb:
				frames = [fb] as Array[Texture2D]
		modulate = Color(0.7, 0.35, 0.55)
		scale_mul = 3.4

	return {"frames": frames, "modulate": modulate, "scale": scale_mul}


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
