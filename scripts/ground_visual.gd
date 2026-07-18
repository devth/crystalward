extends Node2D
## Ground + dirt roads + forest props.
## All ground art stays under actors (Ground node z=-200 absolute). Props use local z only.

# Thra canopy tint — overridden per campaign look
const FOREST_MODULATE := Color(0.42, 0.58, 0.52)
const FLOOR_EXTENT := 3200.0
## Soft dirt-road gradient texture (V = across road width). Cached once.
static var _dirt_tex: Texture2D
static var _dirt_edge_tex: Texture2D
var _look: String = "homeland"
var _forest_mod: Color = FOREST_MODULATE

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
	_look = Campaign.current_look() if Campaign else "homeland"
	_forest_mod = _look_forest_modulate()
	_dirt_tex = null
	_dirt_edge_tex = null
	_build_floor()
	_build_altitude_field()  # continuous painted height bands
	_build_elevation_base()  # material washes following elevation
	_build_plaza()
	_build_paths()
	_build_mist_fields()
	_build_terrain_features()  # soft hills, water, canopy washes only
	_build_atmosphere_light()
	# No scattered tree/rock stickers, mountains, or crystal prop clutter.


func _look_forest_modulate() -> Color:
	match _look:
		"homeland":
			# Soft Gelfling / Legend glade — warm moss, no violet cast
			return Color(0.52, 0.72, 0.48)
		"twinveil":
			return Color(0.40, 0.58, 0.58)
		"mire":
			return Color(0.32, 0.48, 0.42)
		"march":
			return Color(0.38, 0.42, 0.48)
		"gate":
			return Color(0.36, 0.32, 0.48)
		_:
			return FOREST_MODULATE


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
		_apply_look_to_ground_shader(fm)
		floor_poly.material = fm
	else:
		floor_poly.color = Color(0.22, 0.42, 0.28) if _look == "homeland" else Color(0.14, 0.30, 0.26)
	add_child(floor_poly)


func _apply_look_to_ground_shader(fm: ShaderMaterial) -> void:
	## Per-level ground palette. Homeland = gentle Legend / Gelfling meadow.
	match _look:
		"homeland":
			fm.set_shader_parameter("col_shadow", Color(0.12, 0.14, 0.10))
			fm.set_shader_parameter("col_grass_deep", Color(0.18, 0.36, 0.20))
			fm.set_shader_parameter("col_grass", Color(0.30, 0.52, 0.28))
			fm.set_shader_parameter("col_grass_lit", Color(0.48, 0.68, 0.36))
			fm.set_shader_parameter("col_dirt_dark", Color(0.28, 0.24, 0.16))
			fm.set_shader_parameter("col_dirt", Color(0.46, 0.40, 0.28))
			fm.set_shader_parameter("col_dirt_lit", Color(0.58, 0.52, 0.36))
			fm.set_shader_parameter("col_sand", Color(0.62, 0.58, 0.42))
			fm.set_shader_parameter("col_rock", Color(0.36, 0.38, 0.34))
			fm.set_shader_parameter("col_rock_lit", Color(0.50, 0.52, 0.46))
			fm.set_shader_parameter("col_wet", Color(0.22, 0.38, 0.32))
			fm.set_shader_parameter("col_moss", Color(0.36, 0.55, 0.30))
		"twinveil":
			fm.set_shader_parameter("col_grass_deep", Color(0.14, 0.28, 0.28))
			fm.set_shader_parameter("col_grass", Color(0.22, 0.40, 0.38))
			fm.set_shader_parameter("col_grass_lit", Color(0.36, 0.55, 0.52))
			fm.set_shader_parameter("col_wet", Color(0.18, 0.32, 0.42))
			fm.set_shader_parameter("col_moss", Color(0.28, 0.48, 0.44))
		"mire":
			fm.set_shader_parameter("col_shadow", Color(0.08, 0.10, 0.10))
			fm.set_shader_parameter("col_grass_deep", Color(0.10, 0.22, 0.18))
			fm.set_shader_parameter("col_grass", Color(0.16, 0.32, 0.26))
			fm.set_shader_parameter("col_wet", Color(0.12, 0.22, 0.28))
			fm.set_shader_parameter("col_moss", Color(0.22, 0.38, 0.28))
		"march":
			fm.set_shader_parameter("col_grass_deep", Color(0.16, 0.20, 0.22))
			fm.set_shader_parameter("col_grass", Color(0.24, 0.30, 0.32))
			fm.set_shader_parameter("col_grass_lit", Color(0.36, 0.40, 0.38))
			fm.set_shader_parameter("col_rock", Color(0.30, 0.28, 0.36))
		"gate":
			fm.set_shader_parameter("col_shadow", Color(0.08, 0.06, 0.12))
			fm.set_shader_parameter("col_grass_deep", Color(0.12, 0.14, 0.20))
			fm.set_shader_parameter("col_grass", Color(0.18, 0.22, 0.28))
			fm.set_shader_parameter("col_rock", Color(0.24, 0.20, 0.34))
			fm.set_shader_parameter("col_rock_lit", Color(0.38, 0.32, 0.48))
		_:
			pass


