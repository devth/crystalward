extends Node2D
## Ground + dirt roads + forest props.
## All ground art stays under actors (Ground node z=-200 absolute). Props use local z only.

# Soft natural canopy tint for sparse trees only
const FOREST_MODULATE := Color(0.48, 0.68, 0.52)
const FLOOR_EXTENT := 3200.0
## Soft dirt-road gradient texture (V = across road width). Cached once.
static var _dirt_tex: Texture2D
static var _dirt_edge_tex: Texture2D

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
	_build_elevation_base()  # soft material washes (grass/dirt/rock)
	_build_plaza()
	_build_paths()
	_build_mist_fields()
	_build_terrain_features()  # mountains, hills, lakes (not prop confetti)
	_build_landmarks()
	_scatter_forest_props()  # sparse canopy only
	_build_botanicals()      # light meadow accents
	# No heavy atmosphere particle cloud — keep scene readable


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
	## Sparse material washes only — floor shader carries most of the texture.
	if PathNetwork == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for ix in range(-8, 9):
		for iy in range(-7, 9):
			if (ix + iy * 3) % 2 == 0:
				continue  # half density
			var pos := Vector2(
				float(ix) * 240.0 + rng.randf_range(-40, 40),
				float(iy) * 220.0 + rng.randf_range(-30, 30)
			)
			if pos.length() < 220.0:
				continue  # keep plaza open
			if PathNetwork.dist_to_path(pos) < PATH_CLEAR * 0.9:
				continue
			var elev := PathNetwork.elevation_at(pos)
			if absf(elev) < 0.18:
				continue
			if elev > 0.0:
				var r := 50.0 + elev * 70.0
				var hill := _ellipse(pos, r, r * 0.55, Color(0.2, 0.38, 0.22, 0.1 + elev * 0.08), Z_HILL)
				add_child(hill)
			else:
				var r2 := 45.0 + absf(elev) * 60.0
				var hollow := _ellipse(pos, r2, r2 * 0.55, Color(0.18, 0.26, 0.28, 0.1 + absf(elev) * 0.08), Z_HILL)
				add_child(hollow)


func _build_plaza() -> void:
	## Open glade around the crystal — dirt/grass clearing, not fog or prop circle.
	var outer := _ellipse(Vector2(0, 40), 320, 200, Color(0.22, 0.32, 0.24, 0.35), Z_PLAZA)
	add_child(outer)
	var clear := _ellipse(Vector2(0, 40), 220, 140, Color(0.32, 0.28, 0.22, 0.4), Z_PLAZA)
	add_child(clear)
	# Soft packed earth pad the crystal sits on
	var pad := _ellipse(Vector2(0, 40), 90, 48, Color(0.4, 0.32, 0.24, 0.45), Z_PLAZA)
	add_child(pad)
	# Very subtle warm rim (not a fog ball)
	var warm := _ellipse(Vector2(0, 40), 70, 38, Color(0.9, 0.78, 0.45, 0.1), Z_PLAZA)
	add_child(warm)
	# Four standing stones only — landmarks, not clutter
	var rng := RandomNumberGenerator.new()
	rng.seed = 1982
	for i in 4:
		var ang := TAU * float(i) / 4.0 + 0.35
		var p := Vector2(0, 40) + Vector2(cos(ang), sin(ang) * 0.7) * 150.0
		if PathNetwork and PathNetwork.dist_to_path(p) < PATH_CLEAR:
			continue
		_add_standing_stone(p, rng.randf_range(0.85, 1.15))


