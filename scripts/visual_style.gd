extends Node
## PixelJunk-inspired visual language: outlines, palette, helpers.
## Autoloaded as VisualStyle.

const OUTLINE := Color(0.1, 0.07, 0.14, 0.95)
const SHADOW := Color(0.05, 0.04, 0.1, 0.45)
const P1_TINT := Color(0.55, 0.85, 0.75)
const P2_TINT := Color(0.9, 0.6, 0.85)
const PATH_DIRT := Color(0.45, 0.32, 0.22, 0.92)
const TOWER_MOSS := Color(0.35, 0.55, 0.4)
const ESSENCE_GLOW := Color(0.45, 0.95, 0.9)
const CRYSTAL_CORE := Color(0.85, 0.7, 1.0)
const UI_CREAM := Color(0.98, 0.95, 0.9)
const UI_INK := Color(0.12, 0.1, 0.16)
# Legend (1985) botanical palette
const LEGEND_MEADOW := Color(0.4, 0.6, 0.38)
const LEGEND_BLOOM := Color(0.95, 0.55, 0.7)
const LEGEND_GOLDEN_HOUR := Color(0.95, 0.88, 0.55)

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
	sb.bg_color = Color(0.06, 0.07, 0.09, 0.92)
	sb.set_corner_radius_all(10)
	sb.border_color = Color(0.55, 0.48, 0.35, 0.55)
	sb.set_border_width_all(1)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)