func _build_altitude_field() -> void:
	## Dense heightfield: stacked contour layers + slope shade so altitude reads clearly.
	if PathNetwork == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7711
	var cell := 95.0
	var half_x := 14
	var half_y := 12
	# Sample elev grid once
	var grid: Dictionary = {}  # "ix,iy" -> elev
	for ix in range(-half_x, half_x + 1):
		for iy in range(-half_y, half_y + 1):
			var pos := Vector2(float(ix) * cell, float(iy) * cell * 0.92)
			grid["%d,%d" % [ix, iy]] = PathNetwork.elevation_at(pos)

	# Contour-ish blobs at each cell based on height band
	for ix in range(-half_x, half_x + 1):
		for iy in range(-half_y, half_y + 1):
			var pos := Vector2(
				float(ix) * cell + rng.randf_range(-18, 18),
				float(iy) * cell * 0.92 + rng.randf_range(-14, 14)
			)
			if pos.length() < 160.0:
				continue
			if PathNetwork.dist_to_path(pos) < PATH_CLEAR * 0.55:
				continue
			var elev: float = grid.get("%d,%d" % [ix, iy], 0.0)
			var grad := PathNetwork.elevation_gradient(pos)
			var slope := grad.length()

			# Height band color (low → wet/dark, mid → grass, high → rock/lit)
			var col: Color
			var a: float
			var r := 52.0 + absf(elev) * 48.0 + slope * 40.0
			if _look == "homeland":
				# Soft rolling Gelfling hills — warm meadow bands, no purple basins
				if elev > 0.55:
					col = Color(0.42, 0.44, 0.36, 1.0)
					a = 0.12 + elev * 0.1
					r *= 1.05
				elif elev > 0.28:
					col = Color(0.38, 0.58, 0.32, 1.0)
					a = 0.14 + elev * 0.1
				elif elev > 0.05:
					col = Color(0.32, 0.52, 0.30, 1.0)
					a = 0.12 + elev * 0.08
				elif elev > -0.2:
					col = Color(0.28, 0.46, 0.28, 1.0)
					a = 0.1
				elif elev > -0.5:
					col = Color(0.24, 0.40, 0.32, 1.0)
					a = 0.1
				else:
					col = Color(0.22, 0.36, 0.34, 1.0)
					a = 0.12
			elif elev > 0.55:
				col = Color(0.36, 0.34, 0.44, 1.0)  # high violet stone
				a = 0.16 + elev * 0.14
				r *= 1.1
			elif elev > 0.28:
				col = Color(0.26, 0.42, 0.36, 1.0)  # upper river-green meadow
				a = 0.14 + elev * 0.12
			elif elev > 0.05:
				col = Color(0.20, 0.36, 0.30, 1.0)  # mid Thra moss
				a = 0.1 + elev * 0.1
			elif elev > -0.2:
				col = Color(0.16, 0.28, 0.26, 1.0)  # low glade
				a = 0.08 + absf(elev) * 0.06
			elif elev > -0.5:
				col = Color(0.14, 0.24, 0.30, 1.0)  # damp Bismark hollow
				a = 0.12 + absf(elev) * 0.1
			else:
				col = Color(0.14, 0.16, 0.28, 1.0)  # deep Astronomist basin
				a = 0.14 + absf(elev) * 0.1

			col.a = clampf(a, 0.06, 0.32)
			# Stack 1–3 soft layers so height “builds” visually
			var layers := 1
			if elev > 0.35 or elev < -0.35:
				layers = 2
			if elev > 0.7 or elev < -0.65:
				layers = 3
			for li in layers:
				var lr := r * (1.0 - float(li) * 0.18)
				var loft := -float(li) * (6.0 + maxf(0.0, elev) * 8.0)  # higher layers sit "up"
				var layer_pos := pos + Vector2(0, loft * 0.15)
				var poly := _organic_poly(layer_pos, lr, 0.62 + elev * 0.05, 11, rng, col, Z_HILL + li)
				# Slight tint shift per layer (crest brighter)
				if elev > 0.0:
					poly.color = poly.color.lightened(0.04 * float(li))
					poly.color.a = col.a * (0.85 + li * 0.08)
				else:
					poly.color = poly.color.darkened(0.03 * float(li))
				add_child(poly)

			# Slope shade: darken downhill side, lighten uphill for 3D read
			if slope > 0.004:
				var downhill := -grad.normalized()
				var shade_pos := pos + downhill * (28.0 + slope * 200.0)
				var shade_a := clampf(0.06 + slope * 8.0, 0.06, 0.2)
				var shade := _organic_poly(
					shade_pos, r * 0.7, 0.55, 9, rng,
					Color(0.05, 0.07, 0.08, shade_a), Z_HILL
				)
				add_child(shade)
				# Lit face uphill
				var uphill := grad.normalized()
				var lit_pos := pos + uphill * 18.0
				var lit := _organic_poly(
					lit_pos, r * 0.45, 0.5, 8, rng,
					Color(0.42, 0.55, 0.48, clampf(0.04 + slope * 4.0, 0.04, 0.12)), Z_HILL + 1
				)
				add_child(lit)

	# Contour rings around major landforms for readable topo
	for f in PathNetwork.features:
		var kind: String = str(f.get("kind", ""))
		if kind not in ["hill", "lake", "pond", "canopy"]:
			continue
		var c: Vector2 = f.get("pos", Vector2.ZERO)
		var rad: float = float(f.get("radius", 100.0))
		var elev_f: float = float(f.get("elev", 0.0))
		var stretch: Vector2 = f.get("stretch", Vector2(1.2, 0.9)) as Vector2
		var fang: float = float(f.get("angle", 0.0))
		var ring_n := 4 if absf(elev_f) > 0.7 else 3
		for ri in ring_n:
			var t := 0.35 + float(ri) * 0.22
			var pts := _organic_shore_pts(c, rad * t, 0.7, 16, rng, 100 + ri, stretch, fang)
			var ring_col: Color
			if elev_f > 0.0:
				ring_col = Color(0.28, 0.44, 0.38, 0.07 + elev_f * 0.04)
			else:
				ring_col = Color(0.22, 0.28, 0.42, 0.08 + absf(elev_f) * 0.05)
			_add_filled_poly(pts, ring_col, Z_HILL)


