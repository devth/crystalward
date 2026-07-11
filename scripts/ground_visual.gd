extends Node2D
## Ground + dirt roads + forest props.
## All ground art stays under actors (Ground node z=-200 absolute). Props use local z only.

# Spec: Dark Crystal + Legend — cool canopy under violet night, not dull lime
const FOREST_MODULATE := Color(0.52, 0.84, 0.62)
const FLOOR_EXTENT := 2800.0

const Z_FLOOR := 0
const Z_WATER := 2
const Z_HILL := 4
const Z_PLAZA := 6
const Z_PATH_EDGE := 10
const Z_PATH := 12
const Z_PATH_DETAIL := 14
const Z_PORTAL := 20
const Z_DECOR := 30
const Z_MOUNTAIN := 40
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
	_build_elevation_base()  # soft hill/valley washes under props
	_build_plaza()
	_build_paths()
	_build_mist_fields()
	_build_terrain_features()  # mountains, hills, lakes, forests
	_build_landmarks()
	_scatter_forest_props()
	_build_botanicals()
	_build_atmosphere_light()


func _build_floor() -> void:
	var e := FLOOR_EXTENT
	var floor_poly := Polygon2D.new()
	floor_poly.polygon = PackedVector2Array([
		Vector2(-e, -e * 0.85), Vector2(e, -e * 0.85), Vector2(e, e * 0.95), Vector2(-e, e * 0.95)
	])
	# Dense UV so elevation/biome noise reads lush at play zoom
	floor_poly.uv = PackedVector2Array([
		Vector2(0, 0), Vector2(36, 0), Vector2(36, 30), Vector2(0, 30)
	])
	floor_poly.color = Color.WHITE
	floor_poly.z_index = Z_FLOOR
	var fm := ShaderMaterial.new()
	var lush := load("res://shaders/lush_ground.gdshader") as Shader
	if lush:
		fm.shader = lush
		floor_poly.material = fm
	else:
		floor_poly.color = Color(0.16, 0.42, 0.22)
	add_child(floor_poly)


func _build_elevation_base() -> void:
	## Contour washes + stacked rings so hills/valleys read at a glance.
	if PathNetwork == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	# Dense grid of soft elevation blobs across the whole basin
	for ix in range(-11, 12):
		for iy in range(-9, 12):
			var pos := Vector2(
				float(ix) * 180.0 + rng.randf_range(-50, 50),
				float(iy) * 165.0 + rng.randf_range(-40, 40)
			)
			if pos.length() < 160.0:
				continue
			if PathNetwork.dist_to_path(pos) < PATH_CLEAR * 0.75:
				continue
			var elev := PathNetwork.elevation_at(pos)
			if absf(elev) < 0.08:
				continue
			if elev > 0.0:
				var r := 55.0 + elev * 110.0
				var a := 0.14 + elev * 0.18
				var hill := _ellipse(pos, r, r * 0.58, Color(0.1, 0.34, 0.16, a), Z_HILL)
				add_child(hill)
				var mid := _ellipse(pos + Vector2(0, -r * 0.1), r * 0.62, r * 0.36, Color(0.16, 0.42, 0.2, a * 0.9), Z_HILL + 1)
				add_child(mid)
				var crest := _ellipse(pos + Vector2(0, -r * 0.2), r * 0.32, r * 0.18, Color(0.28, 0.52, 0.26, 0.12 + elev * 0.14), Z_HILL + 2)
				add_child(crest)
				# Shadow on "north" slope for depth
				var shade := _ellipse(pos + Vector2(0, r * 0.22), r * 0.7, r * 0.22, Color(0.04, 0.08, 0.06, 0.1 + elev * 0.08), Z_HILL)
				add_child(shade)
			else:
				var r2 := 50.0 + absf(elev) * 100.0
				var a2 := 0.16 + absf(elev) * 0.18
				var hollow := _ellipse(pos, r2, r2 * 0.58, Color(0.06, 0.12, 0.16, a2), Z_HILL)
				add_child(hollow)
				var wet := _ellipse(pos, r2 * 0.65, r2 * 0.38, Color(0.08, 0.18, 0.22, a2 * 0.7), Z_HILL + 1)
				add_child(wet)
	# Explicit contour rings around major landmarks
	for f in PathNetwork.features:
		var kind: String = str(f.get("kind", ""))
		if kind not in ["mountain", "hill", "lake"]:
			continue
		var c: Vector2 = f.get("pos", Vector2.ZERO)
		var rad: float = float(f.get("radius", 100.0))
		var elev_f: float = float(f.get("elev", 0.0))
		for ring_i in 3:
			var t := 0.45 + float(ring_i) * 0.28
			var rr := rad * t
			if elev_f > 0.0:
				var ring := _ellipse(c, rr * 1.15, rr * 0.62, Color(0.12, 0.36, 0.18, 0.08 + elev_f * 0.06), Z_HILL)
				add_child(ring)
			else:
				var bowl := _ellipse(c, rr * 1.1, rr * 0.6, Color(0.06, 0.12, 0.18, 0.1 + absf(elev_f) * 0.08), Z_HILL)
				add_child(bowl)


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
	# Soft ethereal mist banks across valleys and lake bowls
	var banks := [
		[Vector2(-420, -200), Vector2(340, 150)],
		[Vector2(480, 180), Vector2(300, 130)],
		[Vector2(-200, 520), Vector2(380, 170)],
		[Vector2(300, -480), Vector2(280, 140)],
		[Vector2(-600, 100), Vector2(260, 110)],
		[Vector2(100, 1100), Vector2(320, 150)],
		[Vector2(-400, 900), Vector2(280, 130)],
		[Vector2(360, 640), Vector2(300, 140)],
		[Vector2(-500, 480), Vector2(260, 120)],
		[Vector2(0, 1600), Vector2(360, 160)],
		[Vector2(200, 200), Vector2(240, 110)],
	]
	for b in banks:
		var mist := _ellipse(b[0], b[1].x * 0.5, b[1].y * 0.5, Color(0.36, 0.26, 0.52, 0.16), Z_PLAZA + 2)
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
			"mountain":
				_add_mountain(pos, radius, rng)
			"hill":
				_add_hill(pos, radius, rng, round_tree, pine_tree)
			"lake":
				_add_lake(pos, radius, rng)
			"fairy_ring":
				_add_fairy_ring(pos, radius, rng)
			"crystal_grove", "crystals":
				_add_crystal_grove(pos, radius, rng)
			_:
				_add_forest_cluster(pos, radius, round_tree, pine_tree, rng)


