extends Node2D
## Atmospheric isometric ground: moss shader field, glowing paths, mist, forest sprites.
## Large ritual forest — props and landmarks across the full playable map.


const FOREST_MODULATE := Color(0.9, 1.0, 0.82)  # Legend golden-green lift
const FLOOR_EXTENT := 2200.0


func _ready() -> void:
	for c in get_children():
		c.queue_free()
	# Wait so Main can rebuild PathNetwork for the selected campaign map first.
	await get_tree().process_frame
	_build()
	if PathNetwork and not PathNetwork.paths_rebuilt.is_connected(_on_paths_rebuilt):
		PathNetwork.paths_rebuilt.connect(_on_paths_rebuilt)


func _on_paths_rebuilt() -> void:
	# Rebuild dirt roads so visual lanes always match monster lanes.
	for c in get_children():
		c.queue_free()
	call_deferred("_build")


func _build() -> void:
	var e := FLOOR_EXTENT
	var floor_poly := Polygon2D.new()
	var floor_pts := PackedVector2Array([
		Vector2(-e, -e * 0.75), Vector2(e, -e * 0.75), Vector2(e, e * 0.75), Vector2(-e, e * 0.75)
	])
	floor_poly.polygon = floor_pts
	floor_poly.uv = PackedVector2Array([
		Vector2(0, 0), Vector2(10, 0), Vector2(10, 7.5), Vector2(0, 7.5)
	])
	floor_poly.color = Color.WHITE
	var fm := ShaderMaterial.new()
	var lush := load("res://shaders/lush_ground.gdshader") as Shader
	fm.shader = lush if lush else load("res://shaders/ground_moss.gdshader") as Shader
	floor_poly.material = fm
	add_child(floor_poly)

	# Island-style ritual diamond (brighter plaza like PJ clearings)
	var diamond := Polygon2D.new()
	diamond.polygon = PackedVector2Array([
		Vector2(0, -520), Vector2(920, 50), Vector2(0, 620), Vector2(-920, 50)
	])
	diamond.color = Color(0.32, 0.48, 0.34, 0.95)
	diamond.z_index = -40
	add_child(diamond)
	var diamond_rim := Polygon2D.new()
	diamond_rim.polygon = PackedVector2Array([
		Vector2(0, -540), Vector2(950, 50), Vector2(0, 640), Vector2(-950, 50)
	])
	diamond_rim.color = Color(0.55, 0.45, 0.75, 0.12)
	diamond_rim.z_index = -41
	add_child(diamond_rim)

	var ring := FX.make_ellipse_poly(180, 105, 48, Color(0.95, 0.85, 0.45, 0.1))
	ring.position = Vector2(0, 40)
	ring.z_index = -35
	add_child(ring)
	var ring2 := FX.make_ellipse_poly(120, 70, 40, Color(0.55, 0.85, 0.7, 0.12))
	ring2.position = Vector2(0, 40)
	ring2.z_index = -34
	add_child(ring2)
	var ring3 := FX.make_ellipse_poly(300, 180, 48, Color(0.7, 0.5, 0.9, 0.06))
	ring3.position = Vector2(0, 40)
	ring3.z_index = -36
	add_child(ring3)

	# Authoritative monster lanes from PathNetwork (glowing roads)
	if PathNetwork:
		for lane in PathNetwork.lanes:
			var pts: PackedVector2Array = lane
			for i in range(pts.size() - 1):
				var width := 70.0 if i == 0 else 58.0
				if i >= pts.size() - 2:
					width = 48.0
				_add_path_strip(pts[i], pts[i + 1], width)
			# Path end markers (corruption portals)
			if pts.size() > 0:
				_add_spawn_portal(pts[0])

	# Standing stones near well + mid-range
	var stones: Array = [
		[Vector2(-260, -100), 1.0], [Vector2(250, -80), 0.85], [Vector2(-300, 160), 0.9],
		[Vector2(280, 140), 1.1], [Vector2(-100, -200), 0.7], [Vector2(120, 220), 0.75],
		[Vector2(-480, 40), 1.2], [Vector2(500, -20), 1.05], [Vector2(40, -420), 0.95],
		[Vector2(-40, 460), 1.0], [Vector2(-620, -280), 0.8], [Vector2(640, 300), 0.9],
	]
	for s in stones:
		_add_standing_stone(s[0], s[1])

	# Near thickets
	for t in [
		Vector2(-400, 40), Vector2(400, 60), Vector2(0, -340), Vector2(-60, 340),
		Vector2(-720, -100), Vector2(760, 80), Vector2(-200, 680), Vector2(220, -700),
	]:
		_add_thicket(t, randf_range(-0.4, 0.4))

	# Distant landmark clusters (~600–1200 from origin)
	_add_landmark_cluster(Vector2(-900, -200), "stones")
	_add_landmark_cluster(Vector2(950, -150), "stones")
	_add_landmark_cluster(Vector2(-850, 500), "thicket")
	_add_landmark_cluster(Vector2(880, 480), "thicket")
	_add_landmark_cluster(Vector2(0, -1000), "stones")
	_add_landmark_cluster(Vector2(-100, 1050), "thicket")
	_add_landmark_cluster(Vector2(-1100, 100), "mixed")
	_add_landmark_cluster(Vector2(1150, 60), "mixed")
	_add_landmark_cluster(Vector2(-650, -750), "mixed")
	_add_landmark_cluster(Vector2(700, 800), "stones")

	_scatter_forest_props()
	_scatter_dark_scenery()

	# Legend (1985) botanical beauty — meadows, fairy rings, ferns, pollen
	var bot := Node2D.new()
	bot.name = "BotanicalBeauty"
	bot.set_script(load("res://scripts/botanical_beauty.gd"))
	add_child(bot)
	if bot.has_method("paint"):
		bot.call("paint", self)

	var motes := FX.spark_particles(self, Color(0.95, 0.85, 0.55, 0.65), 40, "star")
	motes.position = Vector2(0, 40)
	motes.amount = 50
	motes.lifetime = 4.0
	var pm := motes.process_material as ParticleProcessMaterial
	if pm:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 520.0
		pm.initial_velocity_min = 3.0
		pm.initial_velocity_max = 12.0
		pm.gravity = Vector3(0, -4, 0)

	# Soft golden-green forest light shafts (Legend dappled magic)
	for i in 6:
		var shaft := Polygon2D.new()
		var ang := -0.9 + float(i) * 0.35
		shaft.polygon = PackedVector2Array([
			Vector2(0, 30),
			Vector2(cos(ang - 0.1) * 40, -80),
			Vector2(cos(ang + 0.1) * 320, -420),
			Vector2(cos(ang - 0.1) * 320, -420),
		])
		shaft.color = Color(0.95, 0.9, 0.55, 0.035 + float(i % 2) * 0.01)
		shaft.z_index = -25
		shaft.position = Vector2(0, 40)
		add_child(shaft)

	_add_mist_bank(Vector2(-520, -80), Vector2(320, 180))
	_add_mist_bank(Vector2(480, 120), Vector2(300, 160))
	_add_mist_bank(Vector2(40, 360), Vector2(360, 140))
	_add_mist_bank(Vector2(-700, 400), Vector2(280, 150))
	_add_mist_bank(Vector2(800, -350), Vector2(260, 140))
	_add_mist_bank(Vector2(-200, -700), Vector2(300, 120))
	# Softer fairy mist near glade
	_add_mist_bank(Vector2(80, -40), Vector2(200, 100))
	_add_mist_bank(Vector2(-120, 100), Vector2(180, 90))


