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
	_build_terrain_features()  # forests / mountains roads curve around
	_build_landmarks()
	_scatter_forest_props()
	# Botanical confetti disabled — kept readable
	# _build_botanicals()
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
	# Soft clearing around the Lightwell — not a hard diamond stamp
	var clear := _ellipse(Vector2(0, 40), 280, 170, Color(0.32, 0.48, 0.34, 0.35), Z_PLAZA)
	add_child(clear)
	var ring := _ellipse(Vector2(0, 40), 160, 95, Color(0.55, 0.72, 0.5, 0.18), Z_PLAZA)
	add_child(ring)
	var ring2 := _ellipse(Vector2(0, 40), 100, 58, Color(0.75, 0.7, 0.45, 0.12), Z_PLAZA)
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
		_add_path_ribbon(pts, 58.0)
		_add_spawn_portal(pts[0])
	if n_lanes == 0:
		push_warning("ground_visual: PathNetwork has no lanes — roads not drawn")


func _build_terrain_features() -> void:
	if PathNetwork == null:
		return
	var tree_tex: Texture2D = AssetPaths.load_texture(AssetPaths.FOREST_TREES) if AssetPaths else null
	var round_tree: Texture2D = null
	var pine_tree: Texture2D = null
	if tree_tex and tree_tex.get_width() >= 64 and tree_tex.get_height() >= 128:
		round_tree = _atlas(tree_tex, Rect2(0, 0, 64, 64))
		pine_tree = _atlas(tree_tex, Rect2(0, 64, 64, 64))

	var rng := RandomNumberGenerator.new()
	rng.seed = 9001
	for f in PathNetwork.features:
		var pos: Vector2 = f.get("pos", Vector2.ZERO)
		var kind: String = str(f.get("kind", "forest"))
		var radius: float = float(f.get("radius", 120.0))
		if kind == "mountain":
			_add_mountain_cluster(pos, radius, rng)
		else:
			_add_forest_cluster(pos, radius, round_tree, pine_tree, rng)


func _add_mountain_cluster(center: Vector2, radius: float, rng: RandomNumberGenerator) -> void:
	# Layered rock peaks — roads bend around these.
	var base := _ellipse(center + Vector2(0, 12), radius * 0.85, radius * 0.45, Color(0.18, 0.16, 0.2, 0.75), Z_DECOR - 5)
	add_child(base)
	for i in 5:
		var ang := TAU * float(i) / 5.0 + rng.randf() * 0.3
		var o := Vector2(cos(ang), sin(ang) * 0.7) * radius * rng.randf_range(0.15, 0.55)
		var peak := Polygon2D.new()
		var h := rng.randf_range(48.0, 90.0)
		var w := rng.randf_range(22.0, 40.0)
		peak.polygon = PackedVector2Array([
			Vector2(-w, 10), Vector2(-w * 0.4, -h * 0.55), Vector2(0, -h),
			Vector2(w * 0.35, -h * 0.5), Vector2(w, 10)
		])
		peak.color = Color(0.28, 0.26, 0.32).darkened(rng.randf() * 0.15)
		peak.position = center + o
		peak.z_index = Z_DECOR + clampi(int((center.y + o.y) / 40.0), -10, 40)
		add_child(peak)
		# Snow / crystal cap
		var cap := Polygon2D.new()
		cap.polygon = PackedVector2Array([
			Vector2(0, -h), Vector2(-w * 0.22, -h * 0.72), Vector2(w * 0.18, -h * 0.7)
		])
		cap.color = Color(0.75, 0.78, 0.85, 0.85)
		cap.position = peak.position
		cap.z_index = peak.z_index + 1
		add_child(cap)
	# A few standing stones on the slope
	for j in 3:
		var a2 := rng.randf() * TAU
		_add_standing_stone(center + Vector2(cos(a2), sin(a2) * 0.7) * radius * 0.7, rng.randf_range(0.7, 1.1))


func _add_forest_cluster(
	center: Vector2,
	radius: float,
	round_tree: Texture2D,
	pine_tree: Texture2D,
	rng: RandomNumberGenerator
) -> void:
	var count := int(clampf(radius / 18.0, 6.0, 16.0))
	for i in count:
		var ang := rng.randf() * TAU
		var r := radius * sqrt(rng.randf()) * 0.9
		var pos := center + Vector2(cos(ang), sin(ang) * 0.78) * r
		# Stay off the roads
		if PathNetwork and PathNetwork.dist_to_path(pos) < 70.0:
			continue
		var tex: Texture2D = pine_tree if (pine_tree and rng.randf() < 0.45) else round_tree
		if tex == null:
			continue
		_place_sprite(tex, pos, rng.randf_range(1.9, 2.9), 0.96)
	# Undergrowth thicket at center
	_add_thicket(center + Vector2(rng.randf_range(-20, 20), rng.randf_range(-10, 10)), rng.randf_range(-0.2, 0.2))


