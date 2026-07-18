extends Node2D
## Castle of the Crystal — Dark Crystal–style tower housing the floating gem.
## Crystal Chamber: stone spires, chamber arch, Lake of Fire shaft, pure Crystal of Truth.

@onready var _hp_bar: ProgressBar = $HpBar

var _float_root: Node2D
var _core: Polygon2D
var _facets: Array[Polygon2D] = []
var _heart: Polygon2D
var _shadow: Polygon2D
var _rim_glow: Polygon2D
var _shaft_glow: Polygon2D
var _fire_lobes: Array[Polygon2D] = []
var _health_t: float = 1.0
var _float_y: float = 0.0

# Thra / castle stone
const STONE_DEEP := Color(0.10, 0.08, 0.14, 0.98)
const STONE := Color(0.18, 0.14, 0.24, 0.96)
const STONE_LIT := Color(0.30, 0.24, 0.38, 0.95)
const STONE_RIM := Color(0.42, 0.34, 0.52, 0.9)
const STONE_MOSS := Color(0.22, 0.32, 0.28, 0.55)
const FIRE_DEEP := Color(0.55, 0.18, 0.08, 0.75)
const FIRE := Color(0.95, 0.45, 0.15, 0.7)
const FIRE_LIT := Color(1.0, 0.75, 0.35, 0.55)


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
	_hp_bar.position = Vector2(-58, 108)
	_hp_bar.size = Vector2(116, 12)


func _build_visuals() -> void:
	_build_foundation()
	_build_tower_body()
	_build_chamber_shaft()
	_build_spires()
	_build_chamber_arch()
	_build_crystal_gem()
	_build_chamber_detail()


## Outer courtyard ring + heavy stone plinth (castle footprint).
func _build_foundation() -> void:
	var shadow := FX.make_ellipse_poly(110, 48, 36, Color(0.04, 0.03, 0.08, 0.55))
	shadow.position = Vector2(0, 58)
	shadow.z_index = -12
	add_child(shadow)

	# Outer buttress apron
	var apron := FX.make_ellipse_poly(98, 42, 36, STONE_DEEP)
	apron.position = Vector2(0, 52)
	apron.z_index = -11
	add_child(apron)

	var apron_lit := FX.make_ellipse_poly(86, 36, 32, STONE)
	apron_lit.position = Vector2(0, 48)
	apron_lit.z_index = -10
	add_child(apron_lit)

	# Stepped plinth (three rings like chamber tiers)
	for i in 3:
		var r := 72.0 - i * 12.0
		var ry := 30.0 - i * 4.0
		var ring := FX.make_ellipse_poly(r, ry, 30, STONE_LIT if i == 2 else STONE)
		ring.position = Vector2(0, 42 - i * 4)
		ring.z_index = -9 + i
		ring.color.a = 0.95
		add_child(ring)

	# Moss on lower stones
	var moss := FX.make_ellipse_poly(70, 18, 24, STONE_MOSS)
	moss.position = Vector2(0, 50)
	moss.z_index = -6
	add_child(moss)

	# Three ceremonial approach markers (Three Suns motif — small standing stones)
	for i in 3:
		var ang := -PI * 0.55 + float(i) * 0.55
		var p := Vector2(cos(ang), sin(ang) * 0.55) * 88.0 + Vector2(0, 40)
		_add_standing_tooth(p, 0.7 + float(i % 2) * 0.15, -5)