func _add_landmark_cluster(center: Vector2, kind: String) -> void:
	match kind:
		"stones":
			for i in 5:
				var o := Vector2(randf_range(-70, 70), randf_range(-50, 50))
				_add_standing_stone(center + o, randf_range(0.7, 1.3))
			_add_thicket(center + Vector2(40, 20), 0.2)
		"thicket":
			_add_thicket(center, randf_range(-0.3, 0.3))
			_add_thicket(center + Vector2(60, -30), 0.4)
			_add_thicket(center + Vector2(-50, 40), -0.25)
			_add_standing_stone(center + Vector2(20, 10), 0.85)
		_:
			_add_standing_stone(center, 1.15)
			_add_thicket(center + Vector2(-40, 30), 0.1)
			_add_standing_stone(center + Vector2(55, -20), 0.75)


func _scatter_forest_props() -> void:
	## These packs are WHOLE sprites (or 2 stacked trees), NOT tile grids.
	## Blind 16×16 / 32×64 slicing produced solid green/black "barf" rectangles.
	var tree_tex: Texture2D = AssetPaths.load_texture(AssetPaths.FOREST_TREES)
	var stone_tex: Texture2D = AssetPaths.load_texture(AssetPaths.FOREST_STONES)
	var bush_tex: Texture2D = AssetPaths.load_texture(AssetPaths.FOREST_BUSHES)
	var dawn_tree: Texture2D = AssetPaths.load_texture(AssetPaths.DAWNLIKE_TREE0)

	var rng := RandomNumberGenerator.new()
	rng.seed = 4242

	# Seasons-of-Forest trees.png is 64×128: two full trees stacked (round + pine).
	var tree_sprites: Array[Texture2D] = []
	if tree_tex and tree_tex.get_width() >= 32:
		if tree_tex.get_height() >= 128 and tree_tex.get_width() >= 64:
			tree_sprites.append(_region_or_full(tree_tex, Rect2(0, 0, 64, 64)))
			tree_sprites.append(_region_or_full(tree_tex, Rect2(0, 64, 64, 64)))
		else:
			tree_sprites.append(tree_tex)
	# DawnLike trees: real 16×16 sheet — pick a few nice cells only
	if dawn_tree:
		for cell in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 1), Vector2i(3, 2), Vector2i(0, 2)]:
			var reg := Rect2(cell.x * 16, cell.y * 16, 16, 16)
			var t := _region_or_full(dawn_tree, reg)
			if t:
				tree_sprites.append(t)

	for i in 70:
		var pos := _rand_map_pos(rng, 220, 1950)
		if pos.length() < 300.0 and rng.randf() < 0.8:
			continue
		if tree_sprites.is_empty():
			break
		var tex: Texture2D = tree_sprites[i % tree_sprites.size()]
		# Full forest trees are larger; dawnlike cells need more scale
		var is_dawn := tex.get_width() <= 16
		var sc := rng.randf_range(3.2, 4.6) if is_dawn else rng.randf_range(1.8, 2.8)
		_place_sprite(tex, pos, sc, -1, 0.95)

	# Whole bush stamp only (32×32 art — never slice)
	if bush_tex:
		for i in 22:
			var pos := _rand_map_pos(rng, 200, 1800)
			if pos.length() < 260.0:
				continue
			_place_sprite(bush_tex, pos, rng.randf_range(2.0, 3.0), 0, 0.92)

	# Whole stone stamp only
	if stone_tex:
		for i in 18:
			var pos := _rand_map_pos(rng, 200, 1750)
			if pos.length() < 240.0:
				continue
			_place_sprite(stone_tex, pos, rng.randf_range(1.6, 2.4), 0, 0.9)

	# No grass sheet scatter, no haunted grid-slice, no black-backed scenery sheet.
	# Those were the solid green squares and dark UI-looking blocks.


