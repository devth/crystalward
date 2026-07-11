extends Node2D
## Atmospheric isometric ground: moss shader field, glowing paths, mist, forest sprites.


const FOREST_MODULATE := Color(0.75, 0.7, 0.95)


func _ready() -> void:
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	_build()


func _build() -> void:
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

	var diamond := Polygon2D.new()
	diamond.polygon = PackedVector2Array([
		Vector2(0, -300), Vector2(560, 40), Vector2(0, 380), Vector2(-560, 40)
	])
	diamond.color = Color(0.14, 0.2, 0.18, 0.92)
	diamond.z_index = -40
	add_child(diamond)

	var ring := FX.make_ellipse_poly(120, 70, 40, Color(0.45, 0.3, 0.7, 0.12))
	ring.position = Vector2(0, 40)
	ring.z_index = -35
	add_child(ring)
	var ring2 := FX.make_ellipse_poly(80, 46, 36, Color(0.35, 0.55, 0.45, 0.1))
	ring2.position = Vector2(0, 40)
	ring2.z_index = -34
	add_child(ring2)

	_add_path_strip(Vector2(0, -220), Vector2(0, 260), 56)
	_add_path_strip(Vector2(-300, 20), Vector2(300, 20), 50)
	_add_path_strip(Vector2(-180, -140), Vector2(200, 160), 36)
	_add_path_strip(Vector2(180, -120), Vector2(-160, 180), 36)

	_add_standing_stone(Vector2(-260, -100), 1.0)
	_add_standing_stone(Vector2(250, -80), 0.85)
	_add_standing_stone(Vector2(-300, 160), 0.9)
	_add_standing_stone(Vector2(280, 140), 1.1)
	_add_standing_stone(Vector2(-100, -200), 0.7)
	_add_standing_stone(Vector2(120, 220), 0.75)

	_add_thicket(Vector2(-400, 40), -0.3)
	_add_thicket(Vector2(400, 60), 0.4)
	_add_thicket(Vector2(0, -340), 0.0)
	_add_thicket(Vector2(-60, 340), 0.1)

	_scatter_forest_props()

	var motes := FX.spark_particles(self, Color(0.65, 0.45, 0.9, 0.7), 36, "star")
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

	_add_mist_bank(Vector2(-320, -60), Vector2(220, 140))
	_add_mist_bank(Vector2(280, 80), Vector2(200, 120))
	_add_mist_bank(Vector2(40, 240), Vector2(260, 100))


