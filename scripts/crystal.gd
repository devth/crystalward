extends Node2D
## Castle of the Crystal — Brian Froud organic stone fortress + Crystal Chamber.
## Architecture only: living rock spires, open chamber, pure Crystal of Truth.
## No runes, glyphs, standing stones, or ritual/witchcraft props.

@onready var _hp_bar: ProgressBar = $HpBar

var _float_root: Node2D
var _core: Polygon2D
var _facets: Array[Polygon2D] = []
var _heart: Polygon2D
var _shadow: Polygon2D
var _rim_glow: Polygon2D
var _shaft_glow: Polygon2D
var _ember_core: Polygon2D
var _health_t: float = 1.0
var _float_y: float = 0.0

# Froud castle stone — bone-slate and cool ash, not purple magic or green moss-witch
const STONE_DEEP := Color(0.10, 0.09, 0.11, 0.98)
const STONE := Color(0.20, 0.18, 0.20, 0.96)
const STONE_LIT := Color(0.34, 0.31, 0.32, 0.95)
const STONE_RIM := Color(0.46, 0.42, 0.40, 0.92)
const STONE_WARM := Color(0.28, 0.24, 0.22, 0.9)
const EMBER := Color(0.72, 0.32, 0.12, 0.55)
const EMBER_LIT := Color(0.95, 0.55, 0.22, 0.4)


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
	FX.style_progress_bar(_hp_bar, Color(0.72, 0.68, 0.78), Color(0.08, 0.07, 0.09, 0.9))
	_hp_bar.position = Vector2(-58, 118)
	_hp_bar.size = Vector2(116, 12)


func _build_visuals() -> void:
	_build_foundation()
	_build_tower_mass()
	_build_chamber_shaft()
	_build_spire_cluster()
	_build_chamber_mouth()
	_build_crystal_gem()
	_build_fore_ledge()


func _build_foundation() -> void:
	## Heavy organic plinth — castle grows from the rock, not a magic circle.
	var shadow := FX.make_ellipse_poly(118, 48, 36, Color(0.03, 0.02, 0.04, 0.55))
	shadow.position = Vector2(0, 62)
	shadow.z_index = -14
	add_child(shadow)

	# Irregular rock apron (asymmetric living stone)
	var apron := Polygon2D.new()
	apron.polygon = PackedVector2Array([
		Vector2(-108, 58), Vector2(-70, 72), Vector2(-20, 78), Vector2(30, 76),
		Vector2(80, 70), Vector2(112, 54), Vector2(96, 40), Vector2(40, 36),
		Vector2(-50, 38), Vector2(-100, 46)
	])
	apron.color = STONE_DEEP
	apron.z_index = -13
	add_child(apron)

	var apron_lit := Polygon2D.new()
	apron_lit.polygon = PackedVector2Array([
		Vector2(-88, 50), Vector2(-40, 60), Vector2(20, 62), Vector2(72, 54),
		Vector2(90, 44), Vector2(50, 38), Vector2(-30, 40), Vector2(-78, 44)
	])
	apron_lit.color = STONE
	apron_lit.z_index = -12
	add_child(apron_lit)

	# Stepped chamber dais — plain stone tiers
	for i in 3:
		var r := 74.0 - i * 12.0
		var ry := 28.0 - i * 3.5
		var ring := FX.make_ellipse_poly(r, ry, 32, STONE_LIT if i == 2 else STONE_WARM)
		ring.position = Vector2(0, 46 - i * 5)
		ring.z_index = -11 + i
		add_child(ring)