func _build_mist_fields() -> void:
	## Very few soft mist banks — atmosphere, not haze soup.
	var banks := [
		[Vector2(-500, -180), Vector2(280, 120)],
		[Vector2(520, 200), Vector2(240, 100)],
		[Vector2(0, 1400), Vector2(300, 130)],
	]
	for b in banks:
		var mist := _ellipse(b[0], b[1].x * 0.5, b[1].y * 0.5, Color(0.35, 0.32, 0.45, 0.1), Z_PLAZA + 2)
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
				_add_lake(pos, radius, rng, false)
			"pond":
				_add_lake(pos, radius, rng, true)
			"fairy_ring":
				# Skip dense mushroom rings — floor materials + sparse botanicals are enough
				pass
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
	var foothill := _ellipse(center + Vector2(0, 28), radius * 1.25, radius * 0.38, Color(0.32, 0.48, 0.38, 0.4), Z_MOUNTAIN - 6)
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
		peak.color = Color(0.42, 0.38, 0.52).darkened(rng.randf() * 0.08)
		peak.position = center + o
		peak.z_index = Z_MOUNTAIN + clampi(int((center.y + o.y) / 60.0), -5, 15)
		add_child(peak)
		# Moss shoulder on lower slope of peak
		var moss_s := Polygon2D.new()
		moss_s.polygon = PackedVector2Array([
			Vector2(-w * 0.7, 10), Vector2(-w * 0.25, -h * 0.25), Vector2(w * 0.2, -h * 0.22), Vector2(w * 0.65, 10)
		])
		moss_s.color = Color(0.38, 0.58, 0.42, 0.55)
		moss_s.position = peak.position
		moss_s.z_index = peak.z_index + 1
		add_child(moss_s)
		# Pearl / champagne crystal cap
		var cap := Polygon2D.new()
		cap.polygon = PackedVector2Array([
			Vector2(0, -h), Vector2(-w * 0.3, -h * 0.7), Vector2(w * 0.24, -h * 0.68)
		])
		cap.color = Color(0.9, 0.94, 1.0, 0.85) if i % 2 == 0 else Color(0.98, 0.88, 0.55, 0.75)
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
	# Light crown of trees only
	var count := int(clampf(r / 28.0, 3.0, 8.0))
	for i in count:
		var ang := rng.randf() * TAU
		var rr := r * sqrt(rng.randf()) * 0.65
		var p := center + Vector2(cos(ang), sin(ang) * 0.7) * rr + Vector2(0, -r * 0.1)
		if PathNetwork and PathNetwork.dist_to_path(p) < PATH_CLEAR:
			continue
		var tex: Texture2D = pine_tree if (pine_tree and rng.randf() < 0.55) else round_tree
		if tex:
			_place_sprite(tex, p, rng.randf_range(2.0, 2.8), 0.95)


func _add_lake(center: Vector2, radius: float, rng: RandomNumberGenerator, is_pond: bool = false) -> void:
	## Swimmable lake or pond — soft shore, deep center, lilies/reeds. Wardens can swim here.
	var r := maxf(48.0 if is_pond else 70.0, radius)
	var aspect := 0.62 if is_pond else 0.6
	# Wide marshy shore
	var marsh := _ellipse(center, r * 1.32, r * (aspect + 0.18), Color(0.12, 0.28, 0.15, 0.48), Z_WATER)
	add_child(marsh)
	var shore := _ellipse(center, r * 1.16, r * (aspect + 0.12), Color(0.16, 0.24, 0.14, 0.72), Z_WATER + 1)
	add_child(shore)
	# Sandy/mud bank
	var bank := _ellipse(center, r * 1.06, r * (aspect + 0.05), Color(0.28, 0.24, 0.16, 0.4), Z_WATER + 2)
	add_child(bank)
	var wet := _ellipse(center, r * 1.0, r * aspect, Color(0.08, 0.16, 0.15, 0.55), Z_WATER + 2)
	add_child(wet)
	# Water body (matches PathNetwork swim ellipse ~0.92 / 0.58)
	var water_col := Color(0.32, 0.58, 0.68, 0.72) if is_pond else Color(0.28, 0.52, 0.65, 0.75)
	var water := _ellipse(center, r * 0.94, r * aspect, water_col, Z_WATER + 3)
	add_child(water)
	var deep := _ellipse(center + Vector2(r * 0.06, r * 0.04), r * 0.55, r * aspect * 0.58, Color(0.22, 0.38, 0.58, 0.65), Z_WATER + 4)
	add_child(deep)
	var shallows := _ellipse(center + Vector2(-r * 0.18, -r * 0.1), r * 0.38, r * aspect * 0.35, Color(0.48, 0.75, 0.78, 0.32), Z_WATER + 4)
	add_child(shallows)
	# Soft pearl-cyan rim light
	var rim := _ellipse(center, r * 0.96, r * aspect * 1.02, Color(0.55, 0.88, 0.95, 0.12), Z_WATER + 3)
	add_child(rim)
	# Specular glints
	var glint_n := 5 if is_pond else 10
	for i in glint_n:
		var g := _ellipse(
			center + Vector2(rng.randf_range(-r * 0.45, r * 0.45), rng.randf_range(-r * aspect * 0.5, r * aspect * 0.5)),
			rng.randf_range(6, 18), rng.randf_range(2.5, 7),
			Color(0.55, 0.9, 1.0, 0.18 + rng.randf() * 0.1), Z_WATER + 5
		)
		add_child(g)
	# Ethereal mist over water
	var mist := _ellipse(center + Vector2(0, -6), r * 0.75, r * aspect * 0.7, Color(0.45, 0.4, 0.75, 0.14), Z_WATER + 6)
	add_child(mist)
	# Sparse shore reeds only — materials carry the rest
	var edge_n := 4 if is_pond else 6
	for i in edge_n:
		var ang := TAU * float(i) / float(edge_n) + rng.randf() * 0.2
		var p := center + Vector2(cos(ang), sin(ang) * aspect) * r * rng.randf_range(0.95, 1.12)
		if PathNetwork and PathNetwork.dist_to_path(p) < PATH_CLEAR * 0.7:
			continue
		_add_reed_cluster(p, rng)
	# One lily pad on larger lakes only
	if not is_pond and rng.randf() < 0.6:
		var lp := center + Vector2(rng.randf_range(-r * 0.25, r * 0.25), rng.randf_range(-r * 0.15, r * 0.15))
		_add_lily_pad(lp, rng.randf_range(0.8, 1.1), rng)


