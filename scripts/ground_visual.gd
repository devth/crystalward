extends Node2D
## Ground + dirt roads + forest props.
## All ground art stays under actors (Ground node z=-200 absolute). Props use local z only.

# Spec: Dark Crystal + Legend — cool canopy under violet night, not dull lime
const FOREST_MODULATE := Color(0.55, 0.72, 0.68)
const FLOOR_EXTENT := 2200.0

const Z_FLOOR := 0
const Z_PLAZA := 1
const Z_PATH_EDGE := 10
const Z_PATH := 12
const Z_PATH_DETAIL := 14
const Z_PORTAL := 20
const Z_DECOR := 30
## Nothing solid on the road (path half-width ~58 + margin).
const PATH_CLEAR := 110.0


func _ready() -> void:
	y_sort_enabled = false
	z_as_relative = false
	z_index = -200
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
	_build_mist_fields()
	_build_terrain_features()  # forests / fairy rings / crystal groves
	_build_landmarks()
	_scatter_forest_props()
	_build_botanicals()  # Legend soft-dark blooms (restrained)
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
	# Lightwell glade — warm amber heart in cold violet night (spec art dir)
	var outer_mist := _ellipse(Vector2(0, 40), 380, 230, Color(0.28, 0.2, 0.42, 0.28), Z_PLAZA)
	add_child(outer_mist)
	var clear := _ellipse(Vector2(0, 40), 280, 170, Color(0.18, 0.28, 0.26, 0.5), Z_PLAZA)
	add_child(clear)
	var amber_glow := _ellipse(Vector2(0, 40), 200, 118, Color(0.95, 0.72, 0.35, 0.2), Z_PLAZA)
	add_child(amber_glow)
	var cyan_ring := _ellipse(Vector2(0, 40), 145, 85, Color(0.45, 0.92, 0.95, 0.22), Z_PLAZA)
	add_child(cyan_ring)
	var core_glow := _ellipse(Vector2(0, 40), 80, 48, Color(0.98, 0.88, 0.55, 0.18), Z_PLAZA)
	add_child(core_glow)
	# Ethereal crystal circle around the well (original Dark Crystal vibe)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1982
	for i in 8:
		var ang := TAU * float(i) / 8.0 + 0.2
		var p := Vector2(0, 40) + Vector2(cos(ang), sin(ang) * 0.72) * 165.0
		if PathNetwork and PathNetwork.dist_to_path(p) < PATH_CLEAR:
			continue
		var tint := Color(0.55, 0.9, 0.95, 0.9) if i % 2 == 0 else Color(0.95, 0.75, 0.45, 0.88)
		_add_ethereal_crystal(p, rng.randf_range(0.7, 1.05), tint, rng)


func _build_mist_fields() -> void:
	# Soft ethereal mist banks (behind props, local z under Ground)
	var banks := [
		[Vector2(-420, -200), Vector2(320, 140)],
		[Vector2(480, 180), Vector2(280, 120)],
		[Vector2(-200, 520), Vector2(360, 160)],
		[Vector2(300, -480), Vector2(260, 130)],
		[Vector2(-600, 100), Vector2(240, 100)],
	]
	for b in banks:
		var mist := _ellipse(b[0], b[1].x * 0.5, b[1].y * 0.5, Color(0.38, 0.28, 0.55, 0.14), Z_PLAZA + 2)
		add_child(mist)


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
		# Never plant solid decor on the road
		if PathNetwork.dist_to_path(pos) < PATH_CLEAR:
			continue
		match kind:
			"fairy_ring", "mountain":  # mountain legacy → fairy rings
				_add_fairy_ring(pos, radius, rng)
			"crystal_grove", "crystals":
				_add_crystal_grove(pos, radius, rng)
			_:
				_add_forest_cluster(pos, radius, round_tree, pine_tree, rng)


