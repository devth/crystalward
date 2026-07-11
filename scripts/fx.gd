extends Node
## Procedural VFX helpers (no external textures).
## Autoloaded as `FX` so headless/game runs resolve without editor class_name scan.


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


func spark_particles(parent: Node, color: Color, amount: int = 18) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = amount
	p.lifetime = 1.4
	p.preprocess = 0.4
	p.explosiveness = 0.0
	p.randomness = 0.6
	p.local_coords = false
	p.z_index = 5

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 8.0
	mat.initial_velocity_max = 28.0
	mat.gravity = Vector3(0, -6, 0)
	mat.scale_min = 1.2
	mat.scale_max = 2.8
	mat.color = color
	# Fade via color ramp
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

	# Soft circle texture
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8:
			var d := Vector2(x - 3.5, y - 3.5).length()
			var a := clampf(1.0 - d / 3.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	var tex := ImageTexture.create_from_image(img)
	p.texture = tex

	parent.add_child(p)
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
