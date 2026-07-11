extends Node2D
## Ground + dirt roads + forest props.
## Critical: paths must paint ABOVE the floor (z_index), not under it.

const FOREST_MODULATE := Color(0.92, 1.0, 0.88)
const FLOOR_EXTENT := 2200.0

# Local draw order under Ground (parent z is -100 on Main)
const Z_FLOOR := 0
const Z_PLAZA := 1
const Z_PATH_EDGE := 18
const Z_PATH := 20
const Z_PATH_DETAIL := 22
const Z_PORTAL := 30
const Z_DECOR := 40


func _ready() -> void:
	y_sort_enabled = false
	for c in get_children():
		c.queue_free()
	# Main rebuilds PathNetwork in its _ready; wait one frame so lanes exist.
	await get_tree().process_frame
	if PathNetwork and PathNetwork.lane_count() == 0:
		PathNetwork.rebuild(PathNetwork.active_lane_set if PathNetwork.active_lane_set else "simple")
	_build()
	if PathNetwork and not PathNetwork.paths_rebuilt.is_connected(_on_paths_rebuilt):
		PathNetwork.paths_rebuilt.connect(_on_paths_rebuilt)


func _on_paths_rebuilt() -> void:
	for c in get_children():
		c.queue_free()
	call_deferred("_build")


func _build() -> void:
	_build_floor()
	_build_plaza()
	_build_paths()  # must be after floor, higher z
	_build_landmarks()
	_scatter_forest_props()
	_build_botanicals()
	_build_atmosphere_light()


func _build_floor() -> void:
	var e := FLOOR_EXTENT
	var floor_poly := Polygon2D.new()
	floor_poly.polygon = PackedVector2Array([
		Vector2(-e, -e * 0.75), Vector2(e, -e * 0.75), Vector2(e, e * 0.75), Vector2(-e, e * 0.75)
	])
	floor_poly.uv = PackedVector2Array([
		Vector2(0, 0), Vector2(12, 0), Vector2(12, 9), Vector2(0, 9)
	])
	floor_poly.color = Color.WHITE
	floor_poly.z_index = Z_FLOOR
	var fm := ShaderMaterial.new()
	var lush := load("res://shaders/lush_ground.gdshader") as Shader
	if lush:
		fm.shader = lush
		floor_poly.material = fm
	else:
		floor_poly.color = Color(0.22, 0.38, 0.26)
	add_child(floor_poly)


func _build_plaza() -> void:
	var diamond := Polygon2D.new()
	diamond.polygon = PackedVector2Array([
		Vector2(0, -520), Vector2(920, 50), Vector2(0, 620), Vector2(-920, 50)
	])
	diamond.color = Color(0.28, 0.42, 0.30, 0.55)
	diamond.z_index = Z_PLAZA
	add_child(diamond)

	var ring := _ellipse(Vector2(0, 40), 180, 105, Color(0.95, 0.85, 0.45, 0.12), Z_PLAZA)
	add_child(ring)
	var ring2 := _ellipse(Vector2(0, 40), 120, 70, Color(0.55, 0.85, 0.7, 0.1), Z_PLAZA)
	add_child(ring2)


func _build_paths() -> void:
	if PathNetwork == null:
		return
	if PathNetwork.lane_count() == 0:
		PathNetwork.rebuild("simple")
	var n_lanes := 0
	for lane in PathNetwork.lanes:
		var pts: PackedVector2Array = lane
		if pts.size() < 2:
			continue
		n_lanes += 1
		for i in range(pts.size() - 1):
			var width := 78.0 if i == 0 else 64.0
			if i >= pts.size() - 2:
				width = 52.0
			_add_path_strip(pts[i], pts[i + 1], width)
		_add_spawn_portal(pts[0])
	if n_lanes == 0:
		push_warning("ground_visual: PathNetwork has no lanes — roads not drawn")


func _build_landmarks() -> void:
	var stones: Array = [
		[Vector2(-260, -100), 1.0], [Vector2(250, -80), 0.85], [Vector2(-300, 160), 0.9],
		[Vector2(280, 140), 1.1], [Vector2(-100, -200), 0.7], [Vector2(120, 220), 0.75],
		[Vector2(-480, 40), 1.2], [Vector2(500, -20), 1.05],
	]
	for s in stones:
		_add_standing_stone(s[0], s[1])
	for t in [Vector2(-400, 40), Vector2(400, 60), Vector2(0, -340), Vector2(-60, 340)]:
		_add_thicket(t, randf_range(-0.3, 0.3))