func _add_fairy_ring(center: Vector2, radius: float, rng: RandomNumberGenerator) -> void:
	## Soft mushroom/moss circle — ethereal glade marker (replaces mountains).
	var r := maxf(48.0, radius * 0.55)
	var moss := _ellipse(center, r * 1.15, r * 0.72, Color(0.18, 0.32, 0.26, 0.55), Z_DECOR - 4)
	add_child(moss)
	var glow := _ellipse(center, r * 0.95, r * 0.58, Color(0.55, 0.4, 0.85, 0.12), Z_DECOR - 3)
	add_child(glow)
	var ring_n := 10
	for i in ring_n:
		var ang := TAU * float(i) / float(ring_n) + rng.randf() * 0.12
		var p := center + Vector2(cos(ang), sin(ang) * 0.72) * r
		if PathNetwork and PathNetwork.dist_to_path(p) < PATH_CLEAR:
			continue
		_add_mushroom(p, rng.randf_range(0.75, 1.25), rng)
	# Center soft crystal sprout
	if PathNetwork == null or PathNetwork.dist_to_path(center) >= PATH_CLEAR:
		_add_ethereal_crystal(center + Vector2(0, -4), rng.randf_range(0.7, 1.0), Color(0.7, 0.5, 0.95, 0.85), rng)


func _add_crystal_grove(center: Vector2, radius: float, rng: RandomNumberGenerator) -> void:
	## Cluster of ethereal crystal spires (Dark Crystal vibe).
	var bed := _ellipse(center + Vector2(0, 8), radius * 0.7, radius * 0.38, Color(0.14, 0.1, 0.2, 0.55), Z_DECOR - 5)
	add_child(bed)
	var n := clampi(int(radius / 28.0), 4, 9)
	for i in n:
		var ang := TAU * float(i) / float(n) + rng.randf() * 0.4
		var o := Vector2(cos(ang), sin(ang) * 0.7) * radius * rng.randf_range(0.12, 0.72)
		var p := center + o
		if PathNetwork and PathNetwork.dist_to_path(p) < PATH_CLEAR:
			continue
		var tint := Color(0.55, 0.9, 0.95, 0.9) if i % 2 == 0 else Color(0.95, 0.75, 0.45, 0.88)
		_add_ethereal_crystal(p, rng.randf_range(0.85, 1.45), tint, rng)


func _add_mushroom(pos: Vector2, scale: float, rng: RandomNumberGenerator) -> void:
	var root := Node2D.new()
	root.position = pos
	root.scale = Vector2(scale, scale)
	root.z_index = Z_DECOR + clampi(int(pos.y / 80.0), -5, 20)
	add_child(root)
	var stem := Polygon2D.new()
	stem.polygon = PackedVector2Array([Vector2(-3, 6), Vector2(3, 6), Vector2(2, -8), Vector2(-2, -8)])
	stem.color = Color(0.75, 0.7, 0.8, 0.9)
	root.add_child(stem)
	var cap := Polygon2D.new()
	var cw := rng.randf_range(8.0, 12.0)
	cap.polygon = PackedVector2Array([
		Vector2(-cw, -4), Vector2(-cw * 0.6, -14), Vector2(0, -16),
		Vector2(cw * 0.6, -14), Vector2(cw, -4)
	])
	cap.color = Color(0.55, 0.35, 0.75, 0.92)
	root.add_child(cap)
	var spot := Polygon2D.new()
	spot.polygon = PackedVector2Array([Vector2(-3, -10), Vector2(0, -13), Vector2(2, -9)])
	spot.color = Color(0.95, 0.85, 0.55, 0.7)
	root.add_child(spot)


