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

# DawnLike (CC-BY 4.0) — 16×16 atlas sheets
const DAWNLIKE_DEMON0 := DAWNLIKE_CHAR_DIR + "Demon0.png"
const DAWNLIKE_DEMON1 := DAWNLIKE_CHAR_DIR + "Demon1.png"
const DAWNLIKE_UNDEAD0 := DAWNLIKE_CHAR_DIR + "Undead0.png"
const DAWNLIKE_PEST0 := DAWNLIKE_CHAR_DIR + "Pest0.png"
const DAWNLIKE_TREE0 := DAWNLIKE_OBJ_DIR + "Tree0.png"

# Kenney roguelike dungeon spritesheet
const ROGUELIKE_DUNGEON := ROGUELIKE_DIR + "roguelikeDungeon_transparent.png"

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