func _build_elevation_base() -> void:
	## Extra material patches keyed to altitude (sand near water, rock on high ground).
	if PathNetwork == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for ix in range(-11, 12):
		for iy in range(-9, 12):
			if (ix + iy * 3) % 4 == 0:
				continue
			var pos := Vector2(
				float(ix) * 175.0 + rng.randf_range(-40, 40),
				float(iy) * 160.0 + rng.randf_range(-30, 30)
			)
			if pos.length() < 180.0:
				continue
			if PathNetwork.dist_to_path(pos) < PATH_CLEAR * 0.8:
				continue
			var elev := PathNetwork.elevation_at(pos)
			if absf(elev) < 0.15:
				continue
			var r := 36.0 + absf(elev) * 70.0
			if elev > 0.4:
				var rock := _organic_poly(pos, r * 0.85, 0.68, 10, rng, Color(0.32, 0.30, 0.40, 0.14 + elev * 0.1), Z_HILL + 1)
				add_child(rock)
			elif elev < -0.25:
				var wet := _organic_poly(pos, r * 1.05, 0.72, 12, rng, Color(0.16, 0.26, 0.30, 0.12 + absf(elev) * 0.1), Z_HILL)
				add_child(wet)
	for f in PathNetwork.features:
		if str(f.get("kind", "")) not in ["lake", "pond"]:
			continue
		var c: Vector2 = f.get("pos", Vector2.ZERO)
		var rad: float = float(f.get("radius", 100.0))
		var sand := _organic_poly(c, rad * 1.28, 0.72, 16, rng, Color(0.42, 0.38, 0.34, 0.2), Z_HILL)
		add_child(sand)


