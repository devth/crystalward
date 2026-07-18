extends Node2D
## Lightwell / Crystal — Dark Crystal–inspired pure gem: clear lavender body,
## amethyst energy, river-green + rose facets, floating above a stone well.

@onready var _hp_bar: ProgressBar = $HpBar

var _float_root: Node2D
var _core: Polygon2D
var _facets: Array[Polygon2D] = []
var _heart: Polygon2D
var _shadow: Polygon2D
var _rim_glow: Polygon2D
var _health_t: float = 1.0
var _float_y: float = 0.0
var _shimmer_t: float = 0.0


func _ready() -> void:
	add_to_group("crystal")
	if has_node("Glow"):
		$Glow.queue_free()
	if has_node("Core"):
		$Core.queue_free()

	_build_visuals()
	GameState.crystal_hp_changed.connect(_on_hp)
	_on_hp(GameState.crystal_hp, GameState.crystal_max_hp)
	z_as_relative = false
	if VisualStyle:
		z_index = VisualStyle.actor_z(global_position.y) + 20
	else:
		z_index = clampi(70 + int(global_position.y) + 2000, 50, 4000)
	FX.style_progress_bar(_hp_bar, Color(0.68, 0.52, 0.88), Color(0.08, 0.06, 0.12, 0.9))
	_hp_bar.position = Vector2(-56, 72)
	_hp_bar.size = Vector2(112, 12)


func _build_visuals() -> void:
	# Stone well — castle purple-grey (Astronomist family)
	var well_shadow := FX.make_ellipse_poly(58, 24, 28, Color(0.08, 0.05, 0.12, 0.55))
	well_shadow.position = Vector2(0, 32)
	well_shadow.z_index = -4
	add_child(well_shadow)

	var well := FX.make_ellipse_poly(48, 19, 28, Color(0.22, 0.18, 0.30, 0.92))
	well.position = Vector2(0, 30)
	well.z_index = -3
	add_child(well)

	var well_rim := FX.make_ellipse_poly(42, 16, 26, Color(0.36, 0.32, 0.48, 0.88))
	well_rim.position = Vector2(0, 28)
	well_rim.z_index = -2
	add_child(well_rim)

	# Soft amethyst pool
	var pool := FX.make_ellipse_poly(22, 10, 18, Color(0.58, 0.42, 0.82, 0.34))
	pool.position = Vector2(0, 28)
	pool.z_index = -1
	add_child(pool)

	_shadow = FX.make_ellipse_poly(28, 10, 18, Color(0.06, 0.04, 0.12, 0.52))
	_shadow.position = Vector2(0, 34)
	_shadow.z_index = -1
	add_child(_shadow)

	# Soft vertical shaft — pale crystal light
	var shaft := Polygon2D.new()
	shaft.polygon = PackedVector2Array([
		Vector2(-12, -180), Vector2(12, -180), Vector2(7, 24), Vector2(-7, 24)
	])
	shaft.color = Color(0.82, 0.72, 0.98, 0.08)
	shaft.z_index = -5
	add_child(shaft)

	_float_root = Node2D.new()
	_float_root.name = "FloatRoot"
	_float_root.position = Vector2(0, -18)
	_float_root.z_index = 4
	add_child(_float_root)

	_rim_glow = FX.make_ellipse_poly(34, 44, 22, Color(0.62, 0.48, 0.88, 0.2))
	_rim_glow.position = Vector2(0, -12)
	_rim_glow.z_index = -1
	_float_root.add_child(_rim_glow)

	var outline := Polygon2D.new()
	outline.polygon = _main_body_pts(1.14)
	outline.color = Color(0.12, 0.09, 0.18, 0.95)
	outline.z_index = 0
	_float_root.add_child(outline)

	# Clear lavender body (film crystal read)
	_core = Polygon2D.new()
	_core.polygon = _main_body_pts(1.0)
	_core.color = Color(0.78, 0.74, 0.92, 1.0)
	_core.z_index = 1
	_float_root.add_child(_core)

	# Facets: river-green / dust-rose / amethyst (Thra refraction)
	_add_facet([
		Vector2(0, -72), Vector2(-22, -48), Vector2(-14, -8), Vector2(0, 4)
	], Color(0.38, 0.68, 0.60, 0.86), 2)

	_add_facet([
		Vector2(0, -72), Vector2(22, -48), Vector2(18, -6), Vector2(0, 4)
	], Color(0.82, 0.55, 0.68, 0.8), 2)

	_add_facet([
		Vector2(-22, -48), Vector2(-32, -12), Vector2(-18, 18), Vector2(-8, -4)
	], Color(0.42, 0.34, 0.72, 0.82), 2)

	_add_facet([
		Vector2(22, -48), Vector2(32, -12), Vector2(18, 18), Vector2(8, -4)
	], Color(0.58, 0.42, 0.82, 0.78), 2)

	_add_facet([
		Vector2(0, -72), Vector2(12, -54), Vector2(4, -28), Vector2(0, -16), Vector2(-8, -28)
	], Color(0.88, 0.82, 0.98, 0.55), 3)

	_add_facet([
		Vector2(0, -72), Vector2(12, -54), Vector2(0, -38), Vector2(-12, -54)
	], Color(0.98, 0.96, 1.0, 0.94), 3)

	_add_facet([
		Vector2(-10, 8), Vector2(0, 38), Vector2(10, 8), Vector2(0, -4)
	], Color(0.48, 0.68, 0.62, 0.52), 2)

	_add_facet([
		Vector2(-18, 18), Vector2(0, 42), Vector2(18, 18), Vector2(8, 28), Vector2(-8, 28)
	], Color(0.62, 0.42, 0.78, 0.68), 3)

	# Inner heart — soft pure-crystal white with amethyst pulse
	_heart = FX.make_ellipse_poly(8, 14, 12, Color(0.92, 0.88, 0.98, 0.95))
	_heart.position = Vector2(0, -8)
	_heart.z_index = 4
	_float_root.add_child(_heart)

	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([
		Vector2(0, -86), Vector2(8, -70), Vector2(0, -62), Vector2(-8, -70)
	])
	tip.color = Color(0.95, 0.90, 1.0, 0.98)
	tip.z_index = 4
	_float_root.add_child(tip)
	_facets.append(tip)

	# Orbiting shards — teal / rose / amethyst
	var shard_cols := [
		Color(0.45, 0.78, 0.70, 0.88),
		Color(0.86, 0.58, 0.68, 0.88),
		Color(0.62, 0.48, 0.88, 0.88),
	]
	for i in 3:
		var shard := Polygon2D.new()
		var ang := float(i) * TAU / 3.0 + 0.3
		shard.polygon = PackedVector2Array([
			Vector2(0, -9), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0)
		])
		shard.color = shard_cols[i]
		shard.set_meta("orbit", ang)
		shard.set_meta("dist", 42.0 + float(i % 2) * 6.0)
		shard.set_meta("hue", i)
		shard.name = "Shard%d" % i
		shard.z_index = 5
		_float_root.add_child(shard)