## Main tower walls — organic Froud stone (no straight skyscraper).
func _build_tower_body() -> void:
	# Rear wall mass (behind crystal)
	var rear := Polygon2D.new()
	rear.polygon = PackedVector2Array([
		Vector2(-52, 20), Vector2(52, 20), Vector2(48, -70), Vector2(28, -130),
		Vector2(0, -148), Vector2(-28, -130), Vector2(-48, -70)
	])
	rear.color = STONE_DEEP
	rear.z_index = -3
	add_child(rear)

	# Rear mid tone (organic ridges)
	var rear_mid := Polygon2D.new()
	rear_mid.polygon = PackedVector2Array([
		Vector2(-40, 14), Vector2(40, 14), Vector2(36, -60), Vector2(20, -115),
		Vector2(0, -132), Vector2(-20, -115), Vector2(-36, -60)
	])
	rear_mid.color = STONE
	rear_mid.z_index = -2
	add_child(rear_mid)

	# Left wall wing (chamber side)
	var left := Polygon2D.new()
	left.polygon = PackedVector2Array([
		Vector2(-78, 36), Vector2(-42, 28), Vector2(-38, -40), Vector2(-48, -100),
		Vector2(-62, -125), Vector2(-88, -90), Vector2(-82, -20)
	])
	left.color = STONE
	left.z_index = 1
	add_child(left)

	var left_lit := Polygon2D.new()
	left_lit.polygon = PackedVector2Array([
		Vector2(-68, 28), Vector2(-48, 22), Vector2(-46, -30), Vector2(-54, -85),
		Vector2(-62, -105), Vector2(-72, -70)
	])
	left_lit.color = STONE_LIT
	left_lit.z_index = 2
	add_child(left_lit)

	# Right wall wing
	var right := Polygon2D.new()
	right.polygon = PackedVector2Array([
		Vector2(78, 36), Vector2(42, 28), Vector2(38, -40), Vector2(48, -100),
		Vector2(62, -125), Vector2(88, -90), Vector2(82, -20)
	])
	right.color = STONE
	right.z_index = 1
	add_child(right)

	var right_lit := Polygon2D.new()
	right_lit.polygon = PackedVector2Array([
		Vector2(68, 28), Vector2(48, 22), Vector2(46, -30), Vector2(54, -85),
		Vector2(62, -105), Vector2(72, -70)
	])
	right_lit.color = STONE_LIT
	right_lit.z_index = 2
	add_child(right_lit)

	# Buttress ribs along sides
	for sx in [-1.0, 1.0]:
		var rib := Polygon2D.new()
		rib.polygon = PackedVector2Array([
			Vector2(sx * 44, 30), Vector2(sx * 56, 28), Vector2(sx * 52, -55),
			Vector2(sx * 46, -95), Vector2(sx * 38, -50)
		])
		rib.color = STONE_RIM
		rib.z_index = 3
		add_child(rib)

	# Soft light shaft from ceiling hatch (Three Suns suggestion)
	var hatch := Polygon2D.new()
	hatch.polygon = PackedVector2Array([
		Vector2(-18, -145), Vector2(18, -145), Vector2(10, -60), Vector2(-10, -60)
	])
	hatch.color = Color(0.75, 0.65, 0.95, 0.07)
	hatch.z_index = -1
	add_child(hatch)