func _build_plaza() -> void:
	if _look == "homeland":
		## Soft homeland clearing — sun-warm grass, pale stone ring (Legend opening)
		var outer := _ellipse(Vector2(0, 40), 360, 220, Color(0.32, 0.48, 0.28, 0.32), Z_PLAZA)
		add_child(outer)
		var clear := _ellipse(Vector2(0, 40), 260, 160, Color(0.40, 0.55, 0.32, 0.28), Z_PLAZA)
		add_child(clear)
		var meadow := _ellipse(Vector2(0, 40), 160, 88, Color(0.48, 0.62, 0.36, 0.28), Z_PLAZA)
		add_child(meadow)
		var pad := _ellipse(Vector2(0, 40), 95, 50, Color(0.52, 0.46, 0.34, 0.4), Z_PLAZA)
		add_child(pad)
		var warm := _ellipse(Vector2(0, 40), 72, 40, Color(0.95, 0.85, 0.5, 0.14), Z_PLAZA)
		add_child(warm)
		return
	## Later chapters: darker castle courtyard
	var outer := _ellipse(Vector2(0, 40), 360, 220, Color(0.14, 0.18, 0.20, 0.4), Z_PLAZA)
	add_child(outer)
	var clear := _ellipse(Vector2(0, 40), 260, 160, Color(0.16, 0.13, 0.22, 0.45), Z_PLAZA)
	add_child(clear)
	var stone := _ellipse(Vector2(0, 40), 160, 88, Color(0.20, 0.16, 0.28, 0.5), Z_PLAZA)
	add_child(stone)
	var warm := _ellipse(Vector2(0, 40), 90, 48, Color(0.55, 0.35, 0.72, 0.12), Z_PLAZA)
	add_child(warm)
	var fire_ring := _ellipse(Vector2(0, 48), 55, 28, Color(0.85, 0.4, 0.18, 0.08), Z_PLAZA)
	add_child(fire_ring)


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
	## Integrated land only: soft hills, water, painted canopy mass.
	## No mountain stickers, tree sprites, or crystal prop clusters.
	if PathNetwork == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 9001
	for f in PathNetwork.features:
		var pos: Vector2 = f.get("pos", Vector2.ZERO)
		var kind: String = str(f.get("kind", "hill"))
		if PathNetwork.dist_to_path(pos) < PATH_CLEAR * 0.7:
			continue
		match kind:
			"mountain":
				# Legacy data → soft highland wash
				_add_hill_wash(f, rng)
			"hill":
				_add_hill_wash(f, rng)
			"lake", "pond":
				_add_natural_water(f, rng)
			"canopy", "forest":
				_add_canopy_wash(f, rng)
			_:
				pass


