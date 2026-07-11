extends Node2D
## Atmospheric isometric ground: moss shader field, glowing paths, mist, motes.


func _ready() -> void:
	# Clear editor placeholders
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	_build()


func _build() -> void:
	# Vast dark floor with moss shader
	var floor_poly := Polygon2D.new()
	var floor_pts := PackedVector2Array([
		Vector2(-1100, -800), Vector2(1100, -800), Vector2(1100, 800), Vector2(-1100, 800)
	])
	floor_poly.polygon = floor_pts
	floor_poly.uv = PackedVector2Array([
		Vector2(0, 0), Vector2(4, 0), Vector2(4, 3), Vector2(0, 3)
	])
	floor_poly.color = Color.WHITE
	var fm := ShaderMaterial.new()
	fm.shader = load("res://shaders/ground_moss.gdshader") as Shader
	floor_poly.material = fm
	add_child(floor_poly)

	# Main ritual diamond
	var diamond := Polygon2D.new()
	diamond.polygon = PackedVector2Array([
		Vector2(0, -300), Vector2(560, 40), Vector2(0, 380), Vector2(-560, 40)
	])
	diamond.color = Color(0.14, 0.2, 0.18, 0.92)
	diamond.z_index = -40
	add_child(diamond)

	# Inner glow ring around lightwell
	var ring := FX.make_ellipse_poly(120, 70, 40, Color(0.45, 0.3, 0.7, 0.12))
	ring.position = Vector2(0, 40)
	ring.z_index = -35
	add_child(ring)
	var ring2 := FX.make_ellipse_poly(80, 46, 36, Color(0.35, 0.55, 0.45, 0.1))
	ring2.position = Vector2(0, 40)
	ring2.z_index = -34
	add_child(ring2)

	# Paths with layered glow
	_add_path_strip(Vector2(0, -220), Vector2(0, 260), 56)
	_add_path_strip(Vector2(-300, 20), Vector2(300, 20), 50)
	_add_path_strip(Vector2(-180, -140), Vector2(200, 160), 36)
	_add_path_strip(Vector2(180, -120), Vector2(-160, 180), 36)

	# Decorative standing stones
	_add_standing_stone(Vector2(-260, -100), 1.0)
	_add_standing_stone(Vector2(250, -80), 0.85)
	_add_standing_stone(Vector2(-300, 160), 0.9)
	_add_standing_stone(Vector2(280, 140), 1.1)
	_add_standing_stone(Vector2(-100, -200), 0.7)
	_add_standing_stone(Vector2(120, 220), 0.75)

	# Thorn thickets at edges
	_add_thicket(Vector2(-400, 40), -0.3)
	_add_thicket(Vector2(400, 60), 0.4)
	_add_thicket(Vector2(0, -340), 0.0)
	_add_thicket(Vector2(-60, 340), 0.1)

	# Floating spore motes
	var motes := FX.spark_particles(self, Color(0.65, 0.45, 0.9, 0.7), 36)
	motes.position = Vector2(0, 40)
	motes.amount = 40
	motes.lifetime = 3.5
	var pm := motes.process_material as ParticleProcessMaterial
	if pm:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 280.0
		pm.initial_velocity_min = 4.0
		pm.initial_velocity_max = 14.0
		pm.gravity = Vector3(0, -3, 0)
		pm.scale_min = 0.8
		pm.scale_max = 2.2

	# Distant mist banks
	_add_mist_bank(Vector2(-320, -60), Vector2(220, 140))
	_add_mist_bank(Vector2(280, 80), Vector2(200, 120))
	_add_mist_bank(Vector2(40, 240), Vector2(260, 100))


func _add_path_strip(from: Vector2, to: Vector2, width: float) -> void:
	var dir := (to - from)
	var len := dir.length()
	if len < 1.0:
		return
	var n := dir.normalized()
	var perp := Vector2(-n.y, n.x) * (width * 0.5)
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		from + perp, from - perp, to - perp, to + perp
	])
	poly.color = Color(0.2, 0.12, 0.26, 0.75)
	poly.z_index = -38
	add_child(poly)

	# Edge highlights
	var edge := Line2D.new()
	edge.width = 2.0
	edge.default_color = Color(0.55, 0.35, 0.75, 0.25)
	edge.points = PackedVector2Array([from + perp * 0.85, to + perp * 0.85])
	edge.z_index = -37
	add_child(edge)
	var edge2 := Line2D.new()
	edge2.width = 2.0
	edge2.default_color = Color(0.3, 0.55, 0.45, 0.2)
	edge2.points = PackedVector2Array([from - perp * 0.85, to - perp * 0.85])
	edge2.z_index = -37
	add_child(edge2)

	# Center vein
	var vein := Line2D.new()
	vein.width = 3.0
	vein.default_color = Color(0.7, 0.5, 0.9, 0.12)
	vein.points = PackedVector2Array([from, to])
	vein.z_index = -36
	add_child(vein)


func _add_standing_stone(pos: Vector2, scale: float) -> void:
	var root := Node2D.new()
	root.position = pos
	root.scale = Vector2(scale, scale)
	root.z_index = int(pos.y)
	add_child(root)
	FX.add_soft_shadow(root, 14, 6, 12)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-10, 10), Vector2(-14, -8), Vector2(-4, -28),
		Vector2(6, -32), Vector2(14, -12), Vector2(10, 10)
	])
	body.color = Color(0.22, 0.2, 0.28)
	root.add_child(body)
	var moss := Polygon2D.new()
	moss.polygon = PackedVector2Array([
		Vector2(-8, 2), Vector2(-6, -10), Vector2(2, -6), Vector2(6, 4)
	])
	moss.color = Color(0.25, 0.45, 0.35, 0.75)
	root.add_child(moss)
	var gleam := Polygon2D.new()
	gleam.polygon = PackedVector2Array([Vector2(-2, -26), Vector2(4, -20), Vector2(0, -12)])
	gleam.color = Color(0.7, 0.55, 0.9, 0.35)
	root.add_child(gleam)


func _add_thicket(pos: Vector2, rot: float) -> void:
	var root := Node2D.new()
	root.position = pos
	root.rotation = rot
	root.z_index = int(pos.y)
	add_child(root)
	for i in 7:
		var thorn := Line2D.new()
		thorn.width = 2.5
		thorn.default_color = Color(0.2, 0.45, 0.32, 0.85)
		var h := 30.0 + randf() * 40.0
		var lean := randf_range(-0.4, 0.4)
		thorn.points = PackedVector2Array([
			Vector2(i * 8.0 - 24.0, 8.0),
			Vector2(i * 8.0 - 24.0 + lean * 20.0, -h)
		])
		root.add_child(thorn)
		var tip := Polygon2D.new()
		tip.color = Color(0.35, 0.65, 0.45)
		var tip_pos := Vector2(i * 8.0 - 24.0 + lean * 20.0, -h)
		tip.polygon = PackedVector2Array([
			tip_pos, tip_pos + Vector2(-4, 6), tip_pos + Vector2(4, 6)
		])
		root.add_child(tip)


func _add_mist_bank(pos: Vector2, size: Vector2) -> void:
	var poly := FX.make_ellipse_poly(size.x * 0.5, size.y * 0.5, 32, Color.WHITE)
	poly.position = pos
	poly.z_index = 40
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/mist_field.gdshader") as Shader
	poly.material = mat
	add_child(poly)
