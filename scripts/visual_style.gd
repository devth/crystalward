extends Node
## Crystalward visual language — Dark Crystal / ethereal forest.
## Autoloaded as VisualStyle.

const OUTLINE := Color(0.06, 0.04, 0.12, 0.95)
const SHADOW := Color(0.02, 0.02, 0.06, 0.5)
const P1_TINT := Color(0.45, 0.9, 0.85)   # cyan crystal warden
const P2_TINT := Color(0.75, 0.55, 0.95)  # violet shadow warden
const PATH_DIRT := Color(0.28, 0.2, 0.28, 0.95)
const TOWER_MOSS := Color(0.28, 0.42, 0.38)
const ESSENCE_GLOW := Color(0.45, 0.95, 0.9)
const CRYSTAL_CORE := Color(0.55, 0.88, 0.95)
const UI_CREAM := Color(0.92, 0.9, 0.98)
const UI_INK := Color(0.1, 0.08, 0.14)
# Title-screen forest palette (purple mist + teal crystal + deep moss)
const FOREST_DEEP := Color(0.08, 0.12, 0.14)
const FOREST_MOSS := Color(0.18, 0.32, 0.26)
const FOREST_MIST := Color(0.35, 0.28, 0.48)
const LEGEND_MEADOW := Color(0.22, 0.38, 0.32)
const LEGEND_BLOOM := Color(0.65, 0.45, 0.85)
const LEGEND_GOLDEN_HOUR := Color(0.85, 0.75, 0.4)

## Z layers — ground always under actors. Never use Main y_sort (covers north map).
const Z_GROUND := -200
const Z_PATH := -180
const Z_PROP_BASE := 0      # + int(y) for decor
const Z_ACTOR_BASE := 5000  # + int(y) — always above all ground props


func actor_z(world_y: float, height: float = 0.0) -> int:
	## Stable draw order: higher world Y (south) draws later; height lifts slightly.
	return Z_ACTOR_BASE + int(world_y) - int(height * 0.1)


func prop_z(world_y: float) -> int:
	return Z_PROP_BASE + int(world_y)

var _outline_shader: Shader
var _outline_mat: ShaderMaterial


func _ready() -> void:
	_outline_shader = load("res://shaders/sprite_outline.gdshader") as Shader
	if _outline_shader:
		_outline_mat = ShaderMaterial.new()
		_outline_mat.shader = _outline_shader
		_outline_mat.set_shader_parameter("outline_color", OUTLINE)
		_outline_mat.set_shader_parameter("outline_width", 1.15)


func apply_sprite_outline(sprite: CanvasItem, width: float = 1.15) -> void:
	if sprite == null:
		return
	if _outline_shader == null:
		_outline_shader = load("res://shaders/sprite_outline.gdshader") as Shader
	if _outline_shader == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = _outline_shader
	mat.set_shader_parameter("outline_color", OUTLINE)
	mat.set_shader_parameter("outline_width", width)
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
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.1, 0.9))
	label.add_theme_constant_override("outline_size", 5)


func style_hud_panel(panel: PanelContainer) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.1, 0.92)
	sb.set_corner_radius_all(12)
	sb.border_color = Color(0.45, 0.7, 0.75, 0.4)
	sb.set_border_width_all(1)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)
