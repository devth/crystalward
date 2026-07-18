extends Node
## Crystalward visual language — The Dark Crystal / Thra ethereal palette.
## Autoloaded as VisualStyle.
## Reference: deep Astronomist violet, Bismark steel-blue, River Green teal,
## pure crystal lavender-white, soft amber light flex (Froud fairy-tale grade).

# ── Dark Crystal core swatches ──────────────────────────────────────────────
## #473B6E Astronomist — castle stone / night shadow
const ASTRONOMIST := Color(0.278, 0.231, 0.431)
## #456988 Bismark — mist, water, cold stone
const BISMARK := Color(0.271, 0.412, 0.533)
## #6DA195 River Green — Thra moss / living green
const RIVER_GREEN := Color(0.427, 0.631, 0.584)
## Pure Crystal heart (clear gem + violet energy)
const CRYSTAL_WHITE := Color(0.93, 0.90, 0.98)
const CRYSTAL_AMETHYST := Color(0.62, 0.48, 0.82)
const CRYSTAL_TEAL_FACET := Color(0.45, 0.72, 0.68)
## Light-flex warm accents (film fairy-tale grade — sparingly)
const THRA_AMBER := Color(0.90, 0.78, 0.48)
const DUST_ROSE := Color(0.78, 0.55, 0.62)
const SKY_VIOLET := Color(0.42, 0.35, 0.58)

# ── Gameplay tokens ─────────────────────────────────────────────────────────
# Soft ink wash (semi-transparent — painted edge, not arcade stroke)
const OUTLINE := Color(0.14, 0.09, 0.18, 0.72)
const SHADOW := Color(0.12, 0.08, 0.16, 0.38)
const P1_TINT := Color(0.55, 0.88, 0.90)   # soft crystal cyan warden
const P2_TINT := Color(0.78, 0.58, 0.92)  # amethyst warden
const PATH_DIRT := Color(0.42, 0.38, 0.40, 0.95)  # cool mauve-taupe trail
const TOWER_MOSS := Color(0.38, 0.55, 0.48)
const ESSENCE_GLOW := Color(0.72, 0.88, 0.92)
const CRYSTAL_CORE := Color(0.78, 0.72, 0.95)
const UI_CREAM := Color(0.94, 0.92, 0.98)
const UI_INK := Color(0.12, 0.09, 0.18)

# Ethereal Thra glade
const FOREST_DEEP := Color(0.12, 0.16, 0.18)
const FOREST_MOSS := Color(0.28, 0.42, 0.38)
const FOREST_MIST := Color(0.48, 0.40, 0.62)
const LEGEND_MEADOW := Color(0.36, 0.52, 0.46)
const LEGEND_BLOOM := Color(0.72, 0.52, 0.78)
const LEGEND_GOLDEN_HOUR := Color(0.90, 0.78, 0.48)
const PASTEL_BLUSH := Color(0.82, 0.62, 0.70)
const PASTEL_LILAC := Color(0.68, 0.58, 0.88)
const PASTEL_MINT := Color(0.52, 0.78, 0.72)
const CHAMPAGNE := Color(0.90, 0.82, 0.58)

## Z layers — ground always under actors. Never use Main y_sort (covers north map).
## Godot CanvasItem.z_index is clamped to [-4096, 4096]; stay well inside that.
const Z_GROUND := -200
const Z_PATH := -180
const Z_PROP_BASE := 0
## Actors map world Y into a positive band so they always draw above Ground (z≈-200).
const Z_ACTOR_MIN := 50
const Z_ACTOR_MAX := 4000
const Z_WORLD_Y_BIAS := 2000  # world y -2000..2000 → mapped 0..4000


func actor_z(world_y: float, height: float = 0.0) -> int:
	## Higher world Y (south) draws later; always above ground art.
	var z := Z_ACTOR_MIN + int(world_y) + Z_WORLD_Y_BIAS - int(height * 0.1)
	return clampi(z, Z_ACTOR_MIN, Z_ACTOR_MAX)


func prop_z(world_y: float) -> int:
	return clampi(Z_PROP_BASE + int(world_y), -4000, 4000)

var _outline_shader: Shader
var _outline_mat: ShaderMaterial


func _ready() -> void:
	_outline_shader = load("res://shaders/sprite_outline.gdshader") as Shader
	if _outline_shader:
		_outline_mat = ShaderMaterial.new()
		_outline_mat.shader = _outline_shader
		_outline_mat.set_shader_parameter("outline_color", OUTLINE)
		_outline_mat.set_shader_parameter("outline_width", 1.2)
		_outline_mat.set_shader_parameter("wash", 0.5)


func apply_sprite_outline(sprite: CanvasItem, width: float = 1.35) -> void:
	if sprite == null:
		return
	if _outline_shader == null:
		_outline_shader = load("res://shaders/sprite_outline.gdshader") as Shader
	if _outline_shader == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = _outline_shader
	mat.set_shader_parameter("outline_color", OUTLINE)
	# Soft ink edge — readable without hard gamey stroke
	mat.set_shader_parameter("outline_width", maxf(width, 1.1))
	mat.set_shader_parameter("wash", 0.5)
	sprite.material = mat


func make_blob_shadow(parent: Node2D, rx: float = 18.0, ry: float = 8.0, y: float = 10.0) -> Polygon2D:
	var shadow := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * float(i) / 20.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	shadow.polygon = pts
	shadow.color = SHADOW
	shadow.position = Vector2(0, y)
	shadow.z_index = -3
	parent.add_child(shadow)
	return shadow


func style_game_label(label: Label, size: int = 16, cream: bool = true) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", UI_CREAM if cream else UI_INK)
	label.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.12, 0.92))
	label.add_theme_constant_override("outline_size", 5)


func style_hud_panel(panel: PanelContainer) -> void:
	var sb := StyleBoxFlat.new()
	# Parchment-dark panel (illustration matte, not neon UI chrome)
	sb.bg_color = Color(0.09, 0.07, 0.12, 0.88)
	sb.set_corner_radius_all(10)
	sb.border_color = Color(0.48, 0.38, 0.58, 0.4)
	sb.set_border_width_all(1)
	sb.shadow_color = Color(0.06, 0.03, 0.1, 0.4)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)