func _add_ethereal_crystal(pos: Vector2, scale: float, tint: Color, rng: RandomNumberGenerator) -> void:
	var root := Node2D.new()
	root.position = pos
	root.scale = Vector2(scale, scale)
	root.rotation = rng.randf_range(-0.15, 0.15)
	root.z_index = Z_DECOR + clampi(int(pos.y / 80.0), -5, 22)
	add_child(root)
	var h := rng.randf_range(28.0, 52.0)
	var w := rng.randf_range(7.0, 12.0)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, -h), Vector2(w * 0.55, -h * 0.55), Vector2(w * 0.35, 6),
		Vector2(-w * 0.3, 6), Vector2(-w * 0.5, -h * 0.5)
	])
	body.color = tint
	root.add_child(body)
	var facet := Polygon2D.new()
	facet.polygon = PackedVector2Array([
		Vector2(-w * 0.15, -h * 0.85), Vector2(w * 0.2, -h * 0.7), Vector2(0, -h * 0.35)
	])
	facet.color = tint.lightened(0.35)
	facet.color.a = 0.75
	root.add_child(facet)
	var glow := _ellipse(Vector2(0, 2), w * 1.4, w * 0.7, Color(tint.r, tint.g, tint.b, 0.18), -1)
	root.add_child(glow)


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
		if PathNetwork and PathNetwork.dist_to_path(pos) < PATH_CLEAR:
			continue
		var tex: Texture2D = pine_tree if (pine_tree and rng.randf() < 0.45) else round_tree
		if tex == null:
			continue
		_place_sprite(tex, pos, rng.randf_range(1.9, 2.9), 0.96)
	# Undergrowth thicket at center
	_add_thicket(center + Vector2(rng.randf_range(-20, 20), rng.randf_range(-10, 10)), rng.randf_range(-0.2, 0.2))