func _main_body_pts(scale: float) -> PackedVector2Array:
	var pts := PackedVector2Array([
		Vector2(0, -72), Vector2(22, -48), Vector2(32, -12), Vector2(22, 18),
		Vector2(8, 36), Vector2(0, 42), Vector2(-8, 36), Vector2(-22, 16),
		Vector2(-32, -12), Vector2(-22, -48)
	])
	if scale != 1.0:
		for i in pts.size():
			pts[i] *= scale
	return pts


func _add_facet(pts: Array, col: Color, z: int) -> void:
	var f := Polygon2D.new()
	var packed := PackedVector2Array()
	for p in pts:
		packed.append(p as Vector2)
	f.polygon = packed
	f.color = col
	f.z_index = z
	f.set_meta("base_color", col)
	_float_root.add_child(f)
	_facets.append(f)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	_shimmer_t = t

	_float_y = -14.0 + sin(t * 1.15) * 6.5
	if _float_root:
		_float_root.position.y = _float_y
		_float_root.position.x = sin(t * 0.5) * 1.6
		_float_root.rotation = sin(t * 0.4) * 0.035

	if _shadow:
		var lift := clampf((-_float_y - 6.0) / 20.0, 0.0, 1.0)
		var sc := 1.0 - lift * 0.22
		_shadow.scale = Vector2(sc, sc)
		_shadow.modulate.a = 0.38 + (1.0 - lift) * 0.22

	if _rim_glow:
		_rim_glow.modulate.a = 0.65 + 0.35 * sin(t * 1.9)
		# Cycle: river green → dust rose → amethyst
		var hue_t := fmod(t * 0.32, 3.0)
		var g := Color(0.42, 0.72, 0.64, 0.22)
		var p := Color(0.86, 0.52, 0.66, 0.22)
		var u := Color(0.58, 0.42, 0.88, 0.22)
		var rim: Color
		if hue_t < 1.0:
			rim = g.lerp(p, hue_t)
		elif hue_t < 2.0:
			rim = p.lerp(u, hue_t - 1.0)
		else:
			rim = u.lerp(g, hue_t - 2.0)
		_rim_glow.color = rim

	if _core:
		var pulse := 1.0 + 0.025 * sin(t * 2.2)
		_core.scale = Vector2(pulse, pulse)
		var healthy := Color(0.78, 0.74, 0.92, 1.0)
		var hurt := Color(0.82, 0.28, 0.38, 1.0)
		var shimmer := 0.5 + 0.5 * sin(t * 1.5)
		healthy = healthy.lerp(Color(0.55, 0.72, 0.70, 1.0), shimmer * 0.2)
		_core.color = healthy.lerp(hurt, 1.0 - _health_t)

	for i in _facets.size():
		var f: Polygon2D = _facets[i]
		if not is_instance_valid(f):
			continue
		if f.has_meta("base_color"):
			var base: Color = f.get_meta("base_color")
			var wave := 0.75 + 0.25 * sin(t * 2.4 + float(i) * 0.9)
			f.color = Color(base.r, base.g, base.b, base.a * wave)

	if _heart:
		var hp := 1.0 + 0.1 * sin(t * 3.2)
		_heart.scale = Vector2(hp, hp)
		var pure := Color(0.95, 0.92, 1.0, 0.95)
		var dim := Color(0.72, 0.28, 0.35, 0.8)
		var pulse_col := pure.lerp(Color(0.62, 0.48, 0.88, 0.95), 0.45 + 0.45 * sin(t * 1.7))
		_heart.color = pulse_col.lerp(dim, 1.0 - _health_t)

	if _float_root:
		for c in _float_root.get_children():
			if c is Polygon2D and str(c.name).begins_with("Shard"):
				var ang: float = c.get_meta("orbit") + t * 0.7
				var dist: float = c.get_meta("dist")
				c.position = Vector2(cos(ang), sin(ang) * 0.55) * dist + Vector2(0, -8)
				c.rotation = ang
				c.modulate.a = 0.7 + 0.3 * sin(t * 2.0 + ang)

	if _hp_bar:
		_hp_bar.position = Vector2(-56, 72)


func _on_hp(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_health_t = float(current) / float(maxi(1, maximum))


func get_hurtbox_position() -> Vector2:
	return global_position