func _scatter_forest_props() -> void:
	var tree_tex: Texture2D = AssetPaths.load_texture(AssetPaths.FOREST_TREES)
	var stone_tex: Texture2D = AssetPaths.load_texture(AssetPaths.FOREST_STONES)
	var bush_tex: Texture2D = AssetPaths.load_texture(AssetPaths.FOREST_BUSHES)
	var grass_tex: Texture2D = AssetPaths.load_texture(AssetPaths.FOREST_GRASS)

	# Prefer DawnLike tree cells if forest sheet is missing.
	if tree_tex == null:
		tree_tex = AssetPaths.atlas_region(AssetPaths.DAWNLIKE_TREE0, Rect2(0, 0, 48, 64))

	var edge_spots: Array[Vector2] = [
		Vector2(-480, -220), Vector2(-520, -40), Vector2(-500, 160), Vector2(-460, 300),
		Vector2(480, -200), Vector2(520, -20), Vector2(500, 180), Vector2(460, 320),
		Vector2(-200, -380), Vector2(40, -400), Vector2(220, -360),
		Vector2(-180, 380), Vector2(80, 400), Vector2(260, 360),
		Vector2(-380, -280), Vector2(380, -260), Vector2(-360, 280), Vector2(360, 300),
	]
	var thicket_centers: Array[Vector2] = [
		Vector2(-400, 40), Vector2(400, 60), Vector2(0, -340), Vector2(-60, 340),
		Vector2(-280, -180), Vector2(300, 200),
	]

	if tree_tex:
		var tree_regions := _sheet_regions(tree_tex, 32, 64)
		for i in edge_spots.size():
			var pos: Vector2 = edge_spots[i]
			var reg: Rect2 = tree_regions[i % tree_regions.size()]
			var tex := _region_or_full(tree_tex, reg)
			var sc := randf_range(2.2, 3.6)
			_place_sprite(tex, pos + Vector2(randf_range(-20, 20), randf_range(-12, 12)), sc, -1)
		# Extra trees around thickets
		for center in thicket_centers:
			for j in 3:
				var offset := Vector2(randf_range(-50, 50), randf_range(-30, 30))
				var reg2: Rect2 = tree_regions[j % tree_regions.size()]
				_place_sprite(_region_or_full(tree_tex, reg2), center + offset, randf_range(2.0, 3.2), -1)

	if bush_tex:
		var bush_regs := _sheet_regions(bush_tex, 16, 16)
		for center in thicket_centers:
			for j in 4:
				var offset := Vector2(randf_range(-40, 40), randf_range(-24, 24))
				var reg: Rect2 = bush_regs[j % bush_regs.size()]
				_place_sprite(_region_or_full(bush_tex, reg), center + offset, randf_range(2.5, 3.5), 0)

	if stone_tex:
		var stone_regs := _sheet_regions(stone_tex, 16, 16)
		var stone_spots: Array[Vector2] = [
			Vector2(-200, 80), Vector2(180, -60), Vector2(-80, 200), Vector2(90, -160),
			Vector2(-320, -40), Vector2(310, 100), Vector2(40, 280), Vector2(-140, -240),
		]
		for i in stone_spots.size():
			var reg: Rect2 = stone_regs[i % stone_regs.size()]
			_place_sprite(_region_or_full(stone_tex, reg), stone_spots[i], randf_range(2.5, 4.0), 0)

	if grass_tex:
		var grass_regs := _sheet_regions(grass_tex, 16, 16)
		for i in 28:
			var pos := Vector2(randf_range(-420, 420), randf_range(-300, 320))
			# Keep clear of lightwell center
			if pos.length() < 90.0:
				continue
			var reg: Rect2 = grass_regs[i % grass_regs.size()]
			_place_sprite(_region_or_full(grass_tex, reg), pos, randf_range(1.8, 2.8), 0, 0.85)


func _sheet_regions(tex: Texture2D, cell_w: int, cell_h: int) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var tw := tex.get_width()
	var th := tex.get_height()
	if tw < cell_w or th < cell_h:
		out.append(Rect2(0, 0, tw, th))
		return out
	var cols := maxi(1, tw / cell_w)
	var rows := maxi(1, th / cell_h)
	for r in rows:
		for c in cols:
			out.append(Rect2(c * cell_w, r * cell_h, cell_w, cell_h))
	if out.is_empty():
		out.append(Rect2(0, 0, tw, th))
	return out


func _region_or_full(tex: Texture2D, region: Rect2) -> Texture2D:
	if region.size.x >= tex.get_width() and region.size.y >= tex.get_height():
		return tex
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = region
	at.filter_clip = true
	return at


func _place_sprite(
	tex: Texture2D,
	pos: Vector2,
	scale_mul: float,
	y_sort_bias: int = 0,
	alpha: float = 1.0
) -> Sprite2D:
	if tex == null:
		return null
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = true
	s.position = pos
	s.scale = Vector2(scale_mul, scale_mul)
	s.modulate = Color(FOREST_MODULATE.r, FOREST_MODULATE.g, FOREST_MODULATE.b, alpha)
	s.z_index = int(pos.y) + y_sort_bias
	# Anchor toward feet for tall trees
	s.offset = Vector2(0, -tex.get_height() * 0.15)
	add_child(s)
	return s


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
