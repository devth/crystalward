extends Node
## Crystalward visual language — ethereal gold + pastel shimmer.
## Autoloaded as VisualStyle.
## Outlines stay strong so actors read clearly on the soft world.

const OUTLINE := Color(0.12, 0.08, 0.18, 0.96)
const SHADOW := Color(0.12, 0.08, 0.16, 0.42)
const P1_TINT := Color(0.55, 0.92, 0.9)   # soft cyan crystal warden
const P2_TINT := Color(0.82, 0.62, 0.95)  # pastel violet warden
const PATH_DIRT := Color(0.48, 0.38, 0.32, 0.95)
const TOWER_MOSS := Color(0.42, 0.58, 0.48)
const ESSENCE_GLOW := Color(0.65, 0.95, 0.92)
const CRYSTAL_CORE := Color(0.7, 0.92, 0.98)
const UI_CREAM := Color(0.97, 0.94, 0.98)
const UI_INK := Color(0.16, 0.12, 0.2)
# Ethereal glade palette — soft gold, sage, lilac pearl
const FOREST_DEEP := Color(0.16, 0.2, 0.22)
const FOREST_MOSS := Color(0.32, 0.48, 0.4)
const FOREST_MIST := Color(0.62, 0.52, 0.78)
const LEGEND_MEADOW := Color(0.4, 0.58, 0.48)
const LEGEND_BLOOM := Color(0.78, 0.58, 0.9)
const LEGEND_GOLDEN_HOUR := Color(0.96, 0.84, 0.5)
const PASTEL_BLUSH := Color(0.92, 0.7, 0.78)
const PASTEL_LILAC := Color(0.75, 0.68, 0.92)
const PASTEL_MINT := Color(0.62, 0.88, 0.78)
const CHAMPAGNE := Color(0.96, 0.88, 0.62)

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
		_outline_mat.set_shader_parameter("outline_width", 1.35)


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
	# Slightly stronger outline so sprites pop on pastel ground
	mat.set_shader_parameter("outline_width", maxf(width, 1.25))
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