func _build_botanicals() -> void:
	var bot := Node2D.new()
	bot.name = "BotanicalBeauty"
	bot.z_index = Z_DECOR
	bot.set_script(load("res://scripts/botanical_beauty.gd"))
	add_child(bot)
	if bot.has_method("paint"):
		bot.call("paint", bot)  # paint into own layer, not entire ground


func _build_atmosphere_light() -> void:
	if FX == null:
		return
	var motes := FX.spark_particles(self, Color(0.95, 0.85, 0.55, 0.45), 22, "star")
	motes.position = Vector2(0, 40)
	motes.z_index = Z_DECOR
	motes.amount = 24
	motes.lifetime = 4.0
	var pm := motes.process_material as ParticleProcessMaterial
	if pm:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 420.0
		pm.initial_velocity_min = 2.0
		pm.initial_velocity_max = 10.0
		pm.gravity = Vector3(0, -3, 0)


func _ellipse(pos: Vector2, rx: float, ry: float, col: Color, z: int) -> Polygon2D:
	var p: Polygon2D
	if FX:
		p = FX.make_ellipse_poly(rx, ry, 40, col)
	else:
		p = Polygon2D.new()
		p.color = col
	p.position = pos
	p.z_index = z
	return p


func _scatter_forest_props() -> void:
	## Whole sprites only — never fake-grid-slice packed sheets.
	var tree_tex: Texture2D = AssetPaths.load_texture(AssetPaths.FOREST_TREES) if AssetPaths else null
	var stone_tex: Texture2D = AssetPaths.load_texture(AssetPaths.FOREST_STONES) if AssetPaths else null
	var bush_tex: Texture2D = AssetPaths.load_texture(AssetPaths.FOREST_BUSHES) if AssetPaths else null
	var dawn_tree: Texture2D = AssetPaths.load_texture(AssetPaths.DAWNLIKE_TREE0) if AssetPaths else null

	var rng := RandomNumberGenerator.new()
	rng.seed = 4242

	var tree_sprites: Array[Texture2D] = []
	if tree_tex and tree_tex.get_width() >= 64 and tree_tex.get_height() >= 128:
		# seasons trees.png: two full trees stacked 64×64
		tree_sprites.append(_atlas(tree_tex, Rect2(0, 0, 64, 64)))
		tree_sprites.append(_atlas(tree_tex, Rect2(0, 64, 64, 64)))
	elif tree_tex:
		tree_sprites.append(tree_tex)

	if dawn_tree and dawn_tree.get_width() >= 48:
		# Known full-ish 16×16 tree cells (not random empty)
		for cell in [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(1, 1), Vector2i(2, 1)]:
			tree_sprites.append(_atlas(dawn_tree, Rect2(cell.x * 16, cell.y * 16, 16, 16)))

	for i in 55:
		var pos := _rand_map_pos(rng, 260, 1900)
		if pos.length() < 320.0:
			continue
		if tree_sprites.is_empty():
			break
		var tex: Texture2D = tree_sprites[i % tree_sprites.size()]
		var is_small := tex.get_width() <= 16
		var sc := rng.randf_range(3.5, 5.0) if is_small else rng.randf_range(2.0, 3.0)
		_place_sprite(tex, pos, sc, 0.95)

	if bush_tex:
		for i in 16:
			var pos := _rand_map_pos(rng, 240, 1750)
			if pos.length() < 280.0:
				continue
			_place_sprite(bush_tex, pos, rng.randf_range(2.0, 2.8), 0.92)

	if stone_tex:
		for i in 12:
			var pos := _rand_map_pos(rng, 240, 1700)
			if pos.length() < 260.0:
				continue
			_place_sprite(stone_tex, pos, rng.randf_range(1.5, 2.2), 0.9)


func _rand_map_pos(rng: RandomNumberGenerator, min_r: float, max_r: float) -> Vector2:
	var ang := rng.randf() * TAU
	var t := rng.randf()
	var r := lerpf(min_r, max_r, t * t * 0.35 + t * 0.65)
	return Vector2(cos(ang), sin(ang) * 0.78) * r + Vector2(rng.randf_range(-24, 24), rng.randf_range(-16, 16))


func _atlas(tex: Texture2D, region: Rect2) -> Texture2D:
	if tex == null:
		return null
	if region.size.x >= tex.get_width() and region.size.y >= tex.get_height():
		return tex
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = region
	at.filter_clip = false  # true was clipping edge pixels into "cut off" art
	return at


