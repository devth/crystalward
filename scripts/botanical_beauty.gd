extends Node2D
## Legend (1985)–inspired botanical beauty: meadows, glowing blossoms,
## fairy rings, ferns, vines, pollen — romantic forest magic.


# Spec: Legend soft-dark botanical beauty — not candy confetti
const LEGEND_GREEN := Color(0.28, 0.48, 0.38)
const LEGEND_MOSS := Color(0.22, 0.4, 0.32)
const LEGEND_BLOOM_PINK := Color(0.75, 0.4, 0.65)   # dusk rose
const LEGEND_BLOOM_LILAC := Color(0.65, 0.5, 0.9)    # violet
const LEGEND_BLOOM_GOLD := Color(0.92, 0.75, 0.35)   # amber crystal light
const LEGEND_BLOOM_WHITE := Color(0.75, 0.92, 0.95)  # cyan frost
const LEGEND_FERN := Color(0.22, 0.42, 0.34)


func paint(parent: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1985  # year of Legend

	# Lightwell meadow — ethereal blooms in the amber/cyan glow
	_meadow_ring(parent, Vector2(0, 40), 100.0, 260.0, 28, rng)
	if PathNetwork:
		for lane in PathNetwork.lanes:
			var pts: PackedVector2Array = lane
			for i in range(0, pts.size() - 1, 2):
				_path_edge_flowers(parent, pts[i], pts[i + 1], rng)
	# A few fairy rings — soft dark magic, not everywhere
	var rings: Array[Vector2] = [
		Vector2(-280, 200), Vector2(300, -80), Vector2(-100, 480),
	]
	for c in rings:
		if PathNetwork and PathNetwork.dist_to_path(c) < 90.0:
			continue
		_fairy_ring(parent, c, rng.randf_range(32.0, 48.0), rng)
	for i in 6:
		var ang := rng.randf() * TAU
		var r := rng.randf_range(350.0, 900.0)
		var pos := Vector2(cos(ang), sin(ang) * 0.82) * r
		if PathNetwork and PathNetwork.dist_to_path(pos) < 100.0:
			continue
		_botanical_cluster(parent, pos, rng)
	_scatter_glow_blossoms(parent, rng)
	_pollen_clouds(parent)
	# Skip RGB plant sheet (reads as solid rectangles)


func _meadow_ring(parent: Node2D, center: Vector2, r0: float, r1: float, count: int, rng: RandomNumberGenerator) -> void:
	for i in count:
		var ang := TAU * float(i) / float(count) + rng.randf() * 0.4
		var r := rng.randf_range(r0, r1)
		var pos := center + Vector2(cos(ang), sin(ang) * 0.75) * r
		match rng.randi() % 5:
			0, 1:
				_flower(parent, pos, LEGEND_BLOOM_PINK if rng.randf() < 0.5 else LEGEND_BLOOM_LILAC, rng.randf_range(0.7, 1.3))
			2:
				_flower(parent, pos, LEGEND_BLOOM_GOLD, rng.randf_range(0.6, 1.1))
			3:
				_flower(parent, pos, LEGEND_BLOOM_WHITE, rng.randf_range(0.8, 1.2))
			_:
				_fern(parent, pos, rng.randf_range(0.8, 1.4), rng.randf_range(-0.4, 0.4))


func _path_edge_flowers(parent: Node2D, a: Vector2, b: Vector2, rng: RandomNumberGenerator) -> void:
	var dir := b - a
	var len := dir.length()
	if len < 40.0:
		return
	var n := Vector2(-dir.y, dir.x).normalized()
	var steps := int(len / 90.0)
	for s in steps:
		var t := (float(s) + 0.5) / float(maxi(1, steps))
		var base: Vector2 = a.lerp(b, t)
		for side_f in [-1.0, 1.0]:
			if rng.randf() < 0.55:
				continue
			var side: float = float(side_f)
			var pos: Vector2 = base + n * side * rng.randf_range(48.0, 88.0)
			# Keep flowers on the verge, not on the dirt
			if PathNetwork and PathNetwork.dist_to_path(pos) < 36.0:
				continue
			if rng.randf() < 0.45:
				_flower(parent, pos, _rand_bloom(rng), rng.randf_range(0.65, 1.1))
			else:
				_grass_tuft(parent, pos, rng)


func _fairy_ring(parent: Node2D, center: Vector2, radius: float, rng: RandomNumberGenerator) -> void:
	var n := 10 + rng.randi() % 6
	for i in n:
		var ang := TAU * float(i) / float(n)
		var pos := center + Vector2(cos(ang), sin(ang) * 0.7) * radius
		if rng.randf() < 0.55:
			_mushroom(parent, pos, rng)
		else:
			_flower(parent, pos, LEGEND_BLOOM_WHITE if rng.randf() < 0.4 else LEGEND_BLOOM_LILAC, rng.randf_range(0.7, 1.1))
	# Soft ethereal glow in center
	var glow := FX.make_ellipse_poly(radius * 0.7, radius * 0.45, 28, Color(0.85, 0.7, 1.0, 0.08))
	glow.position = center
	glow.z_index = -30
	parent.add_child(glow)
	if FX:
		var p := FX.spark_particles(parent, Color(0.95, 0.85, 1.0, 0.55), 8, "star")
		p.position = center


func _botanical_cluster(parent: Node2D, center: Vector2, rng: RandomNumberGenerator) -> void:
	# Dense Legend undergrowth pocket
	for i in 8:
		var o := Vector2(rng.randf_range(-50, 50), rng.randf_range(-40, 40))
		var pos := center + o
		match rng.randi() % 6:
			0, 1:
				_fern(parent, pos, rng.randf_range(0.9, 1.6), rng.randf_range(-0.5, 0.5))
			2, 3:
				_flower(parent, pos, _rand_bloom(rng), rng.randf_range(0.7, 1.4))
			4:
				_grass_tuft(parent, pos, rng)
			_:
				_leaf_bush(parent, pos, rng)


func _scatter_glow_blossoms(parent: Node2D, rng: RandomNumberGenerator) -> void:
	# Sparse night-blooming flowers that glow like crystal dust
	for i in 14:
		var ang := rng.randf() * TAU
		var r := rng.randf_range(220.0, 900.0)
		var pos := Vector2(cos(ang), sin(ang) * 0.8) * r
		if PathNetwork and PathNetwork.dist_to_path(pos) < 80.0:
			continue
		_glow_blossom(parent, pos, rng)


func _pollen_clouds(parent: Node2D) -> void:
	# Amber + violet pollen — ethereal air of the Lightwell glade
	if FX == null:
		return
	var amber := FX.spark_particles(parent, Color(0.95, 0.8, 0.4, 0.35), 12, "star")
	amber.position = Vector2(0, 40)
	var pm := amber.process_material as ParticleProcessMaterial
	if pm:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 280.0
		pm.gravity = Vector3(0, -3, 0)
		pm.initial_velocity_min = 1.5
		pm.initial_velocity_max = 6.0
	amber.lifetime = 4.0
	amber.z_index = -5
	var violet := FX.spark_particles(parent, Color(0.7, 0.5, 0.95, 0.28), 10, "glow")
	violet.position = Vector2(40, 20)
	violet.z_index = -5


func _scatter_plant_sheet(_parent: Node2D, _rng: RandomNumberGenerator) -> void:
	# Disabled: plants.png is RGB (no alpha) and reads as solid colored rectangles in-world.
	return


func _attach_sway(node: Node2D, phase: float) -> void:
	node.set_meta("sway_phase", phase)
	# Driven by botanical_sway.gd on parent if present; else simple process on a helper
	var sway := Node.new()
	sway.set_script(load("res://scripts/botanical_sway.gd"))
	node.add_child(sway)


func _rand_bloom(rng: RandomNumberGenerator) -> Color:
	match rng.randi() % 4:
		0:
			return LEGEND_BLOOM_PINK
		1:
			return LEGEND_BLOOM_LILAC
		2:
			return LEGEND_BLOOM_GOLD
		_:
			return LEGEND_BLOOM_WHITE


func _rand_away_from_crystal(rng: RandomNumberGenerator, min_r: float, max_r: float) -> Vector2:
	var ang := rng.randf() * TAU
	var r := rng.randf_range(min_r, max_r)
	return Vector2(cos(ang), sin(ang) * 0.82) * r


func _flower(parent: Node2D, pos: Vector2, color: Color, sc: float) -> void:
	# pos is local to `parent` (world pos when parent is ground; local when nested).
	_flower_into(parent, pos, color, sc)


func _flower_into(parent: Node2D, local_pos: Vector2, color: Color, sc: float) -> void:
	var root := Node2D.new()
	root.position = local_pos
	root.scale = Vector2(sc, sc)
	# Only use world-ish Y sort when placed on the ground (non-zero local offset
	# from a root already Y-sorted is fine as a local draw order hint).
	if absf(local_pos.y) > 0.01 or absf(local_pos.x) > 0.01:
		root.z_index = int(local_pos.y)
	parent.add_child(root)
	# Stem
	var stem := Line2D.new()
	stem.width = 2.0
	stem.default_color = LEGEND_GREEN
	stem.points = PackedVector2Array([Vector2(0, 6), Vector2(0, -6)])
	root.add_child(stem)
	# Petals
	for i in 5:
		var ang := TAU * float(i) / 5.0 - PI * 0.5
		var petal := Polygon2D.new()
		var tip := Vector2(cos(ang), sin(ang)) * 8.0
		var side := Vector2(-sin(ang), cos(ang)) * 3.5
		petal.polygon = PackedVector2Array([
			Vector2.ZERO, tip + side * 0.3, tip, tip - side * 0.3
		])
		petal.color = color
		petal.position = Vector2(0, -8)
		root.add_child(petal)
	# Center
	var core := FX.make_ellipse_poly(2.5, 2.2, 10, LEGEND_BLOOM_GOLD)
	core.position = Vector2(0, -8)
	root.add_child(core)
	_attach_sway(root, randf() * TAU)


func _glow_blossom(parent: Node2D, pos: Vector2, rng: RandomNumberGenerator) -> void:
	# One root at world pos; flower is parented at local origin (no double-offset).
	var root := Node2D.new()
	root.position = pos
	root.z_index = int(pos.y)
	parent.add_child(root)
	var color := _rand_bloom(rng)
	var sc := rng.randf_range(0.9, 1.4)
	var glow := FX.make_ellipse_poly(14 * sc, 12 * sc, 16, Color(color.r, color.g, color.b, 0.2))
	glow.position = Vector2(0, -10 * sc)
	root.add_child(glow)
	# Build flower in-place under root (local 0) — do not pass world `pos` again.
	_flower_into(root, Vector2.ZERO, color, sc)
	if FX and rng.randf() < 0.4:
		var p := FX.spark_particles(root, Color(color.r, color.g, color.b, 0.6), 5, "glow")
		p.position = Vector2(0, -10 * sc)


func _fern(parent: Node2D, pos: Vector2, sc: float, rot: float) -> void:
	var root := Node2D.new()
	root.position = pos
	root.scale = Vector2(sc, sc)
	root.rotation = rot
	root.z_index = int(pos.y)
	parent.add_child(root)
	for i in 5:
		var frond := Line2D.new()
		frond.width = 2.0
		frond.default_color = LEGEND_FERN.lightened(float(i) * 0.05)
		var lean := (float(i) - 2.0) * 0.25
		frond.points = PackedVector2Array([
			Vector2(0, 4),
			Vector2(lean * 8.0, -6 - i * 3.0),
			Vector2(lean * 14.0, -14 - i * 4.0),
		])
		root.add_child(frond)
		# Side leaflets
		for j in 3:
			var t := 0.3 + float(j) * 0.25
			var p: Vector2 = Vector2(lean * 8.0, -6 - i * 3.0).lerp(Vector2(lean * 14.0, -14 - i * 4.0), t)
			var leaf := Polygon2D.new()
			leaf.polygon = PackedVector2Array([
				p, p + Vector2(5, -2), p + Vector2(1, 3)
			])
			leaf.color = LEGEND_FERN.lightened(0.1)
			root.add_child(leaf)
	_attach_sway(root, randf() * TAU)


func _grass_tuft(parent: Node2D, pos: Vector2, rng: RandomNumberGenerator) -> void:
	var root := Node2D.new()
	root.position = pos
	root.z_index = int(pos.y)
	parent.add_child(root)
	for i in 4:
		var blade := Line2D.new()
		blade.width = 1.5
		blade.default_color = LEGEND_MOSS.lightened(rng.randf() * 0.15)
		var x := rng.randf_range(-5, 5)
		blade.points = PackedVector2Array([
			Vector2(x, 4), Vector2(x + rng.randf_range(-3, 3), -rng.randf_range(8, 16))
		])
		root.add_child(blade)
	_attach_sway(root, rng.randf() * TAU)


func _leaf_bush(parent: Node2D, pos: Vector2, rng: RandomNumberGenerator) -> void:
	var root := Node2D.new()
	root.position = pos
	root.z_index = int(pos.y)
	parent.add_child(root)
	for i in 4:
		var blob := FX.make_ellipse_poly(
			rng.randf_range(8, 14),
			rng.randf_range(6, 11),
			14,
			LEGEND_GREEN.lightened(rng.randf() * 0.2)
		)
		blob.position = Vector2(rng.randf_range(-8, 8), rng.randf_range(-12, 0))
		root.add_child(blob)
	# Occasional flower on bush
	if rng.randf() < 0.45:
		_flower(root, Vector2(rng.randf_range(-4, 4), -10), _rand_bloom(rng), 0.7)
	_attach_sway(root, rng.randf() * TAU)


func _mushroom(parent: Node2D, pos: Vector2, rng: RandomNumberGenerator) -> void:
	var root := Node2D.new()
	root.position = pos
	root.z_index = int(pos.y)
	parent.add_child(root)
	var stem := FX.make_ellipse_poly(3, 5, 10, Color(0.9, 0.88, 0.8))
	stem.position = Vector2(0, 0)
	root.add_child(stem)
	var cap_col := Color(0.85, 0.45, 0.55) if rng.randf() < 0.5 else Color(0.7, 0.55, 0.9)
	var cap := FX.make_ellipse_poly(8, 5, 14, cap_col)
	cap.position = Vector2(0, -6)
	root.add_child(cap)
	# Soft glow for fairy-ring magic
	var g := FX.make_ellipse_poly(10, 6, 12, Color(cap_col.r, cap_col.g, cap_col.b, 0.15))
	g.position = Vector2(0, -6)
	g.z_index = -1
	root.add_child(g)