func _build_tower_mass() -> void:
	## Bulbous Froud mass — organic fortress body, not a gothic church.
	# Deep rear silhouette (wide base, pinched mid, high crown)
	var rear := Polygon2D.new()
	rear.polygon = PackedVector2Array([
		Vector2(-62, 28), Vector2(62, 28), Vector2(58, -20), Vector2(50, -70),
		Vector2(36, -118), Vector2(18, -150), Vector2(0, -162), Vector2(-18, -150),
		Vector2(-36, -118), Vector2(-50, -70), Vector2(-58, -20)
	])
	rear.color = STONE_DEEP
	rear.z_index = -4
	add_child(rear)

	var rear_mid := Polygon2D.new()
	rear_mid.polygon = PackedVector2Array([
		Vector2(-48, 22), Vector2(48, 22), Vector2(44, -18), Vector2(38, -65),
		Vector2(26, -110), Vector2(12, -138), Vector2(0, -148), Vector2(-12, -138),
		Vector2(-26, -110), Vector2(-38, -65), Vector2(-44, -18)
	])
	rear_mid.color = STONE
	rear_mid.z_index = -3
	add_child(rear_mid)

	# Left / right organic wall lobes — slightly asymmetric for living-stone read
	var left_wing := Polygon2D.new()
	left_wing.polygon = PackedVector2Array([
		Vector2(-88, 40), Vector2(-44, 30), Vector2(-40, -28), Vector2(-52, -88),
		Vector2(-70, -128), Vector2(-98, -96), Vector2(-102, -40), Vector2(-94, 8)
	])
	left_wing.color = STONE
	left_wing.z_index = 1
	add_child(left_wing)

	var left_lit := Polygon2D.new()
	left_lit.polygon = PackedVector2Array([
		Vector2(-74, 28), Vector2(-50, 22), Vector2(-48, -24), Vector2(-56, -80),
		Vector2(-68, -112), Vector2(-82, -78), Vector2(-78, -10)
	])
	left_lit.color = STONE_LIT
	left_lit.z_index = 2
	add_child(left_lit)

	var right_wing := Polygon2D.new()
	right_wing.polygon = PackedVector2Array([
		Vector2(84, 38), Vector2(42, 28), Vector2(38, -32), Vector2(48, -92),
		Vector2(64, -122), Vector2(96, -88), Vector2(98, -28), Vector2(90, 12)
	])
	right_wing.color = STONE
	right_wing.z_index = 1
	add_child(right_wing)

	var right_lit := Polygon2D.new()
	right_lit.polygon = PackedVector2Array([
		Vector2(70, 26), Vector2(48, 20), Vector2(46, -26), Vector2(54, -84),
		Vector2(64, -108), Vector2(78, -70), Vector2(74, -6)
	])
	right_lit.color = STONE_LIT
	right_lit.z_index = 2
	add_child(right_lit)

	# Structural stone ribs (buttresses — architecture, not glyphs)
	for sx in [-1.0, 1.0]:
		var rib := Polygon2D.new()
		rib.polygon = PackedVector2Array([
			Vector2(sx * 46, 32), Vector2(sx * 58, 28), Vector2(sx * 54, -48),
			Vector2(sx * 46, -96), Vector2(sx * 38, -52)
		])
		rib.color = STONE_RIM
		rib.z_index = 3
		add_child(rib)

	# Dark window slits (architecture)
	for p in [Vector2(-56, -40), Vector2(56, -36), Vector2(-40, -78), Vector2(42, -82)]:
		var win := Polygon2D.new()
		win.polygon = PackedVector2Array([
			p + Vector2(-3, 8), p + Vector2(3, 8), p + Vector2(2.5, -10),
			p + Vector2(0, -14), p + Vector2(-2.5, -10)
		])
		win.color = Color(0.05, 0.04, 0.06, 0.85)
		win.z_index = 4
		add_child(win)

	# Soft cool light from chamber oculus (opening in the rock, not a magic beam)
	var oculus := Polygon2D.new()
	oculus.polygon = PackedVector2Array([
		Vector2(-12, -154), Vector2(12, -154), Vector2(7, -72), Vector2(-7, -72)
	])
	oculus.color = Color(0.78, 0.76, 0.82, 0.05)
	oculus.z_index = -2
	add_child(oculus)


func _build_chamber_shaft() -> void:
	## Chamber floor + deep ember shaft (film Lake of Fire) — plain stone ring only.
	var floor_outer := FX.make_ellipse_poly(52, 22, 30, Color(0.12, 0.11, 0.12, 0.96))
	floor_outer.position = Vector2(0, 30)
	floor_outer.z_index = 0
	add_child(floor_outer)

	var floor_rim := FX.make_ellipse_poly(44, 18, 28, STONE_RIM)
	floor_rim.position = Vector2(0, 28)
	floor_rim.z_index = 0
	add_child(floor_rim)

	var lip := FX.make_ellipse_poly(36, 14, 26, STONE_LIT)
	lip.position = Vector2(0, 28)
	lip.z_index = 1
	add_child(lip)

	var void_hole := FX.make_ellipse_poly(26, 11, 20, Color(0.03, 0.02, 0.03, 0.96))
	void_hole.position = Vector2(0, 28)
	void_hole.z_index = 1
	add_child(void_hole)

	# Ember pool — soft heat under the crystal, not cartoon flames
	_shaft_glow = FX.make_ellipse_poly(22, 9, 18, EMBER)
	_shaft_glow.position = Vector2(0, 28)
	_shaft_glow.z_index = 2
	add_child(_shaft_glow)

	_ember_core = FX.make_ellipse_poly(12, 5, 14, EMBER_LIT)
	_ember_core.position = Vector2(0, 28)
	_ember_core.z_index = 3
	add_child(_ember_core)

	# Faint heat haze column (architecture light, not fire tongues)
	var haze := Polygon2D.new()
	haze.polygon = PackedVector2Array([
		Vector2(-8, 24), Vector2(8, 24), Vector2(5, -8), Vector2(-5, -8)
	])
	haze.color = Color(0.9, 0.5, 0.2, 0.08)
	haze.z_index = 3
	haze.name = "HeatHaze"
	add_child(haze)

	_shadow = FX.make_ellipse_poly(16, 6, 16, Color(0.04, 0.03, 0.05, 0.42))
	_shadow.position = Vector2(0, 24)
	_shadow.z_index = 4
	add_child(_shadow)