## Lake of Fire shaft under the crystal (chamber floor hole).
func _build_chamber_shaft() -> void:
	# Chamber floor ring
	var floor_outer := FX.make_ellipse_poly(48, 22, 28, Color(0.14, 0.11, 0.18, 0.95))
	floor_outer.position = Vector2(0, 28)
	floor_outer.z_index = 0
	add_child(floor_outer)

	var floor_rim := FX.make_ellipse_poly(40, 18, 26, STONE_RIM)
	floor_rim.position = Vector2(0, 26)
	floor_rim.z_index = 0
	add_child(floor_rim)

	# Circular + triangular etchings (ceremony symbols)
	for i in 6:
		var ang := TAU * float(i) / 6.0
		var tick := Polygon2D.new()
		tick.polygon = PackedVector2Array([
			Vector2(-2, -6), Vector2(2, -6), Vector2(1, 2), Vector2(-1, 2)
		])
		tick.color = Color(0.55, 0.42, 0.72, 0.55)
		tick.position = Vector2(cos(ang), sin(ang) * 0.55) * 34.0 + Vector2(0, 26)
		tick.rotation = ang
		tick.z_index = 1
		add_child(tick)

	# Shaft void
	var void_hole := FX.make_ellipse_poly(26, 12, 20, Color(0.04, 0.02, 0.06, 0.95))
	void_hole.position = Vector2(0, 26)
	void_hole.z_index = 1
	add_child(void_hole)

	# Lake of Fire glow
	_shaft_glow = FX.make_ellipse_poly(22, 10, 18, FIRE)
	_shaft_glow.position = Vector2(0, 26)
	_shaft_glow.z_index = 2
	add_child(_shaft_glow)

	var fire_core := FX.make_ellipse_poly(12, 6, 14, FIRE_LIT)
	fire_core.position = Vector2(0, 26)
	fire_core.z_index = 3
	fire_core.name = "FireCore"
	add_child(fire_core)
	_fire_lobes.append(fire_core)

	# Rising heat tongues
	for i in 4:
		var tongue := Polygon2D.new()
		var ox := float(i - 1.5) * 5.0
		tongue.polygon = PackedVector2Array([
			Vector2(ox - 3, 24), Vector2(ox, 8 - i * 3.0), Vector2(ox + 3, 24)
		])
		tongue.color = FIRE.lerp(FIRE_LIT, float(i) * 0.15)
		tongue.color.a = 0.45
		tongue.z_index = 3
		tongue.set_meta("base_y", 0.0)
		tongue.name = "FireTongue%d" % i
		add_child(tongue)
		_fire_lobes.append(tongue)

	# Crystal shadow on chamber floor
	_shadow = FX.make_ellipse_poly(18, 7, 16, Color(0.05, 0.03, 0.1, 0.45))
	_shadow.position = Vector2(0, 22)
	_shadow.z_index = 4
	add_child(_shadow)


## Tall flanking spires — castle exterior read.
func _build_spires() -> void:
	_add_spire(Vector2(-72, 20), 1.0, true)
	_add_spire(Vector2(72, 20), 1.0, false)
	_add_spire(Vector2(-48, -40), 0.72, true)
	_add_spire(Vector2(48, -40), 0.72, false)
	# Crown peak above chamber
	var crown := Polygon2D.new()
	crown.polygon = PackedVector2Array([
		Vector2(-16, -140), Vector2(0, -175), Vector2(16, -140),
		Vector2(10, -132), Vector2(0, -148), Vector2(-10, -132)
	])
	crown.color = STONE_RIM
	crown.z_index = 2
	add_child(crown)
	# Crystal tip ornament on crown
	var jewel := Polygon2D.new()
	jewel.polygon = PackedVector2Array([
		Vector2(0, -182), Vector2(5, -168), Vector2(0, -162), Vector2(-5, -168)
	])
	jewel.color = Color(0.72, 0.55, 0.92, 0.9)
	jewel.z_index = 3
	add_child(jewel)


func _add_spire(origin: Vector2, scale: float, left: bool) -> void:
	var sx := -1.0 if left else 1.0
	var h := 95.0 * scale
	var w := 18.0 * scale
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		origin + Vector2(-w * 0.9, 12),
		origin + Vector2(w * 0.9, 12),
		origin + Vector2(w * 0.55, -h * 0.55),
		origin + Vector2(sx * w * 0.15, -h),
		origin + Vector2(-w * 0.45, -h * 0.5)
	])
	base.color = STONE
	base.z_index = 2
	add_child(base)
	# Lit face
	var lit := Polygon2D.new()
	lit.polygon = PackedVector2Array([
		origin + Vector2(sx * -w * 0.2, 6),
		origin + Vector2(sx * w * 0.5, 4),
		origin + Vector2(sx * w * 0.3, -h * 0.55),
		origin + Vector2(sx * w * 0.05, -h * 0.92)
	])
	lit.color = STONE_LIT
	lit.z_index = 3
	add_child(lit)
	# Needle tip
	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([
		origin + Vector2(0, -h - 14 * scale),
		origin + Vector2(4 * scale, -h + 2),
		origin + Vector2(-4 * scale, -h + 2)
	])
	tip.color = STONE_RIM
	tip.z_index = 4
	add_child(tip)
	# Small balcony tooth
	var balc := Polygon2D.new()
	balc.polygon = PackedVector2Array([
		origin + Vector2(sx * -6, -h * 0.4),
		origin + Vector2(sx * 14, -h * 0.42),
		origin + Vector2(sx * 12, -h * 0.32),
		origin + Vector2(sx * -4, -h * 0.3)
	])
	balc.color = STONE_DEEP
	balc.z_index = 4
	add_child(balc)