func _place_sprite(tex: Texture2D, pos: Vector2, scale_mul: float, alpha: float = 1.0) -> Sprite2D:
	if tex == null:
		return null
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = true
	s.position = pos
	s.scale = Vector2(scale_mul, scale_mul)
	s.modulate = Color(FOREST_MODULATE.r, FOREST_MODULATE.g, FOREST_MODULATE.b, alpha)
	# Keep props above floor/paths; use Y only as fine sort within decor band
	s.z_index = Z_DECOR + clampi(int(pos.y / 40.0), -10, 40)
	s.offset = Vector2(0, -float(tex.get_height()) * 0.4)
	add_child(s)
	return s


func _add_path_strip(from: Vector2, to: Vector2, width: float) -> void:
	var dir := to - from
	var len := dir.length()
	if len < 1.0:
		return
	var n := dir.normalized()
	var perp := Vector2(-n.y, n.x) * (width * 0.5)

	# Dark outer bed
	var outer := Polygon2D.new()
	outer.polygon = PackedVector2Array([
		from + perp * 1.2, from - perp * 1.2, to - perp * 1.2, to + perp * 1.2
	])
	outer.color = Color(0.22, 0.14, 0.08, 1.0)
	outer.z_index = Z_PATH_EDGE
	add_child(outer)

	# Main dirt
	var mid := Polygon2D.new()
	mid.polygon = PackedVector2Array([
		from + perp * 1.0, from - perp * 1.0, to - perp * 1.0, to + perp * 1.0
	])
	mid.color = Color(0.48, 0.34, 0.20, 1.0)
	mid.z_index = Z_PATH
	add_child(mid)

	# Lighter center track
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([
		from + perp * 0.45, from - perp * 0.45, to - perp * 0.45, to + perp * 0.45
	])
	inner.color = Color(0.62, 0.46, 0.28, 1.0)
	inner.z_index = Z_PATH_DETAIL
	add_child(inner)

	# Soft moss edge lines (readable without noise)
	var edge := Line2D.new()
	edge.width = 4.0
	edge.default_color = Color(0.25, 0.4, 0.22, 0.65)
	edge.begin_cap_mode = Line2D.LINE_CAP_ROUND
	edge.end_cap_mode = Line2D.LINE_CAP_ROUND
	edge.points = PackedVector2Array([from + perp * 1.05, to + perp * 1.05])
	edge.z_index = Z_PATH_DETAIL
	add_child(edge)
	var edge2 := edge.duplicate() as Line2D
	edge2.points = PackedVector2Array([from - perp * 1.05, to - perp * 1.05])
	add_child(edge2)

	# Center guide (subtle crystal dust)
	var vein := Line2D.new()
	vein.width = 2.5
	vein.default_color = Color(0.75, 0.65, 0.95, 0.35)
	vein.begin_cap_mode = Line2D.LINE_CAP_ROUND
	vein.end_cap_mode = Line2D.LINE_CAP_ROUND
	vein.points = PackedVector2Array([from, to])
	vein.z_index = Z_PATH_DETAIL
	add_child(vein)


func _add_spawn_portal(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	root.z_index = Z_PORTAL
	add_child(root)
	var outer := _ellipse(Vector2.ZERO, 44, 28, Color(0.18, 0.08, 0.2, 0.85), 0)
	root.add_child(outer)
	var ring := _ellipse(Vector2.ZERO, 34, 20, Color(0.75, 0.35, 0.55, 0.6), 1)
	root.add_child(ring)
	var core := _ellipse(Vector2.ZERO, 16, 10, Color(1.0, 0.7, 0.85, 0.7), 2)
	root.add_child(core)
	if FX:
		var p := FX.spark_particles(root, Color(0.95, 0.55, 0.85, 0.7), 10, "magic")
		p.z_index = 3


func _add_standing_stone(pos: Vector2, scale: float) -> void:
	var root := Node2D.new()
	root.position = pos
	root.scale = Vector2(scale, scale)
	root.z_index = Z_DECOR + clampi(int(pos.y / 40.0), -10, 40)
	add_child(root)
	if FX:
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


func _add_thicket(pos: Vector2, rot: float) -> void:
	var root := Node2D.new()
	root.position = pos
	root.rotation = rot
	root.z_index = Z_DECOR + clampi(int(pos.y / 40.0), -10, 40)
	add_child(root)
	for i in 6:
		var thorn := Line2D.new()
		thorn.width = 2.5
		thorn.default_color = Color(0.2, 0.42, 0.3, 0.9)
		var h := 28.0 + randf() * 36.0
		var lean := randf_range(-0.35, 0.35)
		thorn.points = PackedVector2Array([
			Vector2(i * 7.0 - 18.0, 8.0),
			Vector2(i * 7.0 - 18.0 + lean * 18.0, -h)
		])
		root.add_child(thorn)