func _build_spire_cluster() -> void:
	## Castle of the Crystal exterior — uneven needle spires of living rock.
	# Outer tall pair
	_add_spire(Vector2(-86, 22), 1.18, true, 0.0)
	_add_spire(Vector2(82, 20), 1.12, false, 0.08)
	# Mid pair
	_add_spire(Vector2(-58, -8), 0.92, true, 0.04)
	_add_spire(Vector2(56, -12), 0.88, false, -0.05)
	# Inner high pair
	_add_spire(Vector2(-34, -48), 0.68, true, 0.1)
	_add_spire(Vector2(32, -52), 0.72, false, -0.08)
	# Far rear needles for depth / silhouette
	_add_spire(Vector2(-22, -20), 0.55, true, 0.0)
	_add_spire(Vector2(20, -18), 0.5, false, 0.0)

	# Central crown of rock peaks (stone only — no jewel ornaments)
	var crown_a := Polygon2D.new()
	crown_a.polygon = PackedVector2Array([
		Vector2(-22, -142), Vector2(-6, -178), Vector2(4, -150), Vector2(-4, -138)
	])
	crown_a.color = STONE_RIM
	crown_a.z_index = 2
	add_child(crown_a)

	var crown_b := Polygon2D.new()
	crown_b.polygon = PackedVector2Array([
		Vector2(-4, -148), Vector2(0, -188), Vector2(10, -152), Vector2(4, -140)
	])
	crown_b.color = STONE_LIT
	crown_b.z_index = 3
	add_child(crown_b)

	var crown_c := Polygon2D.new()
	crown_c.polygon = PackedVector2Array([
		Vector2(6, -140), Vector2(18, -168), Vector2(24, -136), Vector2(10, -132)
	])
	crown_c.color = STONE
	crown_c.z_index = 2
	add_child(crown_c)


func _add_spire(origin: Vector2, scale: float, left: bool, lean: float) -> void:
	var sx := -1.0 if left else 1.0
	var h := 102.0 * scale
	var w := 16.0 * scale
	var tip_x := sx * lean * 18.0

	# Organic stem — slightly bowed needle
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		origin + Vector2(-w, 14),
		origin + Vector2(w * 0.95, 12),
		origin + Vector2(w * 0.45 + tip_x * 0.3, -h * 0.48),
		origin + Vector2(tip_x + sx * w * 0.08, -h),
		origin + Vector2(-w * 0.35 + tip_x * 0.2, -h * 0.42)
	])
	base.color = STONE
	base.z_index = 2
	add_child(base)

	var lit := Polygon2D.new()
	lit.polygon = PackedVector2Array([
		origin + Vector2(sx * -w * 0.12, 8),
		origin + Vector2(sx * w * 0.48, 6),
		origin + Vector2(sx * w * 0.28 + tip_x * 0.25, -h * 0.5),
		origin + Vector2(tip_x * 0.7 + sx * w * 0.04, -h * 0.88)
	])
	lit.color = STONE_LIT
	lit.z_index = 3
	add_child(lit)

	# Needle tip
	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([
		origin + Vector2(tip_x, -h - 18.0 * scale),
		origin + Vector2(tip_x + 3.5 * scale, -h + 2),
		origin + Vector2(tip_x - 3.5 * scale, -h + 2)
	])
	tip.color = STONE_RIM
	tip.z_index = 4
	add_child(tip)

	# Small stone shelf (balcony) on larger spires
	if scale >= 0.85:
		var balc := Polygon2D.new()
		balc.polygon = PackedVector2Array([
			origin + Vector2(sx * -5, -h * 0.36),
			origin + Vector2(sx * 13, -h * 0.38),
			origin + Vector2(sx * 12, -h * 0.28),
			origin + Vector2(sx * -4, -h * 0.26)
		])
		balc.color = STONE_DEEP
		balc.z_index = 4
		add_child(balc)