func _add_hill_wash(f: Dictionary, rng: RandomNumberGenerator) -> void:
	## Continuous highland — layered moss washes only (no peak polygons, no tree stickers).
	var center: Vector2 = f.get("pos", Vector2.ZERO)
	var r: float = maxf(70.0, float(f.get("radius", 120.0)))
	var stretch: Vector2 = f.get("stretch", Vector2(1.35, 0.9)) as Vector2
	var ang: float = float(f.get("angle", 0.0))
	var seed: int = int(f.get("seed", hash(str(f.get("id", "")))))
	var elev_f := float(f.get("elev", 0.5))

	# Deep under-shade blends into ground
	var under := _organic_shore_pts(center + Vector2(0, 10), r * 1.35, 0.72, 20, rng, seed, stretch * 1.1, ang)
	_add_filled_poly(under, Color(0.1, 0.12, 0.14, 0.22 + elev_f * 0.08), Z_HILL)
	var base := _organic_shore_pts(center + Vector2(0, 4), r * 1.12, 0.7, 18, rng, seed + 1, stretch, ang)
	_add_filled_poly(base, Color(0.16, 0.28, 0.22, 0.38 + elev_f * 0.1), Z_HILL)
	var mid := _organic_shore_pts(center, r * 0.88, 0.68, 16, rng, seed + 2, stretch, ang)
	_add_filled_poly(mid, Color(0.22, 0.38, 0.28, 0.36), Z_HILL + 1)
	var high := _organic_shore_pts(center + Vector2(0, -r * 0.08), r * 0.58, 0.64, 14, rng, seed + 3, stretch * 0.92, ang)
	_add_filled_poly(high, Color(0.32, 0.48, 0.34, 0.32), Z_HILL + 2)
	# Warm light on crown (cover-art sun)
	var lit := _organic_shore_pts(center + Vector2(-r * 0.08, -r * 0.12), r * 0.38, 0.6, 12, rng, seed + 4, stretch * 0.85, ang)
	_add_filled_poly(lit, Color(0.55, 0.58, 0.42, 0.14 + elev_f * 0.08), Z_HILL + 3)
	# Cool violet lee shade
	var shade := _organic_shore_pts(center + Vector2(r * 0.1, r * 0.18), r * 0.7, 0.5, 12, rng, seed + 5, stretch, ang)
	_add_filled_poly(shade, Color(0.14, 0.12, 0.2, 0.16), Z_HILL + 1)


func _add_canopy_wash(f: Dictionary, rng: RandomNumberGenerator) -> void:
	## Soft painted woodland mass — merges with floor, never sticker trees.
	var center: Vector2 = f.get("pos", Vector2.ZERO)
	var r: float = maxf(80.0, float(f.get("radius", 140.0)))
	var seed: int = int(f.get("seed", hash(str(f.get("id", "")))))
	var stretch := Vector2(1.25, 0.95)
	var base := _organic_shore_pts(center, r * 1.2, 0.75, 18, rng, seed, stretch, 0.1)
	_add_filled_poly(base, Color(0.12, 0.22, 0.18, 0.28), Z_HILL)
	var mid := _organic_shore_pts(center + Vector2(0, -6), r * 0.95, 0.7, 16, rng, seed + 2, stretch, -0.05)
	_add_filled_poly(mid, Color(0.18, 0.34, 0.26, 0.32), Z_HILL + 1)
	# Several soft crown lobes for depth
	for i in 4:
		var o := Vector2(rng.randf_range(-r * 0.35, r * 0.35), rng.randf_range(-r * 0.25, r * 0.15))
		var lobe := _organic_shore_pts(center + o, r * rng.randf_range(0.28, 0.45), 0.72, 12, rng, seed + 10 + i, Vector2(1.1, 0.9), rng.randf() * 0.4)
		var a := 0.18 + float(i) * 0.03
		_add_filled_poly(lobe, Color(0.22 + float(i) * 0.03, 0.4, 0.28 + float(i) * 0.02, a), Z_HILL + 2)
	# Ethereal violet under-canopy light
	var mist := _ellipse(center + Vector2(0, 8), r * 0.7, r * 0.4, Color(0.4, 0.32, 0.55, 0.06), Z_HILL + 3)
	add_child(mist)