func _build_landmarks() -> void:
	# Plaza crystal markers — never on the road.
	var crystals: Array = [
		[Vector2(-240, -100), 0.95, Color(0.55, 0.9, 0.95, 0.9)],
		[Vector2(250, -80), 0.9, Color(0.95, 0.75, 0.45, 0.88)],
		[Vector2(-250, 160), 0.92, Color(0.7, 0.5, 0.95, 0.9)],
		[Vector2(240, 150), 0.95, Color(0.55, 0.9, 0.95, 0.9)],
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for s in crystals:
		if PathNetwork == null or PathNetwork.dist_to_path(s[0]) >= PATH_CLEAR:
			_add_ethereal_crystal(s[0], s[1], s[2], rng)


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
	# Spec: amber crystal light + cold violet motes (title fireflies)
	var amber := FX.spark_particles(self, Color(0.95, 0.75, 0.35, 0.5), 18, "star")
	amber.position = Vector2(0, 40)
	amber.z_index = Z_DECOR
	amber.amount = 18
	amber.lifetime = 4.0
	var pm := amber.process_material as ParticleProcessMaterial
	if pm:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 260.0
		pm.initial_velocity_min = 1.0
		pm.initial_velocity_max = 7.0
		pm.gravity = Vector3(0, -2.0, 0)
	var cyan := FX.spark_particles(self, Color(0.5, 0.95, 0.95, 0.4), 14, "glow")
	cyan.position = Vector2(0, 30)
	cyan.z_index = Z_DECOR
	cyan.amount = 14
	var violet := FX.spark_particles(self, Color(0.7, 0.45, 0.95, 0.32), 12, "magic")
	violet.position = Vector2(0, 60)
	violet.z_index = Z_DECOR
	violet.amount = 12


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
		if PathNetwork and PathNetwork.dist_to_path(pos) < PATH_CLEAR:
			continue
		if tree_sprites.is_empty():
			break
		_place_sprite(tree_sprites[i % tree_sprites.size()], pos, rng.randf_range(2.0, 2.9), 0.95)

	if bush_tex:
		for i in 8:
			var pos := _rand_map_pos(rng, 340, 1700)
			if PathNetwork and PathNetwork.dist_to_path(pos) < PATH_CLEAR:
				continue
			_place_sprite(bush_tex, pos, rng.randf_range(1.9, 2.6), 0.9)

	if stone_tex:
		for i in 5:
			var pos := _rand_map_pos(rng, 360, 1600)
			if PathNetwork and PathNetwork.dist_to_path(pos) < PATH_CLEAR:
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
	# Local z only under Ground (-200) — never compete with actors (5000+)
	s.z_index = Z_DECOR + clampi(int(pos.y / 80.0), -5, 25)
	s.offset = Vector2(0, -float(tex.get_height()) * 0.4)
	add_child(s)
	return s


## Ethereal path: bone-bark bed + warm amber glow vein (spec: amber light vs violet night).
func _add_path_ribbon(pts: PackedVector2Array, half_width: float) -> void:
	if pts.size() < 2:
		return
	var bed := Line2D.new()
	bed.width = half_width * 2.4
	bed.default_color = Color(0.12, 0.08, 0.14, 1.0)
	bed.begin_cap_mode = Line2D.LINE_CAP_ROUND
	bed.end_cap_mode = Line2D.LINE_CAP_ROUND
	bed.joint_mode = Line2D.LINE_JOINT_ROUND
	bed.antialiased = true
	bed.points = pts
	bed.z_index = Z_PATH_EDGE
	add_child(bed)

	var dirt := Line2D.new()
	dirt.width = half_width * 1.95
	dirt.default_color = Color(0.38, 0.28, 0.26, 1.0)  # warm bark-bone
	dirt.begin_cap_mode = Line2D.LINE_CAP_ROUND
	dirt.end_cap_mode = Line2D.LINE_CAP_ROUND
	dirt.joint_mode = Line2D.LINE_JOINT_ROUND
	dirt.antialiased = true
	dirt.points = pts
	dirt.z_index = Z_PATH
	add_child(dirt)

	var track := Line2D.new()
	track.width = half_width * 0.9
	track.default_color = Color(0.52, 0.4, 0.32, 1.0)
	track.begin_cap_mode = Line2D.LINE_CAP_ROUND
	track.end_cap_mode = Line2D.LINE_CAP_ROUND
	track.joint_mode = Line2D.LINE_JOINT_ROUND
	track.antialiased = true
	track.points = pts
	track.z_index = Z_PATH_DETAIL
	add_child(track)

	# Living crystal dust vein down the road
	var vein := Line2D.new()
	vein.width = 4.0
	vein.default_color = Color(0.85, 0.65, 0.35, 0.45)
	vein.begin_cap_mode = Line2D.LINE_CAP_ROUND
	vein.end_cap_mode = Line2D.LINE_CAP_ROUND
	vein.joint_mode = Line2D.LINE_JOINT_ROUND
	vein.antialiased = true
	vein.points = pts
	vein.z_index = Z_PATH_DETAIL + 1
	add_child(vein)

	var glow := Line2D.new()
	glow.width = 14.0
	glow.default_color = Color(0.55, 0.4, 0.85, 0.12)
	glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	glow.joint_mode = Line2D.LINE_JOINT_ROUND
	glow.antialiased = true
	glow.points = pts
	glow.z_index = Z_PATH_EDGE - 1
	add_child(glow)


func _add_spawn_portal(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	root.z_index = Z_PORTAL
	add_child(root)
	# Nightspawn gate — violet mist + amber rim
	var outer := _ellipse(Vector2.ZERO, 44, 26, Color(0.1, 0.06, 0.16, 0.92), 0)
	root.add_child(outer)
	var ring := _ellipse(Vector2.ZERO, 32, 19, Color(0.55, 0.3, 0.7, 0.55), 1)
	root.add_child(ring)
	var core := _ellipse(Vector2.ZERO, 14, 9, Color(0.9, 0.55, 0.4, 0.5), 2)
	root.add_child(core)
	if FX:
		var p := FX.spark_particles(root, Color(0.7, 0.45, 0.95, 0.5), 8, "magic")
		p.z_index = 3


func _add_standing_stone(pos: Vector2, scale: float) -> void:
	var root := Node2D.new()
	root.position = pos
	root.scale = Vector2(scale, scale)
	root.z_index = Z_DECOR + clampi(int(pos.y / 80.0), -5, 20)
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
	moss.color = Color(0.3, 0.5, 0.38, 0.8)
	root.add_child(moss)
	# Crystal fleck on stone
	var fleck := Polygon2D.new()
	fleck.polygon = PackedVector2Array([Vector2(-2, -22), Vector2(4, -18), Vector2(0, -12)])
	fleck.color = Color(0.55, 0.85, 0.9, 0.55)
	root.add_child(fleck)


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