func _build_chamber_mouth() -> void:
	## Open chamber arch — stone framing so the crystal reads clearly.
	var hood := Polygon2D.new()
	hood.polygon = PackedVector2Array([
		Vector2(-50, -4), Vector2(50, -4), Vector2(44, -50), Vector2(22, -96),
		Vector2(0, -112), Vector2(-22, -96), Vector2(-44, -50)
	])
	hood.color = Color(0.09, 0.08, 0.1, 0.52)
	hood.z_index = 5
	add_child(hood)

	var mouth := Polygon2D.new()
	mouth.polygon = PackedVector2Array([
		Vector2(-36, 10), Vector2(36, 10), Vector2(32, -40), Vector2(14, -80),
		Vector2(0, -92), Vector2(-14, -80), Vector2(-32, -40)
	])
	mouth.color = Color(0.14, 0.12, 0.14, 0.28)
	mouth.z_index = 5
	add_child(mouth)

	for sx in [-1.0, 1.0]:
		var rib := Polygon2D.new()
		rib.polygon = PackedVector2Array([
			Vector2(sx * 34, 12), Vector2(sx * 42, 10), Vector2(sx * 38, -44),
			Vector2(sx * 18, -84), Vector2(sx * 10, -72), Vector2(sx * 28, -40)
		])
		rib.color = STONE_RIM
		rib.z_index = 6
		add_child(rib)

	# Plain keystone wedge
	var key := Polygon2D.new()
	key.polygon = PackedVector2Array([
		Vector2(-8, -102), Vector2(0, -116), Vector2(8, -102), Vector2(5, -92), Vector2(-5, -92)
	])
	key.color = STONE_LIT
	key.z_index = 7
	add_child(key)


func _build_crystal_gem() -> void:
	## Crystal of Truth — clear faceted gem suspended over the shaft.
	_float_root = Node2D.new()
	_float_root.name = "FloatRoot"
	_float_root.position = Vector2(0, -30)
	_float_root.z_index = 10
	add_child(_float_root)

	_rim_glow = FX.make_ellipse_poly(32, 44, 22, Color(0.82, 0.84, 0.92, 0.12))
	_rim_glow.position = Vector2(0, -6)
	_rim_glow.z_index = -1
	_float_root.add_child(_rim_glow)

	var outline := Polygon2D.new()
	outline.polygon = _main_body_pts(1.12)
	outline.color = Color(0.14, 0.13, 0.16, 0.95)
	outline.z_index = 0
	_float_root.add_child(outline)

	_core = Polygon2D.new()
	_core.polygon = _main_body_pts(1.0)
	_core.color = Color(0.90, 0.91, 0.96, 1.0)
	_core.z_index = 1
	_float_root.add_child(_core)

	# Clear cool facets — glass/crystal light only (no rainbow magic)
	_add_facet([
		Vector2(0, -58), Vector2(-18, -38), Vector2(-12, -4), Vector2(0, 6)
	], Color(0.58, 0.64, 0.76, 0.78), 2)
	_add_facet([
		Vector2(0, -58), Vector2(18, -38), Vector2(14, -4), Vector2(0, 6)
	], Color(0.94, 0.94, 0.98, 0.72), 2)
	_add_facet([
		Vector2(-18, -38), Vector2(-26, -8), Vector2(-14, 16), Vector2(-6, -2)
	], Color(0.50, 0.52, 0.62, 0.76), 2)
	_add_facet([
		Vector2(18, -38), Vector2(26, -8), Vector2(14, 16), Vector2(6, -2)
	], Color(0.72, 0.74, 0.84, 0.7), 2)
	_add_facet([
		Vector2(0, -58), Vector2(10, -42), Vector2(0, -30), Vector2(-10, -42)
	], Color(0.98, 0.98, 1.0, 0.95), 3)
	_add_facet([
		Vector2(-8, 10), Vector2(0, 32), Vector2(8, 10), Vector2(0, -2)
	], Color(0.62, 0.64, 0.74, 0.58), 3)

	_heart = FX.make_ellipse_poly(6, 11, 12, Color(0.96, 0.97, 1.0, 0.95))
	_heart.position = Vector2(0, -4)
	_heart.z_index = 4
	_float_root.add_child(_heart)

	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([
		Vector2(0, -70), Vector2(6, -56), Vector2(0, -50), Vector2(-6, -56)
	])
	tip.color = Color(0.98, 0.98, 1.0, 0.98)
	tip.z_index = 4
	_float_root.add_child(tip)
	_facets.append(tip)