func _add_lily_pad(pos: Vector2, scale: float, rng: RandomNumberGenerator) -> void:
	var pad := _ellipse(pos, 10.0 * scale, 7.0 * scale, Color(0.18, 0.48, 0.28, 0.85), Z_WATER + 5)
	add_child(pad)
	var notch := _ellipse(pos + Vector2(scale * 3, -scale * 2), 3.5 * scale, 2.5 * scale, Color(0.1, 0.28, 0.18, 0.5), Z_WATER + 5)
	add_child(notch)
	if rng.randf() < 0.45:
		var bloom := _ellipse(pos + Vector2(0, -2), 3.5 * scale, 3.0 * scale, Color(0.95, 0.75, 0.85, 0.8), Z_WATER + 6)
		add_child(bloom)
		var center := _ellipse(pos + Vector2(0, -2), 1.5 * scale, 1.3 * scale, Color(0.95, 0.9, 0.4, 0.85), Z_WATER + 6)
		add_child(center)


func _add_reed_cluster(pos: Vector2, rng: RandomNumberGenerator) -> void:
	for j in (2 + rng.randi() % 3):
		var reed := Line2D.new()
		reed.width = 2.0
		reed.default_color = Color(0.2, 0.48, 0.28, 0.88)
		var lean := rng.randf_range(-5, 5)
		reed.points = PackedVector2Array([
			Vector2(j * 3.0 - 3.0, 4),
			Vector2(j * 3.0 - 3.0 + lean, -12 - rng.randf() * 16)
		])
		reed.position = pos
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
	## Small crystal cluster — keep sparse so home crystal remains the hero.
	var bed := _ellipse(center + Vector2(0, 8), radius * 0.55, radius * 0.3, Color(0.18, 0.14, 0.22, 0.45), Z_DECOR - 5)
	add_child(bed)
	var n := clampi(int(radius / 40.0), 2, 4)
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
	var count := int(clampf(radius / 28.0, 4.0, 10.0))
	for i in count:
		var ang := rng.randf() * TAU
		var r := radius * sqrt(rng.randf()) * 0.9
		var pos := center + Vector2(cos(ang), sin(ang) * 0.78) * r
		if PathNetwork and PathNetwork.dist_to_path(pos) < PATH_CLEAR:
			continue
		var tex: Texture2D = pine_tree if (pine_tree and rng.randf() < 0.45) else round_tree
		if tex == null:
			continue
		_place_sprite(tex, pos, rng.randf_range(2.0, 2.9), 0.95)