func _add_natural_water(f: Dictionary, rng: RandomNumberGenerator) -> void:
	## Organic multi-lobe lake/pond — irregular shore, marsh, sand, deeps (not a circle).
	var center: Vector2 = f.get("pos", Vector2.ZERO)
	var r: float = maxf(50.0, float(f.get("radius", 120.0)))
	var is_pond: bool = str(f.get("kind", "lake")) == "pond"
	var seed: int = int(f.get("seed", 0))
	var lobes: Array = f.get("lobes", [])
	var stretch := Vector2(1.2, 0.7)
	if not lobes.is_empty():
		var max_rx := 0.9
		var max_ry := 0.55
		for lobe in lobes:
			max_rx = maxf(max_rx, float(lobe.get("rx", 1.0)))
			max_ry = maxf(max_ry, float(lobe.get("ry", 0.55)))
		stretch = Vector2(max_rx * 1.35, max_ry * 1.5)

	# Marsh / wetland fringe
	var marsh := _organic_shore_pts(center, r * 1.35, 0.75, 22, rng, seed, stretch, 0.0)
	_add_filled_poly(marsh, Color(0.14, 0.3, 0.16, 0.45), Z_WATER)
	# Mud / sand bank
	var bank := _organic_shore_pts(center, r * 1.18, 0.72, 20, rng, seed + 1, stretch, 0.12)
	_add_filled_poly(bank, Color(0.36, 0.32, 0.22, 0.42), Z_WATER + 1)
	var wet := _organic_shore_pts(center, r * 1.08, 0.7, 18, rng, seed + 2, stretch, -0.08)
	_add_filled_poly(wet, Color(0.12, 0.2, 0.18, 0.5), Z_WATER + 2)

	# Main water surface (organic)
	var water_col := Color(0.32, 0.52, 0.62, 0.78) if is_pond else Color(0.28, 0.45, 0.58, 0.8)
	var water := _organic_shore_pts(center, r * 0.98, 0.68, 20, rng, seed + 3, stretch, 0.05)
	_add_filled_poly(water, water_col, Z_WATER + 3)

	# Depth from multi-lobe centers
	if lobes.is_empty():
		lobes = [{"o": Vector2.ZERO, "rx": 0.7, "ry": 0.5}]
	for i in lobes.size():
		var lobe: Dictionary = lobes[i]
		var o: Vector2 = lobe.get("o", Vector2.ZERO)
		var lrx: float = float(lobe.get("rx", 0.7)) * r
		var lry: float = float(lobe.get("ry", 0.5)) * r
		var deep := _organic_shore_pts(center + o, maxf(lrx, lry) * 0.7, lry / maxf(0.2, lrx), 12, rng, seed + 10 + i, Vector2(1.0, 1.0), rng.randf() * 0.5)
		_add_filled_poly(deep, Color(0.16, 0.28, 0.48, 0.55), Z_WATER + 4)

	# Shallow bay highlight
	var bay_o := Vector2(r * 0.2, -r * 0.08)
	var shallow := _organic_shore_pts(center + bay_o, r * 0.38, 0.65, 10, rng, seed + 20, Vector2(1.3, 0.7), 0.3)
	_add_filled_poly(shallow, Color(0.40, 0.62, 0.68, 0.28), Z_WATER + 4)

	# Specular flecks inside water (few)
	for i in (3 if is_pond else 6):
		var gp := _sample_inside_organic(center, r * 0.7, stretch, rng)
		var g := _ellipse(gp, rng.randf_range(5, 14), rng.randf_range(2, 6), Color(0.6, 0.9, 1.0, 0.16), Z_WATER + 5)
		add_child(g)

	# Soft mist over larger lakes only
	if not is_pond:
		var mist := _organic_shore_pts(center + Vector2(0, -8), r * 0.7, 0.6, 12, rng, seed + 30, stretch * 0.9, 0.0)
		_add_filled_poly(mist, Color(0.4, 0.38, 0.55, 0.1), Z_WATER + 6)

	# Soft painted reed bank wash only — no sticker reed clusters / lily props
	var bank_wash := _organic_shore_pts(center, r * 1.08, 0.72, 14, rng, seed + 4, stretch, 0.0)
	_add_filled_poly(bank_wash, Color(0.2, 0.38, 0.26, 0.14), Z_WATER + 5)