func _add_mountain(center: Vector2, radius: float, rng: RandomNumberGenerator) -> void:
	## Layered rock peaks with moss shoulders — path winds around these.
	var base := _ellipse(center + Vector2(0, 22), radius * 1.15, radius * 0.52, Color(0.09, 0.08, 0.13, 0.9), Z_MOUNTAIN - 5)
	add_child(base)
	# Moss skirts (two layers for lush foothills)
	var skirt := _ellipse(center + Vector2(0, 12), radius * 1.05, radius * 0.46, Color(0.12, 0.3, 0.16, 0.62), Z_MOUNTAIN - 4)
	add_child(skirt)
	var foothill := _ellipse(center + Vector2(0, 28), radius * 1.25, radius * 0.38, Color(0.1, 0.26, 0.14, 0.4), Z_MOUNTAIN - 6)
	add_child(foothill)
	var peaks := 6 + int(radius / 40.0)
	for i in peaks:
		var ang := -0.55 + float(i) * 0.32 + rng.randf() * 0.1
		var o := Vector2(cos(ang), sin(ang) * 0.42) * radius * rng.randf_range(0.02, 0.5)
		var h := rng.randf_range(radius * 0.65, radius * 1.15)
		var w := rng.randf_range(radius * 0.16, radius * 0.34)
		var peak := Polygon2D.new()
		peak.polygon = PackedVector2Array([
			Vector2(-w, 16), Vector2(-w * 0.5, -h * 0.48), Vector2(0, -h),
			Vector2(w * 0.42, -h * 0.46), Vector2(w, 16)
		])
		peak.color = Color(0.24, 0.22, 0.3).darkened(rng.randf() * 0.12)
		peak.position = center + o
		peak.z_index = Z_MOUNTAIN + clampi(int((center.y + o.y) / 60.0), -5, 15)
		add_child(peak)
		# Moss shoulder on lower slope of peak
		var moss_s := Polygon2D.new()
		moss_s.polygon = PackedVector2Array([
			Vector2(-w * 0.7, 10), Vector2(-w * 0.25, -h * 0.25), Vector2(w * 0.2, -h * 0.22), Vector2(w * 0.65, 10)
		])
		moss_s.color = Color(0.18, 0.36, 0.2, 0.55)
		moss_s.position = peak.position
		moss_s.z_index = peak.z_index + 1
		add_child(moss_s)
		# Snow / crystal cap
		var cap := Polygon2D.new()
		cap.polygon = PackedVector2Array([
			Vector2(0, -h), Vector2(-w * 0.3, -h * 0.7), Vector2(w * 0.24, -h * 0.68)
		])
		cap.color = Color(0.78, 0.88, 0.96, 0.8) if i % 2 == 0 else Color(0.92, 0.78, 0.48, 0.7)
		cap.position = peak.position
		cap.z_index = peak.z_index + 2
		add_child(cap)
	# Standing stones + small pines on slope
	for j in 6:
		var a2 := rng.randf() * TAU
		var sp := center + Vector2(cos(a2), sin(a2) * 0.65) * radius * rng.randf_range(0.55, 0.95)
		if PathNetwork and PathNetwork.dist_to_path(sp) < PATH_CLEAR:
			continue
		_add_standing_stone(sp, rng.randf_range(0.7, 1.2))