## Open arch so the crystal is visible in the chamber mouth.
func _build_chamber_arch() -> void:
	# Dark arch hood framing the gem
	var hood := Polygon2D.new()
	hood.polygon = PackedVector2Array([
		Vector2(-46, -8), Vector2(46, -8), Vector2(40, -55), Vector2(18, -95),
		Vector2(0, -108), Vector2(-18, -95), Vector2(-40, -55)
	])
	hood.color = Color(0.12, 0.09, 0.16, 0.55)
	hood.z_index = 5
	add_child(hood)

	# Inner arch cut (lighter so crystal pops through)
	var mouth := Polygon2D.new()
	mouth.polygon = PackedVector2Array([
		Vector2(-32, 8), Vector2(32, 8), Vector2(28, -40), Vector2(12, -78),
		Vector2(0, -88), Vector2(-12, -78), Vector2(-28, -40)
	])
	mouth.color = Color(0.16, 0.12, 0.22, 0.35)
	mouth.z_index = 5
	add_child(mouth)

	# Stone arch ribs
	for sx in [-1.0, 1.0]:
		var rib := Polygon2D.new()
		rib.polygon = PackedVector2Array([
			Vector2(sx * 30, 10), Vector2(sx * 38, 8), Vector2(sx * 34, -45),
			Vector2(sx * 16, -82), Vector2(sx * 8, -70), Vector2(sx * 24, -40)
		])
		rib.color = STONE_RIM
		rib.z_index = 6
		add_child(rib)

	# Keystone above arch
	var key := Polygon2D.new()
	key.polygon = PackedVector2Array([
		Vector2(-8, -100), Vector2(0, -112), Vector2(8, -100), Vector2(4, -90), Vector2(-4, -90)
	])
	key.color = Color(0.48, 0.38, 0.58, 0.95)
	key.z_index = 7
	add_child(key)


