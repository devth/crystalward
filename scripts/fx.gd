extends Node
## VFX helpers — Kenney particle textures when present, procedural fallbacks otherwise.
## Autoloaded as `FX`.


func make_circle_poly(radius: float, points: int = 28, color: Color = Color.WHITE) -> Polygon2D:
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in points:
		var a := TAU * float(i) / float(points)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	poly.polygon = pts
	poly.color = color
	return poly


func make_ellipse_poly(rx: float, ry: float, points: int = 28, color: Color = Color.WHITE) -> Polygon2D:
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in points:
		var a := TAU * float(i) / float(points)
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	poly.polygon = pts
	poly.color = color
	return poly


func make_shader_rect(size: Vector2, shader: Shader, centered: bool = true) -> ColorRect:
	var rect := ColorRect.new()
	rect.size = size
	if centered:
		rect.position = -size * 0.5
	var mat := ShaderMaterial.new()
	mat.shader = shader
	rect.material = mat
	return rect


func add_soft_shadow(parent: Node2D, rx: float = 18.0, ry: float = 8.0, y_off: float = 10.0) -> Polygon2D:
	var shadow := make_ellipse_poly(rx, ry, 24, Color(0, 0, 0, 0.4))
	shadow.position = Vector2(0, y_off)
	shadow.z_index = -2
	parent.add_child(shadow)
	return shadow


func _procedural_circle_tex(size: int = 8) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := (size - 1) * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x - c, y - c).length()
			var a := clampf(1.0 - d / c, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	return ImageTexture.create_from_image(img)


func _particle_tex_for(kind: String) -> Texture2D:
	var tex: Texture2D = AssetPaths.particle_texture(kind)
	if tex == null:
		tex = _procedural_circle_tex(8)
	return tex


## Kenney PNGs are large (~512px); scale them way down for GPU particles.
func _scale_for_texture(tex: Texture2D, base_min: float, base_max: float) -> Vector2:
	if tex == null:
		return Vector2(base_min, base_max)
	var w := float(tex.get_width())
	if w <= 16.0:
		return Vector2(base_min, base_max)
	# Target ~8–20 world pixels
	var target := 12.0
	var s := target / w
	return Vector2(s * (base_min / 2.0), s * (base_max / 2.0))


func spark_particles(parent: Node, color: Color, amount: int = 18, kind: String = "circle_soft") -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = amount
	p.lifetime = 1.4
	p.preprocess = 0.4
	p.explosiveness = 0.0
	p.randomness = 0.6
	p.local_coords = false
	p.z_index = 5

	var tex := _particle_tex_for(kind)
	p.texture = tex

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 8.0
	mat.initial_velocity_max = 28.0
	mat.gravity = Vector3(0, -6, 0)
	var scales := _scale_for_texture(tex, 1.2, 2.8)
	mat.scale_min = scales.x
	mat.scale_max = scales.y
	mat.color = color
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color(color.r, color.g, color.b, 0.0),
		Color(color.r, color.g, color.b, 0.9),
		Color(color.r, color.g, color.b, 0.0),
	])
	grad.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	mat.color_ramp = ramp
	p.process_material = mat

	parent.add_child(p)
	return p


## One-shot burst (attack / death / build). Auto-frees after lifetime.
func burst_particles(
	parent: Node,
	world_pos: Vector2,
	color: Color,
	amount: int = 16,
	kind: String = "spark",
	lifetime: float = 0.5
) -> GPUParticles2D:
	if parent == null:
		return null
	var p := spark_particles(parent, color, amount, kind)
	p.global_position = world_pos
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = lifetime
	p.preprocess = 0.0
	p.emitting = true
	var pm := p.process_material as ParticleProcessMaterial
	if pm:
		pm.initial_velocity_min = 40.0
		pm.initial_velocity_max = 100.0
		pm.gravity = Vector3(0, 50, 0)
	var tree := parent.get_tree()
	if tree:
		tree.create_timer(lifetime + 0.25).timeout.connect(p.queue_free)
	return p


func style_progress_bar(bar: ProgressBar, fill: Color, bg: Color = Color(0.08, 0.06, 0.12, 0.85)) -> void:
	var bg_box := StyleBoxFlat.new()
	bg_box.bg_color = bg
	bg_box.set_corner_radius_all(4)
	bg_box.content_margin_left = 2
	bg_box.content_margin_right = 2
	bg_box.content_margin_top = 2
	bg_box.content_margin_bottom = 2
	var fill_box := StyleBoxFlat.new()
	fill_box.bg_color = fill
	fill_box.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg_box)
	bar.add_theme_stylebox_override("fill", fill_box)
	bar.show_percentage = false


## Style a PanelContainer with a Kenney UI button as nine-patch texture when available.
func style_panel_kenney(panel: PanelContainer, modulate_color: Color = Color(0.55, 0.5, 0.75, 0.95)) -> void:
	var tex: Texture2D = AssetPaths.load_texture(AssetPaths.UI_BUTTON_RECT)
	if tex == null:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.07, 0.16, 0.95)
		sb.set_corner_radius_all(12)
		sb.border_color = Color(0.55, 0.4, 0.8, 0.55)
		sb.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", sb)
		return
	var stb := StyleBoxTexture.new()
	stb.texture = tex
	stb.texture_margin_left = 16
	stb.texture_margin_right = 16
	stb.texture_margin_top = 12
	stb.texture_margin_bottom = 12
	stb.modulate_color = modulate_color
	stb.content_margin_left = 18
	stb.content_margin_right = 18
	stb.content_margin_top = 14
	stb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", stb)