func _build_landmarks() -> void:
	# Two small crystal markers far from well — don't compete with home crystal.
	var crystals: Array = [
		[Vector2(-280, -160), 0.75, Color(0.6, 0.88, 0.95, 0.85)],
		[Vector2(300, -140), 0.7, Color(0.95, 0.82, 0.5, 0.85)],
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
	# Champagne gold + lilac pearl motes (ethereal shimmer, light density)
	var amber := FX.spark_particles(self, Color(0.98, 0.88, 0.55, 0.45), 20, "star")
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
	var cyan := FX.spark_particles(self, Color(0.65, 0.92, 0.96, 0.38), 14, "glow")
	cyan.position = Vector2(0, 30)
	cyan.z_index = Z_DECOR
	cyan.amount = 14
	var violet := FX.spark_particles(self, Color(0.82, 0.68, 0.96, 0.3), 12, "magic")
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
	## Sparse canopy + a few rocks. Lushness lives in the floor shader, not prop spam.
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

	for i in 36:
		var pos := _rand_map_pos(rng, 380, 2200)
		if pos.length() < 340.0:
			continue
		if PathNetwork and PathNetwork.dist_to_path(pos) < PATH_CLEAR + 20.0:
			continue
		if tree_sprites.is_empty():
			break
		var elev := PathNetwork.elevation_at(pos) if PathNetwork else 0.0
		if elev < -0.15 and rng.randf() < 0.7:
			continue
		var sc := rng.randf_range(2.2, 3.2)
		_place_sprite(tree_sprites[i % tree_sprites.size()], pos, sc, 0.96)

	if bush_tex:
		for i in 14:
			var pos := _rand_map_pos(rng, 320, 1800)
			if pos.length() < 300.0:
				continue
			if PathNetwork and PathNetwork.dist_to_path(pos) < PATH_CLEAR + 15.0:
				continue
			_place_sprite(bush_tex, pos, rng.randf_range(1.8, 2.6), 0.92)

	if stone_tex:
		for i in 12:
			var pos := _rand_map_pos(rng, 300, 1600)
			if pos.length() < 280.0:
				continue
			if PathNetwork and PathNetwork.dist_to_path(pos) < PATH_CLEAR:
				continue
			_place_sprite(stone_tex, pos, rng.randf_range(1.4, 2.2), 0.9)

	# A few rocks near path verges only
	for i in 10:
		var pos := _rand_map_pos(rng, 250, 1500)
		if PathNetwork == null:
			break
		var d := PathNetwork.dist_to_path(pos)
		if d < PATH_CLEAR or d > 200.0 or pos.length() < 280.0:
			continue
		_add_standing_stone(pos, rng.randf_range(0.6, 1.0))


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


## Soft dirt road — one continuous packed-dirt ribbon (no multi-band stripes).
func _add_path_ribbon(pts: PackedVector2Array, half_width: float) -> void:
	if pts.size() < 2:
		return
	_ensure_dirt_textures()

	# Soft grass shoulder (low contrast with ground — not purple rings)
	var moss := Line2D.new()
	moss.width = half_width * 2.35
	moss.default_color = Color(0.2, 0.34, 0.22, 0.32)
	moss.begin_cap_mode = Line2D.LINE_CAP_ROUND
	moss.end_cap_mode = Line2D.LINE_CAP_ROUND
	moss.joint_mode = Line2D.LINE_JOINT_ROUND
	moss.antialiased = true
	moss.points = pts
	moss.z_index = Z_PATH_EDGE - 1
	add_child(moss)

	# Single dirt body with soft edge gradient baked into texture
	var dirt := Line2D.new()
	dirt.width = half_width * 1.9
	dirt.default_color = Color(1, 1, 1, 1)
	dirt.begin_cap_mode = Line2D.LINE_CAP_ROUND
	dirt.end_cap_mode = Line2D.LINE_CAP_ROUND
	dirt.joint_mode = Line2D.LINE_JOINT_ROUND
	dirt.antialiased = true
	dirt.points = pts
	dirt.texture = _dirt_tex
	dirt.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	dirt.z_index = Z_PATH
	add_child(dirt)


func _ensure_dirt_textures() -> void:
	if _dirt_tex != null and _dirt_edge_tex != null:
		return
	_dirt_tex = _make_dirt_gradient_tex(false)
	_dirt_edge_tex = _make_dirt_gradient_tex(true)


func _make_dirt_gradient_tex(for_edge: bool) -> Texture2D:
	## V axis = across road width. Soft continuous dirt, not bands.
	var w := 16
	var h := 96
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var v := float(y) / float(h - 1)  # 0..1 across width
		var edge := absf(v - 0.5) * 2.0   # 0 center → 1 edge
		# Smooth falloff (no hard steps)
		var e2 := edge * edge
		var e_smooth := e2 * e2 * (1.0 - 0.15 * edge)  # softer mid, gentle rim

		var col: Color
		if for_edge:
			var soil := Color(0.28, 0.2, 0.14, 1.0)
			var mid := Color(0.4, 0.3, 0.22, 0.85)
			col = mid.lerp(soil, clampf(e_smooth * 1.1, 0.0, 1.0))
			col.a = clampf(0.55 - e_smooth * 0.5, 0.05, 0.6)
		else:
			# Packed dirt: center slightly lighter, edges blend to grass — one smooth falloff
			var crown := Color(0.55, 0.42, 0.30, 1.0)
			var body := Color(0.42, 0.32, 0.22, 1.0)
			var rim := Color(0.3, 0.22, 0.16, 1.0)
			# Smoothstep across full width (no hard bands)
			var t := clampf(edge, 0.0, 1.0)
			t = t * t * (3.0 - 2.0 * t)
			col = crown.lerp(body, t * 0.7).lerp(rim, t)
			col.a = clampf(1.0 - pow(edge, 3.2) * 0.35, 0.75, 1.0)

		# Fine grain — subtle, not stripes
		for x in w:
			var n := fposmod(sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453, 1.0)
			var grain := (n - 0.5) * 0.04
			var c := Color(
				clampf(col.r + grain, 0.0, 1.0),
				clampf(col.g + grain * 0.85, 0.0, 1.0),
				clampf(col.b + grain * 0.7, 0.0, 1.0),
				col.a
			)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	return tex


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