## The Crystal of Truth — suspended in chamber over the fire shaft.
func _build_crystal_gem() -> void:
	_float_root = Node2D.new()
	_float_root.name = "FloatRoot"
	_float_root.position = Vector2(0, -28)
	_float_root.z_index = 10
	add_child(_float_root)

	_rim_glow = FX.make_ellipse_poly(36, 48, 24, Color(0.62, 0.48, 0.88, 0.22))
	_rim_glow.position = Vector2(0, -6)
	_rim_glow.z_index = -1
	_float_root.add_child(_rim_glow)

	# Soft hold beams (crystal levitates in chamber)
	for sx in [-1.0, 1.0]:
		var beam := Line2D.new()
		beam.width = 1.5
		beam.default_color = Color(0.65, 0.5, 0.9, 0.25)
		beam.points = PackedVector2Array([
			Vector2(sx * 28, 36), Vector2(sx * 8, 8), Vector2(0, -10)
		])
		beam.z_index = -1
		_float_root.add_child(beam)

	var outline := Polygon2D.new()
	outline.polygon = _main_body_pts(1.12)
	outline.color = Color(0.10, 0.07, 0.16, 0.95)
	outline.z_index = 0
	_float_root.add_child(outline)

	_core = Polygon2D.new()
	_core.polygon = _main_body_pts(1.0)
	_core.color = Color(0.82, 0.78, 0.95, 1.0)
	_core.z_index = 1
	_float_root.add_child(_core)

	# Facets — film crystal refraction
	_add_facet([
		Vector2(0, -58), Vector2(-18, -38), Vector2(-12, -4), Vector2(0, 6)
	], Color(0.40, 0.70, 0.64, 0.86), 2)
	_add_facet([
		Vector2(0, -58), Vector2(18, -38), Vector2(14, -4), Vector2(0, 6)
	], Color(0.84, 0.55, 0.70, 0.8), 2)
	_add_facet([
		Vector2(-18, -38), Vector2(-26, -8), Vector2(-14, 16), Vector2(-6, -2)
	], Color(0.45, 0.36, 0.75, 0.82), 2)
	_add_facet([
		Vector2(18, -38), Vector2(26, -8), Vector2(14, 16), Vector2(6, -2)
	], Color(0.60, 0.44, 0.85, 0.78), 2)
	_add_facet([
		Vector2(0, -58), Vector2(10, -42), Vector2(0, -30), Vector2(-10, -42)
	], Color(0.98, 0.96, 1.0, 0.94), 3)
	_add_facet([
		Vector2(-8, 10), Vector2(0, 32), Vector2(8, 10), Vector2(0, -2)
	], Color(0.55, 0.45, 0.82, 0.65), 3)

	_heart = FX.make_ellipse_poly(7, 12, 12, Color(0.95, 0.92, 1.0, 0.95))
	_heart.position = Vector2(0, -4)
	_heart.z_index = 4
	_float_root.add_child(_heart)

	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([
		Vector2(0, -70), Vector2(7, -56), Vector2(0, -50), Vector2(-7, -56)
	])
	tip.color = Color(0.96, 0.92, 1.0, 0.98)
	tip.z_index = 4
	_float_root.add_child(tip)
	_facets.append(tip)

	# Orbiting shards
	var shard_cols := [
		Color(0.45, 0.78, 0.70, 0.88),
		Color(0.86, 0.58, 0.68, 0.88),
		Color(0.62, 0.48, 0.88, 0.88),
	]
	for i in 3:
		var shard := Polygon2D.new()
		var ang := float(i) * TAU / 3.0 + 0.3
		shard.polygon = PackedVector2Array([
			Vector2(0, -8), Vector2(4, 0), Vector2(0, 5), Vector2(-4, 0)
		])
		shard.color = shard_cols[i]
		shard.set_meta("orbit", ang)
		shard.set_meta("dist", 34.0 + float(i % 2) * 5.0)
		shard.name = "Shard%d" % i
		shard.z_index = 5
		_float_root.add_child(shard)


func _build_chamber_detail() -> void:
	# Foreground balcony ledge (chamber railing)
	var ledge := Polygon2D.new()
	ledge.polygon = PackedVector2Array([
		Vector2(-50, 18), Vector2(50, 18), Vector2(46, 28), Vector2(-46, 28)
	])
	ledge.color = STONE_LIT
	ledge.z_index = 12
	add_child(ledge)

	var ledge_top := Polygon2D.new()
	ledge_top.polygon = PackedVector2Array([
		Vector2(-48, 14), Vector2(48, 14), Vector2(46, 20), Vector2(-46, 20)
	])
	ledge_top.color = STONE_RIM
	ledge_top.z_index = 13
	add_child(ledge_top)

	# Balcony posts
	for x in [-36.0, -12.0, 12.0, 36.0]:
		var post := Polygon2D.new()
		post.polygon = PackedVector2Array([
			Vector2(x - 3, 8), Vector2(x + 3, 8), Vector2(x + 2, 22), Vector2(x - 2, 22)
		])
		post.color = STONE
		post.z_index = 14
		add_child(post)

	# Small Skeksis-banner hooks (ornament, not clutter)
	for sx in [-1.0, 1.0]:
		var hook := Polygon2D.new()
		hook.polygon = PackedVector2Array([
			Vector2(sx * 55, -20), Vector2(sx * 68, -18), Vector2(sx * 66, 0), Vector2(sx * 54, -2)
		])
		hook.color = Color(0.35, 0.18, 0.28, 0.75)
		hook.z_index = 4
		add_child(hook)