func _build_fore_ledge() -> void:
	## Foreground stone rail — plain architecture.
	var ledge := Polygon2D.new()
	ledge.polygon = PackedVector2Array([
		Vector2(-50, 20), Vector2(50, 20), Vector2(46, 32), Vector2(-46, 32)
	])
	ledge.color = STONE_LIT
	ledge.z_index = 12
	add_child(ledge)

	var ledge_top := Polygon2D.new()
	ledge_top.polygon = PackedVector2Array([
		Vector2(-48, 16), Vector2(48, 16), Vector2(46, 22), Vector2(-46, 22)
	])
	ledge_top.color = STONE_RIM
	ledge_top.z_index = 13
	add_child(ledge_top)

	for x in [-34.0, -12.0, 12.0, 34.0]:
		var post := Polygon2D.new()
		post.polygon = PackedVector2Array([
			Vector2(x - 2.5, 10), Vector2(x + 2.5, 10), Vector2(x + 2, 26), Vector2(x - 2, 26)
		])
		post.color = STONE
		post.z_index = 14
		add_child(post)


func _main_body_pts(scale: float) -> PackedVector2Array:
	var pts := PackedVector2Array([
		Vector2(0, -58), Vector2(18, -38), Vector2(26, -8), Vector2(16, 16),
		Vector2(6, 28), Vector2(0, 32), Vector2(-6, 28), Vector2(-16, 14),
		Vector2(-26, -8), Vector2(-18, -38)
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

	_float_y = -24.0 + sin(t * 1.0) * 4.5
	if _float_root:
		_float_root.position.y = _float_y
		_float_root.position.x = sin(t * 0.35) * 0.8
		_float_root.rotation = sin(t * 0.28) * 0.02

	if _shadow:
		var lift := clampf((-_float_y - 10.0) / 18.0, 0.0, 1.0)
		var sc := 1.0 - lift * 0.2
		_shadow.scale = Vector2(sc, sc)
		_shadow.modulate.a = 0.32 + (1.0 - lift) * 0.2

	if _shaft_glow:
		_shaft_glow.modulate.a = 0.7 + 0.18 * sin(t * 2.4)
		_shaft_glow.scale = Vector2(0.97 + 0.04 * sin(t * 1.8), 0.97 + 0.04 * cos(t * 2.0))

	if _ember_core and is_instance_valid(_ember_core):
		_ember_core.scale = Vector2.ONE * (0.94 + 0.08 * sin(t * 2.6))
		_ember_core.modulate.a = 0.75 + 0.2 * sin(t * 2.2)

	var haze := get_node_or_null("HeatHaze") as Polygon2D
	if haze:
		haze.modulate.a = 0.55 + 0.35 * sin(t * 1.9)
		haze.scale.y = 1.0 + 0.08 * sin(t * 2.1)

	if _rim_glow:
		_rim_glow.modulate.a = 0.5 + 0.2 * sin(t * 1.4)
		_rim_glow.color = Color(0.8, 0.82, 0.9, 0.14)

	if _core:
		var pulse := 1.0 + 0.015 * sin(t * 1.8)
		_core.scale = Vector2(pulse, pulse)
		var healthy := Color(0.90, 0.91, 0.96, 1.0)
		var hurt := Color(0.78, 0.32, 0.34, 1.0)
		_core.color = healthy.lerp(hurt, 1.0 - _health_t)

	for i in _facets.size():
		var f: Polygon2D = _facets[i]
		if not is_instance_valid(f) or not f.has_meta("base_color"):
			continue
		var base: Color = f.get_meta("base_color")
		var wave := 0.8 + 0.2 * sin(t * 1.8 + float(i) * 0.75)
		f.color = Color(base.r, base.g, base.b, base.a * wave)

	if _heart:
		var hp := 1.0 + 0.07 * sin(t * 2.4)
		_heart.scale = Vector2(hp, hp)
		var pure := Color(0.96, 0.97, 1.0, 0.95)
		var dim := Color(0.68, 0.28, 0.3, 0.8)
		_heart.color = pure.lerp(dim, 1.0 - _health_t)

	if _hp_bar:
		_hp_bar.position = Vector2(-58, 118)


func _on_hp(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_health_t = float(current) / float(maxi(1, maximum))


func get_hurtbox_position() -> Vector2:
	return global_position