func _scatter_dark_scenery() -> void:
	# Intentionally empty: misc_scenery is packed on black and grid-slicing = black rectangles.
	pass


func _rand_map_pos(rng: RandomNumberGenerator, min_r: float, max_r: float) -> Vector2:
	var ang := rng.randf() * TAU
	# Bias density slightly outward but still fill mid-map
	var t := rng.randf()
	var r := lerpf(min_r, max_r, t * t * 0.35 + t * 0.65)
	return Vector2(cos(ang), sin(ang) * 0.78) * r + Vector2(rng.randf_range(-30, 30), rng.randf_range(-20, 20))


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
	var th: float = float(tex.get_height()) if tex else 16.0
	s.offset = Vector2(0, -th * 0.35)
	add_child(s)
	return s


func _add_path_strip(from: Vector2, to: Vector2, width: float) -> void:
	var dir := (to - from)
	var len := dir.length()
	if len < 1.0:
		return
	var n := dir.normalized()
	var perp := Vector2(-n.y, n.x) * (width * 0.5)
	# Warm dirt path — high contrast so lanes read on the green field
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		from + perp * 1.15, from - perp * 1.15, to - perp * 1.15, to + perp * 1.15
	])
	poly.color = Color(0.38, 0.26, 0.16, 0.96)
	poly.z_index = -38
	add_child(poly)
	var poly_in := Polygon2D.new()
	poly_in.polygon = PackedVector2Array([
		from + perp * 0.7, from - perp * 0.7, to - perp * 0.7, to + perp * 0.7
	])
	poly_in.color = Color(0.58, 0.42, 0.26, 0.92)
	poly_in.z_index = -37
	add_child(poly_in)

	var edge := Line2D.new()
	edge.width = 3.0
	edge.default_color = Color(0.35, 0.55, 0.35, 0.55)
	edge.points = PackedVector2Array([from + perp * 1.05, to + perp * 1.05])
	edge.z_index = -36
	add_child(edge)
	var edge2 := Line2D.new()
	edge2.width = 3.0
	edge2.default_color = Color(0.35, 0.55, 0.35, 0.55)
	edge2.points = PackedVector2Array([from - perp * 1.05, to - perp * 1.05])
	edge2.z_index = -36
	add_child(edge2)

	# Soft magical center vein
	var vein := Line2D.new()
	vein.width = 3.5
	vein.default_color = Color(0.85, 0.7, 1.0, 0.28)
	vein.begin_cap_mode = Line2D.LINE_CAP_ROUND
	vein.end_cap_mode = Line2D.LINE_CAP_ROUND
	vein.points = PackedVector2Array([from, to])
	vein.z_index = -35
	add_child(vein)

	var steps := maxi(2, int(len / 100.0))
	for s in steps:
		var t := float(s) / float(steps)
		var p: Vector2 = from.lerp(to, t) + perp.normalized() * randf_range(-width * 0.15, width * 0.15)
		var pebble := FX.make_ellipse_poly(randf_range(2.0, 4.0), randf_range(1.5, 2.5), 8, Color(0.35, 0.28, 0.2, 0.5))
		pebble.position = p
		pebble.z_index = -34
		add_child(pebble)


func _add_spawn_portal(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	root.z_index = int(pos.y)
	add_child(root)
	# Friendly-readable “dark gate” — bold silhouette like PJ spawn points
	var outer := FX.make_ellipse_poly(42, 26, 28, Color(0.2, 0.1, 0.22, 0.75))
	root.add_child(outer)
	var ring := FX.make_ellipse_poly(34, 20, 28, Color(0.75, 0.35, 0.55, 0.55))
	root.add_child(ring)
	var core := FX.make_ellipse_poly(16, 10, 18, Color(1.0, 0.7, 0.85, 0.65))
	root.add_child(core)
	if FX:
		FX.spark_particles(root, Color(0.95, 0.55, 0.85, 0.8), 12, "magic")


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
	# Behind characters/UI — was z=40 and washed over gameplay
	poly.z_index = -25
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/mist_field.gdshader") as Shader
	poly.material = mat
	add_child(poly)