func _add_standing_tooth(pos: Vector2, scale: float, z: int) -> void:
	var tooth := Polygon2D.new()
	var h := 22.0 * scale
	var w := 8.0 * scale
	tooth.polygon = PackedVector2Array([
		pos + Vector2(-w, 4), pos + Vector2(w, 4),
		pos + Vector2(w * 0.5, -h * 0.6), pos + Vector2(0, -h),
		pos + Vector2(-w * 0.5, -h * 0.6)
	])
	tooth.color = STONE
	tooth.z_index = z
	add_child(tooth)


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

	# Crystal floats in the chamber (like the film)
	_float_y = -22.0 + sin(t * 1.1) * 5.5
	if _float_root:
		_float_root.position.y = _float_y
		_float_root.position.x = sin(t * 0.45) * 1.2
		_float_root.rotation = sin(t * 0.35) * 0.03

	if _shadow:
		var lift := clampf((-_float_y - 10.0) / 18.0, 0.0, 1.0)
		var sc := 1.0 - lift * 0.25
		_shadow.scale = Vector2(sc, sc)
		_shadow.modulate.a = 0.35 + (1.0 - lift) * 0.25

	# Lake of Fire pulse
	if _shaft_glow:
		var pulse := 0.75 + 0.25 * sin(t * 3.2)
		_shaft_glow.modulate.a = pulse
		_shaft_glow.scale = Vector2(0.95 + 0.08 * sin(t * 2.5), 0.95 + 0.08 * cos(t * 2.8))

	for i in _fire_lobes.size():
		var lobe: Polygon2D = _fire_lobes[i]
		if not is_instance_valid(lobe):
			continue
		if str(lobe.name).begins_with("FireTongue"):
			lobe.modulate.a = 0.35 + 0.25 * sin(t * 4.0 + float(i) * 1.2)
			lobe.position.y = sin(t * 3.5 + float(i)) * 2.0
		elif str(lobe.name) == "FireCore":
			lobe.scale = Vector2.ONE * (0.9 + 0.12 * sin(t * 3.8))

	if _rim_glow:
		_rim_glow.modulate.a = 0.65 + 0.35 * sin(t * 1.8)
		var hue_t := fmod(t * 0.3, 3.0)
		var g := Color(0.42, 0.72, 0.64, 0.22)
		var p := Color(0.86, 0.52, 0.66, 0.22)
		var u := Color(0.58, 0.42, 0.88, 0.22)
		if hue_t < 1.0:
			_rim_glow.color = g.lerp(p, hue_t)
		elif hue_t < 2.0:
			_rim_glow.color = p.lerp(u, hue_t - 1.0)
		else:
			_rim_glow.color = u.lerp(g, hue_t - 2.0)

	if _core:
		var pulse := 1.0 + 0.02 * sin(t * 2.2)
		_core.scale = Vector2(pulse, pulse)
		var healthy := Color(0.82, 0.78, 0.95, 1.0)
		var hurt := Color(0.82, 0.28, 0.38, 1.0)
		healthy = healthy.lerp(Color(0.55, 0.72, 0.70, 1.0), (0.5 + 0.5 * sin(t * 1.5)) * 0.18)
		_core.color = healthy.lerp(hurt, 1.0 - _health_t)

	for i in _facets.size():
		var f: Polygon2D = _facets[i]
		if not is_instance_valid(f) or not f.has_meta("base_color"):
			continue
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
				var ang: float = c.get_meta("orbit") + t * 0.65
				var dist: float = c.get_meta("dist")
				c.position = Vector2(cos(ang), sin(ang) * 0.55) * dist + Vector2(0, -4)
				c.rotation = ang
				c.modulate.a = 0.7 + 0.3 * sin(t * 2.0 + ang)

	if _hp_bar:
		_hp_bar.position = Vector2(-58, 108)


func _on_hp(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_health_t = float(current) / float(maxi(1, maximum))


func get_hurtbox_position() -> Vector2:
	return global_position