func _add_hill(
	center: Vector2,
	radius: float,
	rng: RandomNumberGenerator,
	round_tree: Texture2D,
	pine_tree: Texture2D
) -> void:
	## Soft elevated moss mound with dense crown of trees.
	var r := maxf(60.0, radius)
	var base := _ellipse(center + Vector2(0, 10), r * 1.2, r * 0.62, Color(0.08, 0.24, 0.12, 0.55), Z_HILL)
	add_child(base)
	var mid := _ellipse(center, r * 0.92, r * 0.52, Color(0.12, 0.36, 0.16, 0.52), Z_HILL + 1)
	add_child(mid)
	var upper := _ellipse(center + Vector2(0, -r * 0.08), r * 0.68, r * 0.36, Color(0.18, 0.42, 0.2, 0.48), Z_HILL + 2)
	add_child(upper)
	var crown := _ellipse(center + Vector2(0, -r * 0.16), r * 0.42, r * 0.24, Color(0.26, 0.5, 0.26, 0.42), Z_HILL + 3)
	add_child(crown)
	# North-side shade for elevation read
	var shade := _ellipse(center + Vector2(0, r * 0.28), r * 0.85, r * 0.2, Color(0.04, 0.08, 0.05, 0.22), Z_HILL)
	add_child(shade)
	# Trees denser on hilltop
	var count := int(clampf(r / 16.0, 8.0, 20.0))
	for i in count:
		var ang := rng.randf() * TAU
		var rr := r * sqrt(rng.randf()) * 0.75
		var p := center + Vector2(cos(ang), sin(ang) * 0.7) * rr + Vector2(0, -r * 0.1)
		if PathNetwork and PathNetwork.dist_to_path(p) < PATH_CLEAR:
			continue
		var tex: Texture2D = pine_tree if (pine_tree and rng.randf() < 0.55) else round_tree
		if tex:
			_place_sprite(tex, p, rng.randf_range(2.1, 3.1), 0.97)
	# Undergrowth
	_add_thicket(center + Vector2(rng.randf_range(-20, 20), rng.randf_range(-8, 12)), rng.randf_range(-0.2, 0.2))


