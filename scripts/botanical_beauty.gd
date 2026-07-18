extends Node2D
## Sparse meadow accents — a few blooms and ferns, not prop confetti.
## Lushness lives in the ground shader materials.


# Thra blooms — river green, dust rose, amethyst, soft crystal white
const LEGEND_GREEN := Color(0.34, 0.50, 0.44)
const LEGEND_MOSS := Color(0.28, 0.42, 0.38)
const LEGEND_BLOOM_PINK := Color(0.80, 0.52, 0.62)
const LEGEND_BLOOM_LILAC := Color(0.62, 0.48, 0.82)
const LEGEND_BLOOM_GOLD := Color(0.88, 0.76, 0.48)
const LEGEND_BLOOM_WHITE := Color(0.86, 0.88, 0.96)
const LEGEND_FERN := Color(0.30, 0.46, 0.40)


func paint(parent: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1985
	var homeland := Campaign != null and Campaign.current_look() == "homeland"
	# Homeland: denser soft meadow (Gelfling / Legend opening forest)
	var ring_n := 22 if homeland else 12
	var edge_step := 90.0 if homeland else 140.0
	var cluster_n := 16 if homeland else 8

	# Light meadow ring far enough from crystal not to obscure it
	_meadow_ring(parent, Vector2(0, 40), 180.0, 260.0, ring_n, rng)
	if homeland:
		_meadow_ring(parent, Vector2(0, 40), 280.0, 420.0, 18, rng)

	# Sparse path-edge grass only
	if PathNetwork:
		for lane in PathNetwork.lanes:
			var pts: PackedVector2Array = lane
			var walked := 0.0
			var next_mark := edge_step
			for i in range(pts.size() - 1):
				walked += pts[i].distance_to(pts[i + 1])
				if walked < next_mark:
					continue
				next_mark += edge_step
				_path_edge_flowers(parent, pts[i], pts[i + 1], rng)

	# Fairy rings, far from well
	var rings: Array = [Vector2(320, 480), Vector2(-360, 700)]
	if homeland:
		rings.append(Vector2(420, 180))
		rings.append(Vector2(-180, 380))
		rings.append(Vector2(100, 720))
	for c in rings:
		if PathNetwork and PathNetwork.dist_to_path(c) < 130.0:
			continue
		if c.length() < 280.0:
			continue
		_fairy_ring(parent, c, rng.randf_range(28.0, 40.0), rng)

	# Botanical clusters
	for i in cluster_n:
		var ang := rng.randf() * TAU
		var r := rng.randf_range(400.0, 1600.0)
		var pos := Vector2(cos(ang), sin(ang) * 0.88) * r
		if pos.length() < 320.0:
			continue
		if PathNetwork and PathNetwork.dist_to_path(pos) < 130.0:
			continue
		_botanical_cluster(parent, pos, rng)


func _meadow_ring(parent: Node2D, center: Vector2, r0: float, r1: float, count: int, rng: RandomNumberGenerator) -> void:
	for i in count:
		var ang := TAU * float(i) / float(count) + rng.randf() * 0.4
		var r := rng.randf_range(r0, r1)
		var pos := center + Vector2(cos(ang), sin(ang) * 0.75) * r
		if PathNetwork and PathNetwork.dist_to_path(pos) < 80.0:
			continue
		match rng.randi() % 4:
			0:
				_flower(parent, pos, LEGEND_BLOOM_PINK if rng.randf() < 0.5 else LEGEND_BLOOM_LILAC, rng.randf_range(0.7, 1.1))
			1:
				_flower(parent, pos, LEGEND_BLOOM_GOLD, rng.randf_range(0.6, 1.0))
			_:
				_grass_tuft(parent, pos, rng)


func _path_edge_flowers(parent: Node2D, a: Vector2, b: Vector2, rng: RandomNumberGenerator) -> void:
	var dir := b - a
	var len := dir.length()
	if len < 40.0:
		return
	var n := Vector2(-dir.y, dir.x).normalized()
	for side_f in [-1.0, 1.0]:
		if rng.randf() < 0.45:
			continue
		var pos: Vector2 = a.lerp(b, 0.5) + n * float(side_f) * rng.randf_range(80.0, 110.0)
		if PathNetwork and PathNetwork.dist_to_path(pos) < 72.0:
			continue
		if rng.randf() < 0.35:
			_flower(parent, pos, _rand_bloom(rng), rng.randf_range(0.6, 1.0))
		else:
			_grass_tuft(parent, pos, rng)


func _fairy_ring(parent: Node2D, center: Vector2, radius: float, rng: RandomNumberGenerator) -> void:
	var n := 8
	for i in n:
		var ang := TAU * float(i) / float(n)
		var pos := center + Vector2(cos(ang), sin(ang) * 0.7) * radius
		if rng.randf() < 0.5:
			_mushroom(parent, pos, rng)
		else:
			_flower(parent, pos, LEGEND_BLOOM_LILAC, rng.randf_range(0.65, 0.95))


func _botanical_cluster(parent: Node2D, center: Vector2, rng: RandomNumberGenerator) -> void:
	for i in 5:
		var o := Vector2(rng.randf_range(-40, 40), rng.randf_range(-32, 32))
		var pos := center + o
		if PathNetwork and PathNetwork.dist_to_path(pos) < 100.0:
			continue
		match rng.randi() % 5:
			0, 1:
				_fern(parent, pos, rng.randf_range(0.8, 1.3), rng.randf_range(-0.4, 0.4))
			2:
				_flower(parent, pos, _rand_bloom(rng), rng.randf_range(0.65, 1.1))
			_:
				_grass_tuft(parent, pos, rng)


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


func _flower(parent: Node2D, pos: Vector2, color: Color, sc: float) -> void:
	_flower_into(parent, pos, color, sc)


func _flower_into(parent: Node2D, local_pos: Vector2, color: Color, sc: float) -> void:
	var root := Node2D.new()
	root.position = local_pos
	root.scale = Vector2(sc, sc)
	if absf(local_pos.y) > 0.01 or absf(local_pos.x) > 0.01:
		root.z_index = int(local_pos.y)
	parent.add_child(root)
	var stem := Line2D.new()
	stem.width = 2.0
	stem.default_color = LEGEND_GREEN
	stem.points = PackedVector2Array([Vector2(0, 6), Vector2(0, -6)])
	root.add_child(stem)
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
	if FX:
		var core := FX.make_ellipse_poly(2.5, 2.2, 10, LEGEND_BLOOM_GOLD)
		core.position = Vector2(0, -8)
		root.add_child(core)


func _fern(parent: Node2D, pos: Vector2, sc: float, rot: float) -> void:
	var root := Node2D.new()
	root.position = pos
	root.scale = Vector2(sc, sc)
	root.rotation = rot
	root.z_index = int(pos.y)
	parent.add_child(root)
	for i in 4:
		var frond := Line2D.new()
		frond.width = 2.0
		frond.default_color = LEGEND_FERN.lightened(float(i) * 0.05)
		var lean := (float(i) - 1.5) * 0.25
		frond.points = PackedVector2Array([
			Vector2(0, 4),
			Vector2(lean * 8.0, -6 - i * 3.0),
			Vector2(lean * 12.0, -12 - i * 3.5),
		])
		root.add_child(frond)


func _grass_tuft(parent: Node2D, pos: Vector2, rng: RandomNumberGenerator) -> void:
	var root := Node2D.new()
	root.position = pos
	root.z_index = int(pos.y)
	parent.add_child(root)
	for i in 3:
		var blade := Line2D.new()
		blade.width = 1.5
		blade.default_color = LEGEND_MOSS.lightened(rng.randf() * 0.12)
		var x := rng.randf_range(-4, 4)
		blade.points = PackedVector2Array([
			Vector2(x, 4), Vector2(x + rng.randf_range(-2, 2), -rng.randf_range(7, 14))
		])
		root.add_child(blade)


func _mushroom(parent: Node2D, pos: Vector2, rng: RandomNumberGenerator) -> void:
	var root := Node2D.new()
	root.position = pos
	root.z_index = int(pos.y)
	parent.add_child(root)
	if FX:
		var stem := FX.make_ellipse_poly(3, 5, 10, Color(0.88, 0.86, 0.8))
		root.add_child(stem)
		var cap_col := Color(0.8, 0.5, 0.6) if rng.randf() < 0.5 else Color(0.65, 0.55, 0.85)
		var cap := FX.make_ellipse_poly(7, 4.5, 12, cap_col)
		cap.position = Vector2(0, -5)
		root.add_child(cap)