func _organic_shore_pts(
	center: Vector2,
	radius: float,
	aspect: float,
	n: int,
	rng: RandomNumberGenerator,
	seed: int,
	stretch: Vector2 = Vector2.ONE,
	angle: float = 0.0
) -> PackedVector2Array:
	## Irregular shoreline — bays, peninsulas, no perfect circle.
	var pts := PackedVector2Array()
	var ca := cos(angle)
	var sa := sin(angle)
	var sx := maxf(0.45, stretch.x)
	var sy := maxf(0.45, stretch.y)
	for i in n:
		var a := TAU * float(i) / float(n)
		# Multi-frequency warping for natural coast
		var warp := 1.0
		warp += 0.22 * sin(a * 2.0 + float(seed) * 0.17)
		warp += 0.16 * cos(a * 3.0 - float(seed) * 0.11)
		warp += 0.12 * sin(a * 5.0 + float(seed) * 0.07)
		warp += 0.08 * cos(a * 7.0 + float(seed) * 0.03)
		# Occasional inlet / bay
		if sin(a * 3.0 + float(seed)) > 0.72:
			warp *= 0.72
		# Occasional peninsula
		if cos(a * 2.0 - float(seed) * 0.2) > 0.78:
			warp *= 1.22
		warp *= 0.92 + 0.12 * rng.randf()
		var rr := radius * clampf(warp, 0.55, 1.45)
		var lx := cos(a) * rr * sx
		var ly := sin(a) * rr * aspect * sy
		pts.append(center + Vector2(lx * ca - ly * sa, lx * sa + ly * ca))
	return pts


func _organic_poly(
	center: Vector2,
	radius: float,
	aspect: float,
	n: int,
	rng: RandomNumberGenerator,
	col: Color,
	z: int
) -> Polygon2D:
	var pts := _organic_shore_pts(center, radius, aspect, n, rng, rng.randi(), Vector2.ONE, rng.randf() * 0.4)
	return _make_poly(pts, col, z)


func _add_filled_poly(pts: PackedVector2Array, col: Color, z: int) -> void:
	if pts.size() < 3:
		return
	add_child(_make_poly(pts, col, z))


func _make_poly(pts: PackedVector2Array, col: Color, z: int) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = col
	p.z_index = z
	return p


func _sample_inside_organic(center: Vector2, radius: float, stretch: Vector2, rng: RandomNumberGenerator) -> Vector2:
	var a := rng.randf() * TAU
	var t := sqrt(rng.randf()) * 0.75
	return center + Vector2(cos(a) * radius * stretch.x, sin(a) * radius * stretch.y * 0.7) * t


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
		var tint := Color(0.55, 0.78, 0.82, 0.9) if i % 2 == 0 else Color(0.68, 0.52, 0.88, 0.88)
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


func _build_atmosphere_light() -> void:
	## Sparse dust motes only — cover-art air, not confetti stickers.
	if FX == null:
		return
	var dust := FX.spark_particles(self, Color(0.92, 0.85, 0.7, 0.22), 10, "glow")
	dust.position = Vector2(0, 40)
	dust.z_index = Z_DECOR
	dust.amount = 10
	dust.lifetime = 6.0
	var pm := dust.process_material as ParticleProcessMaterial
	if pm:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 380.0
		pm.initial_velocity_min = 0.5
		pm.initial_velocity_max = 3.0
		pm.gravity = Vector3(0, -0.8, 0)


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
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.centered = true
	s.position = pos
	s.scale = Vector2(scale_mul, scale_mul)
	s.modulate = Color(_forest_mod.r, _forest_mod.g, _forest_mod.b, alpha)
	# Local z only under Ground (-200) — never compete with actors (5000+)
	s.z_index = Z_DECOR + clampi(int(pos.y / 80.0), -5, 25)
	s.offset = Vector2(0, -float(tex.get_height()) * 0.4)
	add_child(s)
	return s