func _add_lake(center: Vector2, radius: float, rng: RandomNumberGenerator) -> void:
	## Still water with shore moss and reed flecks — road skirts the shore.
	var r := maxf(70.0, radius)
	# Wide marshy shore for lush wet-land feel
	var marsh := _ellipse(center, r * 1.28, r * 0.82, Color(0.12, 0.26, 0.14, 0.45), Z_WATER)
	add_child(marsh)
	var shore := _ellipse(center, r * 1.14, r * 0.74, Color(0.14, 0.22, 0.14, 0.7), Z_WATER + 1)
	add_child(shore)
	var wet := _ellipse(center, r * 1.04, r * 0.66, Color(0.09, 0.16, 0.14, 0.55), Z_WATER + 2)
	add_child(wet)
	# Water body
	var water := _ellipse(center, r * 0.94, r * 0.6, Color(0.1, 0.3, 0.42, 0.82), Z_WATER + 3)
	add_child(water)
	var deep := _ellipse(center + Vector2(10, 5), r * 0.58, r * 0.36, Color(0.06, 0.16, 0.32, 0.7), Z_WATER + 4)
	add_child(deep)
	var shallows := _ellipse(center + Vector2(-r * 0.15, -r * 0.08), r * 0.35, r * 0.2, Color(0.2, 0.45, 0.48, 0.35), Z_WATER + 4)
	add_child(shallows)
	# Specular glints
	for i in 8:
		var g := _ellipse(
			center + Vector2(rng.randf_range(-r * 0.45, r * 0.45), rng.randf_range(-r * 0.28, r * 0.28)),
			rng.randf_range(8, 20), rng.randf_range(3, 8),
			Color(0.55, 0.88, 0.98, 0.22), Z_WATER + 5
		)
		add_child(g)
	# Ethereal mist over water
	var mist := _ellipse(center + Vector2(0, -8), r * 0.78, r * 0.45, Color(0.48, 0.38, 0.72, 0.16), Z_WATER + 6)
	add_child(mist)
	# Shore crystals / reeds / grass
	for i in 10:
		var ang := TAU * float(i) / 10.0 + rng.randf() * 0.18
		var p := center + Vector2(cos(ang), sin(ang) * 0.65) * r * rng.randf_range(0.9, 1.15)
		if PathNetwork and PathNetwork.dist_to_path(p) < PATH_CLEAR * 0.7:
			continue
		if rng.randf() < 0.35:
			_add_ethereal_crystal(p, rng.randf_range(0.45, 0.8), Color(0.5, 0.85, 0.95, 0.7), rng)
		else:
			var reed := Line2D.new()
			reed.width = 2.2
			reed.default_color = Color(0.22, 0.48, 0.28, 0.9)
			reed.points = PackedVector2Array([Vector2(0, 4), Vector2(rng.randf_range(-4, 4), -16 - rng.randf() * 14)])
			reed.position = p
			reed.z_index = Z_DECOR
			add_child(reed)


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
	var count := int(clampf(radius / 12.0, 10.0, 28.0))
	for i in count:
		var ang := rng.randf() * TAU
		var r := radius * sqrt(rng.randf()) * 0.95
		var pos := center + Vector2(cos(ang), sin(ang) * 0.78) * r
		# Stay off the roads
		if PathNetwork and PathNetwork.dist_to_path(pos) < PATH_CLEAR:
			continue
		var tex: Texture2D = pine_tree if (pine_tree and rng.randf() < 0.45) else round_tree
		if tex == null:
			continue
		_place_sprite(tex, pos, rng.randf_range(2.0, 3.2), 0.97)
	# Undergrowth thickets
	for t in 3:
		var o := Vector2(rng.randf_range(-radius * 0.4, radius * 0.4), rng.randf_range(-radius * 0.3, radius * 0.3))
		if PathNetwork and PathNetwork.dist_to_path(center + o) < PATH_CLEAR:
			continue
		_add_thicket(center + o, rng.randf_range(-0.25, 0.25))


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
	## Dense canopy filler across the basin — main mass still from feature clusters.
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

	for i in 110:
		var pos := _rand_map_pos(rng, 280, 2300)
		if pos.length() < 260.0:
			continue
		if PathNetwork and PathNetwork.dist_to_path(pos) < PATH_CLEAR:
			continue
		if tree_sprites.is_empty():
			break
		# Prefer denser growth on high ground; keep some in mid elevations
		var elev := PathNetwork.elevation_at(pos) if PathNetwork else 0.0
		if elev < -0.2 and rng.randf() < 0.65:
			continue  # sparse canopy over lake bowls
		if elev < 0.05 and rng.randf() < 0.25:
			continue
		var sc := rng.randf_range(2.1, 3.4) * (1.0 + clampf(elev, 0.0, 0.7) * 0.25)
		_place_sprite(tree_sprites[i % tree_sprites.size()], pos, sc, 0.97)

	if bush_tex:
		for i in 55:
			var pos := _rand_map_pos(rng, 220, 2100)
			if PathNetwork and PathNetwork.dist_to_path(pos) < PATH_CLEAR:
				continue
			_place_sprite(bush_tex, pos, rng.randf_range(1.8, 3.0), 0.94)

	if stone_tex:
		for i in 32:
			var pos := _rand_map_pos(rng, 240, 2000)
			if PathNetwork and PathNetwork.dist_to_path(pos) < PATH_CLEAR:
				continue
			_place_sprite(stone_tex, pos, rng.randf_range(1.4, 2.5), 0.9)

	# Rock clusters on high ground / path verges
	for i in 36:
		var pos := _rand_map_pos(rng, 180, 1900)
		if PathNetwork == null:
			break
		var d := PathNetwork.dist_to_path(pos)
		if d < PATH_CLEAR or d > 260.0:
			continue
		var elev2 := PathNetwork.elevation_at(pos)
		if elev2 < 0.1 and rng.randf() < 0.4:
			continue
		_add_standing_stone(pos, rng.randf_range(0.55, 1.25))

	# Extra thickets for undergrowth density
	for i in 24:
		var pos := _rand_map_pos(rng, 300, 1800)
		if PathNetwork and PathNetwork.dist_to_path(pos) < PATH_CLEAR + 20.0:
			continue
		_add_thicket(pos, rng.randf_range(-0.3, 0.3))