func _build_landmarks() -> void:
	# Plaza ring stones only — big forests/mountains come from features.
	var stones: Array = [
		[Vector2(-200, -80), 0.9], [Vector2(210, -60), 0.85],
		[Vector2(-220, 140), 0.9], [Vector2(200, 130), 0.95],
	]
	for s in stones:
		if PathNetwork == null or PathNetwork.dist_to_path(s[0]) > 55.0:
			_add_standing_stone(s[0], s[1])


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
	# Sparse motes near the well only
	var motes := FX.spark_particles(self, Color(0.9, 0.85, 0.55, 0.35), 10, "star")
	motes.position = Vector2(0, 40)
	motes.z_index = Z_DECOR
	motes.amount = 10
	motes.lifetime = 3.5
	var pm := motes.process_material as ParticleProcessMaterial
	if pm:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 160.0
		pm.initial_velocity_min = 1.0
		pm.initial_velocity_max = 6.0
		pm.gravity = Vector3(0, -2, 0)


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
	## Sparse filler only — main mass is feature clusters. No DawnLike (black tiles).
	var tree_tex: Texture2D = AssetPaths.load_texture(AssetPaths.FOREST_TREES) if AssetPaths else null
	var bush_tex: Texture2D = AssetPaths.load_texture(AssetPaths.FOREST_BUSHES) if AssetPaths else null
	var stone_tex: Texture2D = AssetPaths.load_texture(AssetPaths.FOREST_STONES) if AssetPaths else null

	var rng := RandomNumberGenerator.new()
	rng.seed = 4242

	var tree_sprites: Array[Texture2D] = []
	if tree_tex and tree_tex.get_width() >= 64 and tree_tex.get_height() >= 128:
		tree_sprites.append(_atlas(tree_tex, Rect2(0, 0, 64, 64)))
		tree_sprites.append(_atlas(tree_tex, Rect2(0, 64, 64, 64)))
	elif tree_tex:
		tree_sprites.append(tree_tex)

	for i in 18:
		var pos := _rand_map_pos(rng, 420, 1900)
		if pos.length() < 400.0:
			continue
		if PathNetwork and PathNetwork.dist_to_path(pos) < 95.0:
			continue
		if tree_sprites.is_empty():
			break
		_place_sprite(tree_sprites[i % tree_sprites.size()], pos, rng.randf_range(2.0, 2.9), 0.95)

	if bush_tex:
		for i in 8:
			var pos := _rand_map_pos(rng, 340, 1700)
			if PathNetwork and PathNetwork.dist_to_path(pos) < 85.0:
				continue
			_place_sprite(bush_tex, pos, rng.randf_range(1.9, 2.6), 0.9)

	if stone_tex:
		for i in 5:
			var pos := _rand_map_pos(rng, 360, 1600)
			if PathNetwork and PathNetwork.dist_to_path(pos) < 80.0:
				continue
			_place_sprite(stone_tex, pos, rng.randf_range(1.5, 2.1), 0.88)


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


## Smooth dirt road via layered Line2D (reads as one curve, not faceted strips).
func _add_path_ribbon(pts: PackedVector2Array, half_width: float) -> void:
	if pts.size() < 2:
		return
	var bed := Line2D.new()
	bed.width = half_width * 2.35
	bed.default_color = Color(0.16, 0.11, 0.07, 1.0)
	bed.begin_cap_mode = Line2D.LINE_CAP_ROUND
	bed.end_cap_mode = Line2D.LINE_CAP_ROUND
	bed.joint_mode = Line2D.LINE_JOINT_ROUND
	bed.antialiased = true
	bed.points = pts
	bed.z_index = Z_PATH_EDGE
	add_child(bed)

	var dirt := Line2D.new()
	dirt.width = half_width * 1.9
	dirt.default_color = Color(0.52, 0.38, 0.24, 1.0)
	dirt.begin_cap_mode = Line2D.LINE_CAP_ROUND
	dirt.end_cap_mode = Line2D.LINE_CAP_ROUND
	dirt.joint_mode = Line2D.LINE_JOINT_ROUND
	dirt.antialiased = true
	dirt.points = pts
	dirt.z_index = Z_PATH
	add_child(dirt)

	var track := Line2D.new()
	track.width = half_width * 0.85
	track.default_color = Color(0.62, 0.48, 0.30, 1.0)
	track.begin_cap_mode = Line2D.LINE_CAP_ROUND
	track.end_cap_mode = Line2D.LINE_CAP_ROUND
	track.joint_mode = Line2D.LINE_JOINT_ROUND
	track.antialiased = true
	track.points = pts
	track.z_index = Z_PATH_DETAIL
	add_child(track)

	# Soft moss edge guide
	var edge := Line2D.new()
	edge.width = 3.0
	edge.default_color = Color(0.28, 0.42, 0.26, 0.45)
	edge.begin_cap_mode = Line2D.LINE_CAP_ROUND
	edge.end_cap_mode = Line2D.LINE_CAP_ROUND
	edge.joint_mode = Line2D.LINE_JOINT_ROUND
	edge.points = pts
	edge.z_index = Z_PATH_DETAIL + 1
	add_child(edge)


func _add_spawn_portal(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	root.z_index = Z_PORTAL
	add_child(root)
	# Dark gate — readable but not a neon disco
	var outer := _ellipse(Vector2.ZERO, 40, 24, Color(0.12, 0.08, 0.14, 0.9), 0)
	root.add_child(outer)
	var ring := _ellipse(Vector2.ZERO, 30, 18, Color(0.55, 0.28, 0.42, 0.55), 1)
	root.add_child(ring)
	var core := _ellipse(Vector2.ZERO, 12, 8, Color(0.75, 0.45, 0.55, 0.55), 2)
	root.add_child(core)
	if FX:
		var p := FX.spark_particles(root, Color(0.8, 0.4, 0.55, 0.45), 6, "magic")
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