## Forest trail — cool grey-taupe dirt, soft grass edges (not chocolate sausage).
func _add_path_ribbon(pts: PackedVector2Array, half_width: float) -> void:
	if pts.size() < 2:
		return
	# Bust cache if we reloaded colors in-session (editor hot-reload)
	_dirt_tex = null
	_dirt_edge_tex = null
	_ensure_dirt_textures()

	# Soft verge — homeland uses bright meadow edge
	var moss := Line2D.new()
	moss.width = half_width * 2.15
	if _look == "homeland":
		moss.default_color = Color(0.28, 0.48, 0.26, 0.48)
	else:
		moss.default_color = Color(0.14, 0.26, 0.22, 0.44)
	moss.begin_cap_mode = Line2D.LINE_CAP_ROUND
	moss.end_cap_mode = Line2D.LINE_CAP_ROUND
	moss.joint_mode = Line2D.LINE_JOINT_ROUND
	moss.antialiased = true
	moss.points = pts
	moss.z_index = Z_PATH_EDGE - 1
	add_child(moss)

	# Cool packed earth (narrower trail feel)
	var dirt := Line2D.new()
	dirt.width = half_width * 1.55
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
	## Path colors by look. Homeland: pale warm sand-path (Gelfling trail).
	var w := 24
	var h := 96
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var homeland := _look == "homeland"
	for y in h:
		var v := float(y) / float(h - 1)
		var edge := absf(v - 0.5) * 2.0  # 0 center → 1 edge
		var t := edge * edge * (3.0 - 2.0 * edge)  # smoothstep

		var col: Color
		if for_edge:
			var mid := Color(0.36, 0.50, 0.30, 0.5) if homeland else Color(0.26, 0.32, 0.30, 0.55)
			var out := Color(0.28, 0.42, 0.26, 0.0) if homeland else Color(0.16, 0.24, 0.22, 0.0)
			col = mid.lerp(out, t)
		elif homeland:
			var crown := Color(0.62, 0.56, 0.42, 1.0)  # pale sun-dust
			var body := Color(0.50, 0.46, 0.34, 1.0)
			var rim := Color(0.40, 0.44, 0.30, 1.0)
			col = crown.lerp(body, t * 0.65).lerp(rim, t * 0.85)
			col.a = clampf(1.0 - pow(edge, 2.6) * 0.28, 0.82, 1.0)
		else:
			var crown := Color(0.50, 0.46, 0.48, 1.0)
			var body := Color(0.38, 0.36, 0.40, 1.0)
			var rim := Color(0.28, 0.32, 0.30, 1.0)
			col = crown.lerp(body, t * 0.65).lerp(rim, t * 0.85)
			col.a = clampf(1.0 - pow(edge, 2.6) * 0.28, 0.82, 1.0)

		for x in w:
			# Fine grit — slightly more variance for soil read
			var n := fposmod(sin(float(x) * 12.9898 + float(y) * 78.233) * 43758.5453, 1.0)
			var n2 := fposmod(sin(float(x) * 47.1 + float(y) * 19.3) * 23421.1, 1.0)
			var grain := (n - 0.5) * 0.055 + (n2 - 0.5) * 0.025
			# Tiny cooler pebble flecks
			var pebble := 1.0 if n > 0.93 else 0.0
			var c := Color(
				clampf(col.r + grain - pebble * 0.04, 0.0, 1.0),
				clampf(col.g + grain * 0.9 - pebble * 0.02, 0.0, 1.0),
				clampf(col.b + grain * 0.85 + pebble * 0.02, 0.0, 1.0),
				col.a
			)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


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