func _rand_map_pos(rng: RandomNumberGenerator, min_r: float, max_r: float) -> Vector2:
	var ang := rng.randf() * TAU
	var t := rng.randf()
	# Bias slightly south so the long approach road is flanked by forest
	var r := lerpf(min_r, max_r, t * t * 0.3 + t * 0.7)
	var pos := Vector2(cos(ang), sin(ang) * 0.85) * r
	# Stretch south for long path maps
	if pos.y > 0.0:
		pos.y *= 1.15
	return pos + Vector2(rng.randf_range(-28, 28), rng.randf_range(-18, 18))


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


## Ethereal path: mossy verge + bark dirt + amber crystal vein.
func _add_path_ribbon(pts: PackedVector2Array, half_width: float) -> void:
	if pts.size() < 2:
		return
	# Soft moss verge under the road
	var moss := Line2D.new()
	moss.width = half_width * 2.85
	moss.default_color = Color(0.12, 0.22, 0.16, 0.55)
	moss.begin_cap_mode = Line2D.LINE_CAP_ROUND
	moss.end_cap_mode = Line2D.LINE_CAP_ROUND
	moss.joint_mode = Line2D.LINE_JOINT_ROUND
	moss.antialiased = true
	moss.points = pts
	moss.z_index = Z_PATH_EDGE - 2
	add_child(moss)

	var bed := Line2D.new()
	bed.width = half_width * 2.45
	bed.default_color = Color(0.10, 0.07, 0.12, 1.0)
	bed.begin_cap_mode = Line2D.LINE_CAP_ROUND
	bed.end_cap_mode = Line2D.LINE_CAP_ROUND
	bed.joint_mode = Line2D.LINE_JOINT_ROUND
	bed.antialiased = true
	bed.points = pts
	bed.z_index = Z_PATH_EDGE
	add_child(bed)

	var dirt := Line2D.new()
	dirt.width = half_width * 1.95
	dirt.default_color = Color(0.42, 0.30, 0.24, 1.0)
	dirt.begin_cap_mode = Line2D.LINE_CAP_ROUND
	dirt.end_cap_mode = Line2D.LINE_CAP_ROUND
	dirt.joint_mode = Line2D.LINE_JOINT_ROUND
	dirt.antialiased = true
	dirt.points = pts
	dirt.z_index = Z_PATH
	add_child(dirt)

	var track := Line2D.new()
	track.width = half_width * 0.95
	track.default_color = Color(0.55, 0.42, 0.32, 1.0)
	track.begin_cap_mode = Line2D.LINE_CAP_ROUND
	track.end_cap_mode = Line2D.LINE_CAP_ROUND
	track.joint_mode = Line2D.LINE_JOINT_ROUND
	track.antialiased = true
	track.points = pts
	track.z_index = Z_PATH_DETAIL
	add_child(track)

	# Twin wheel ruts
	var rut := Line2D.new()
	rut.width = 2.5
	rut.default_color = Color(0.22, 0.14, 0.12, 0.55)
	rut.begin_cap_mode = Line2D.LINE_CAP_ROUND
	rut.end_cap_mode = Line2D.LINE_CAP_ROUND
	rut.joint_mode = Line2D.LINE_JOINT_ROUND
	rut.antialiased = true
	rut.points = pts
	rut.z_index = Z_PATH_DETAIL + 1
	add_child(rut)

	var vein := Line2D.new()
	vein.width = 5.0
	vein.default_color = Color(0.92, 0.70, 0.35, 0.5)
	vein.begin_cap_mode = Line2D.LINE_CAP_ROUND
	vein.end_cap_mode = Line2D.LINE_CAP_ROUND
	vein.joint_mode = Line2D.LINE_JOINT_ROUND
	vein.antialiased = true
	vein.points = pts
	vein.z_index = Z_PATH_DETAIL + 2
	add_child(vein)

	var glow := Line2D.new()
	glow.width = 18.0
	glow.default_color = Color(0.58, 0.42, 0.9, 0.14)
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
