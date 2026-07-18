extends Node2D
## Castle of the Crystal — organic stone tower + Crystal Chamber (film architecture).
## No runes, no ritual glyphs, no witchcraft props. Architecture + pure crystal.

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

# Castle stone — cool slate / bone-violet of the Skeksis castle, not green magic
const STONE_DEEP := Color(0.11, 0.10, 0.14, 0.98)
const STONE := Color(0.20, 0.18, 0.24, 0.96)
const STONE_LIT := Color(0.32, 0.30, 0.36, 0.95)
const STONE_RIM := Color(0.40, 0.38, 0.44, 0.92)
const STONE_MOSS := Color(0.18, 0.22, 0.20, 0.4)
const FIRE := Color(0.9, 0.42, 0.14, 0.7)
const FIRE_LIT := Color(1.0, 0.72, 0.32, 0.55)


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
	FX.style_progress_bar(_hp_bar, Color(0.7, 0.55, 0.85), Color(0.08, 0.07, 0.1, 0.9))
	_hp_bar.position = Vector2(-58, 112)
	_hp_bar.size = Vector2(116, 12)


func _build_visuals() -> void:
	_build_foundation()
	_build_tower_body()
	_build_chamber_shaft()
	_build_spires()
	_build_chamber_arch()
	_build_crystal_gem()
	_build_chamber_rail()


func _build_foundation() -> void:
	## Heavy stone plinth — castle footprint, clean rings only.
	var shadow := FX.make_ellipse_poly(108, 46, 36, Color(0.04, 0.03, 0.06, 0.5))
	shadow.position = Vector2(0, 58)
	shadow.z_index = -12
	add_child(shadow)

	var apron := FX.make_ellipse_poly(96, 40, 36, STONE_DEEP)
	apron.position = Vector2(0, 52)
	apron.z_index = -11
	add_child(apron)

	var apron_lit := FX.make_ellipse_poly(84, 34, 32, STONE)
	apron_lit.position = Vector2(0, 48)
	apron_lit.z_index = -10
	add_child(apron_lit)

	# Stepped circular tiers (chamber dais)
	for i in 3:
		var r := 70.0 - i * 11.0
		var ry := 28.0 - i * 3.5
		var ring := FX.make_ellipse_poly(r, ry, 32, STONE_LIT if i == 2 else STONE)
		ring.position = Vector2(0, 42 - i * 4)
		ring.z_index = -9 + i
		add_child(ring)

	# Slight damp moss at base only
	var moss := FX.make_ellipse_poly(66, 16, 24, STONE_MOSS)
	moss.position = Vector2(0, 50)
	moss.z_index = -6
	add_child(moss)


func _build_tower_body() -> void:
	## Organic Froud stone mass — bulbous, structural, not a gothic church.
	# Rear wall (behind crystal)
	var rear := Polygon2D.new()
	rear.polygon = PackedVector2Array([
		Vector2(-54, 18), Vector2(54, 18), Vector2(50, -55), Vector2(36, -100),
		Vector2(14, -138), Vector2(0, -152), Vector2(-14, -138), Vector2(-36, -100),
		Vector2(-50, -55)
	])
	rear.color = STONE_DEEP
	rear.z_index = -3
	add_child(rear)

	var rear_mid := Polygon2D.new()
	rear_mid.polygon = PackedVector2Array([
		Vector2(-42, 12), Vector2(42, 12), Vector2(38, -50), Vector2(26, -95),
		Vector2(10, -128), Vector2(0, -140), Vector2(-10, -128), Vector2(-26, -95),
		Vector2(-38, -50)
	])
	rear_mid.color = STONE
	rear_mid.z_index = -2
	add_child(rear_mid)

	# Left / right organic wall lobes (castle body)
	for sx in [-1.0, 1.0]:
		var wing := Polygon2D.new()
		wing.polygon = PackedVector2Array([
			Vector2(sx * 76, 34), Vector2(sx * 40, 26), Vector2(sx * 36, -35),
			Vector2(sx * 48, -95), Vector2(sx * 64, -118), Vector2(sx * 90, -82),
			Vector2(sx * 84, -18)
		])
		wing.color = STONE
		wing.z_index = 1
		add_child(wing)
		var wing_lit := Polygon2D.new()
		wing_lit.polygon = PackedVector2Array([
			Vector2(sx * 66, 26), Vector2(sx * 46, 20), Vector2(sx * 44, -28),
			Vector2(sx * 52, -82), Vector2(sx * 62, -100), Vector2(sx * 72, -65)
		])
		wing_lit.color = STONE_LIT
		wing_lit.z_index = 2
		add_child(wing_lit)
		# Structural rib (stone architecture, not glyph)
		var rib := Polygon2D.new()
		rib.polygon = PackedVector2Array([
			Vector2(sx * 42, 28), Vector2(sx * 54, 26), Vector2(sx * 50, -50),
			Vector2(sx * 44, -90), Vector2(sx * 36, -48)
		])
		rib.color = STONE_RIM
		rib.z_index = 3
		add_child(rib)

	# Soft ceiling light from chamber oculus (architecture opening, not magic beam)
	var oculus := Polygon2D.new()
	oculus.polygon = PackedVector2Array([
		Vector2(-14, -148), Vector2(14, -148), Vector2(8, -70), Vector2(-8, -70)
	])
	oculus.color = Color(0.85, 0.82, 0.95, 0.06)
	oculus.z_index = -1
	add_child(oculus)


func _build_chamber_shaft() -> void:
	## Crystal Chamber floor: stone ring + Lake of Fire (film) — no etched runes.
	var floor_outer := FX.make_ellipse_poly(50, 22, 30, Color(0.14, 0.12, 0.16, 0.95))
	floor_outer.position = Vector2(0, 28)
	floor_outer.z_index = 0
	add_child(floor_outer)

	var floor_rim := FX.make_ellipse_poly(42, 18, 28, STONE_RIM)
	floor_rim.position = Vector2(0, 26)
	floor_rim.z_index = 0
	add_child(floor_rim)

	# Clean stone lip (structural, not symbols)
	var lip := FX.make_ellipse_poly(34, 14, 26, STONE_LIT)
	lip.position = Vector2(0, 26)
	lip.z_index = 1
	add_child(lip)

	var void_hole := FX.make_ellipse_poly(24, 11, 20, Color(0.04, 0.03, 0.05, 0.95))
	void_hole.position = Vector2(0, 26)
	void_hole.z_index = 1
	add_child(void_hole)

	_shaft_glow = FX.make_ellipse_poly(20, 9, 18, FIRE)
	_shaft_glow.position = Vector2(0, 26)
	_shaft_glow.z_index = 2
	add_child(_shaft_glow)

	var fire_core := FX.make_ellipse_poly(11, 5, 14, FIRE_LIT)
	fire_core.position = Vector2(0, 26)
	fire_core.z_index = 3
	fire_core.name = "FireCore"
	add_child(fire_core)
	_fire_lobes.append(fire_core)

	for i in 3:
		var tongue := Polygon2D.new()
		var ox := float(i - 1) * 5.0
		tongue.polygon = PackedVector2Array([
			Vector2(ox - 2.5, 24), Vector2(ox, 10 - i * 2.5), Vector2(ox + 2.5, 24)
		])
		tongue.color = FIRE.lerp(FIRE_LIT, float(i) * 0.2)
		tongue.color.a = 0.4
		tongue.z_index = 3
		tongue.name = "FireTongue%d" % i
		add_child(tongue)
		_fire_lobes.append(tongue)

	_shadow = FX.make_ellipse_poly(16, 6, 16, Color(0.05, 0.04, 0.08, 0.4))
	_shadow.position = Vector2(0, 22)
	_shadow.z_index = 4
	add_child(_shadow)


func _build_spires() -> void:
	## Flanking castle spires — organic needles like the Castle of the Crystal.
	_add_spire(Vector2(-74, 18), 1.05, true)
	_add_spire(Vector2(74, 18), 1.05, false)
	_add_spire(Vector2(-50, -38), 0.75, true)
	_add_spire(Vector2(50, -38), 0.75, false)

	# Central crown peak (stone only — no jewel ornament)
	var crown := Polygon2D.new()
	crown.polygon = PackedVector2Array([
		Vector2(-18, -138), Vector2(0, -172), Vector2(18, -138),
		Vector2(12, -130), Vector2(0, -146), Vector2(-12, -130)
	])
	crown.color = STONE_RIM
	crown.z_index = 2
	add_child(crown)
	var crown_lit := Polygon2D.new()
	crown_lit.polygon = PackedVector2Array([
		Vector2(-6, -142), Vector2(0, -166), Vector2(6, -142), Vector2(0, -150)
	])
	crown_lit.color = STONE_LIT
	crown_lit.z_index = 3
	add_child(crown_lit)


func _add_spire(origin: Vector2, scale: float, left: bool) -> void:
	var sx := -1.0 if left else 1.0
	var h := 98.0 * scale
	var w := 17.0 * scale
	# Organic stem
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		origin + Vector2(-w, 12),
		origin + Vector2(w, 12),
		origin + Vector2(w * 0.5, -h * 0.5),
		origin + Vector2(sx * w * 0.12, -h),
		origin + Vector2(-w * 0.4, -h * 0.45)
	])
	base.color = STONE
	base.z_index = 2
	add_child(base)
	var lit := Polygon2D.new()
	lit.polygon = PackedVector2Array([
		origin + Vector2(sx * -w * 0.15, 6),
		origin + Vector2(sx * w * 0.45, 4),
		origin + Vector2(sx * w * 0.28, -h * 0.52),
		origin + Vector2(sx * w * 0.05, -h * 0.9)
	])
	lit.color = STONE_LIT
	lit.z_index = 3
	add_child(lit)
	# Needle tip
	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([
		origin + Vector2(0, -h - 16 * scale),
		origin + Vector2(4 * scale, -h + 2),
		origin + Vector2(-4 * scale, -h + 2)
	])
	tip.color = STONE_RIM
	tip.z_index = 4
	add_child(tip)
	# Architectural balcony shelf
	var balc := Polygon2D.new()
	balc.polygon = PackedVector2Array([
		origin + Vector2(sx * -5, -h * 0.38),
		origin + Vector2(sx * 12, -h * 0.4),
		origin + Vector2(sx * 11, -h * 0.3),
		origin + Vector2(sx * -4, -h * 0.28)
	])
	balc.color = STONE_DEEP
	balc.z_index = 4
	add_child(balc)


func _build_chamber_arch() -> void:
	## Open chamber mouth — circular architecture framing the crystal.
	var hood := Polygon2D.new()
	hood.polygon = PackedVector2Array([
		Vector2(-48, -6), Vector2(48, -6), Vector2(42, -52), Vector2(20, -92),
		Vector2(0, -106), Vector2(-20, -92), Vector2(-42, -52)
	])
	hood.color = Color(0.12, 0.1, 0.14, 0.5)
	hood.z_index = 5
	add_child(hood)

	var mouth := Polygon2D.new()
	mouth.polygon = PackedVector2Array([
		Vector2(-34, 8), Vector2(34, 8), Vector2(30, -38), Vector2(14, -76),
		Vector2(0, -86), Vector2(-14, -76), Vector2(-30, -38)
	])
	mouth.color = Color(0.16, 0.14, 0.18, 0.32)
	mouth.z_index = 5
	add_child(mouth)

	for sx in [-1.0, 1.0]:
		var rib := Polygon2D.new()
		rib.polygon = PackedVector2Array([
			Vector2(sx * 32, 10), Vector2(sx * 40, 8), Vector2(sx * 36, -42),
			Vector2(sx * 18, -80), Vector2(sx * 10, -68), Vector2(sx * 26, -38)
		])
		rib.color = STONE_RIM
		rib.z_index = 6
		add_child(rib)

	# Structural keystone (plain stone wedge)
	var key := Polygon2D.new()
	key.polygon = PackedVector2Array([
		Vector2(-7, -98), Vector2(0, -110), Vector2(7, -98), Vector2(4, -88), Vector2(-4, -88)
	])
	key.color = STONE_LIT
	key.z_index = 7
	add_child(key)


func _build_crystal_gem() -> void:
	## Crystal of Truth — clear faceted gem suspended over the shaft (film read).
	_float_root = Node2D.new()
	_float_root.name = "FloatRoot"
	_float_root.position = Vector2(0, -28)
	_float_root.z_index = 10
	add_child(_float_root)

	_rim_glow = FX.make_ellipse_poly(34, 46, 22, Color(0.75, 0.7, 0.95, 0.16))
	_rim_glow.position = Vector2(0, -6)
	_rim_glow.z_index = -1
	_float_root.add_child(_rim_glow)

	var outline := Polygon2D.new()
	outline.polygon = _main_body_pts(1.12)
	outline.color = Color(0.12, 0.1, 0.16, 0.95)
	outline.z_index = 0
	_float_root.add_child(outline)

	_core = Polygon2D.new()
	_core.polygon = _main_body_pts(1.0)
	_core.color = Color(0.88, 0.86, 0.96, 1.0)
	_core.z_index = 1
	_float_root.add_child(_core)

	# Clear / cool facets — crystal light, not rainbow magic
	_add_facet([
		Vector2(0, -58), Vector2(-18, -38), Vector2(-12, -4), Vector2(0, 6)
	], Color(0.55, 0.62, 0.78, 0.8), 2)
	_add_facet([
		Vector2(0, -58), Vector2(18, -38), Vector2(14, -4), Vector2(0, 6)
	], Color(0.92, 0.9, 0.98, 0.75), 2)
	_add_facet([
		Vector2(-18, -38), Vector2(-26, -8), Vector2(-14, 16), Vector2(-6, -2)
	], Color(0.48, 0.45, 0.65, 0.78), 2)
	_add_facet([
		Vector2(18, -38), Vector2(26, -8), Vector2(14, 16), Vector2(6, -2)
	], Color(0.7, 0.68, 0.88, 0.72), 2)
	_add_facet([
		Vector2(0, -58), Vector2(10, -42), Vector2(0, -30), Vector2(-10, -42)
	], Color(0.98, 0.97, 1.0, 0.95), 3)
	_add_facet([
		Vector2(-8, 10), Vector2(0, 32), Vector2(8, 10), Vector2(0, -2)
	], Color(0.6, 0.58, 0.78, 0.6), 3)

	_heart = FX.make_ellipse_poly(6, 11, 12, Color(0.96, 0.94, 1.0, 0.95))
	_heart.position = Vector2(0, -4)
	_heart.z_index = 4
	_float_root.add_child(_heart)

	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([
		Vector2(0, -70), Vector2(6, -56), Vector2(0, -50), Vector2(-6, -56)
	])
	tip.color = Color(0.98, 0.96, 1.0, 0.98)
	tip.z_index = 4
	_float_root.add_child(tip)
	_facets.append(tip)


func _build_chamber_rail() -> void:
	## Foreground stone rail — architecture only.
	var ledge := Polygon2D.new()
	ledge.polygon = PackedVector2Array([
		Vector2(-48, 18), Vector2(48, 18), Vector2(44, 28), Vector2(-44, 28)
	])
	ledge.color = STONE_LIT
	ledge.z_index = 12
	add_child(ledge)

	var ledge_top := Polygon2D.new()
	ledge_top.polygon = PackedVector2Array([
		Vector2(-46, 14), Vector2(46, 14), Vector2(44, 20), Vector2(-44, 20)
	])
	ledge_top.color = STONE_RIM
	ledge_top.z_index = 13
	add_child(ledge_top)

	for x in [-32.0, -10.0, 10.0, 32.0]:
		var post := Polygon2D.new()
		post.polygon = PackedVector2Array([
			Vector2(x - 2.5, 8), Vector2(x + 2.5, 8), Vector2(x + 2, 22), Vector2(x - 2, 22)
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

	_float_y = -22.0 + sin(t * 1.05) * 5.0
	if _float_root:
		_float_root.position.y = _float_y
		_float_root.position.x = sin(t * 0.4) * 1.0
		_float_root.rotation = sin(t * 0.32) * 0.025

	if _shadow:
		var lift := clampf((-_float_y - 10.0) / 18.0, 0.0, 1.0)
		var sc := 1.0 - lift * 0.22
		_shadow.scale = Vector2(sc, sc)
		_shadow.modulate.a = 0.35 + (1.0 - lift) * 0.22

	if _shaft_glow:
		_shaft_glow.modulate.a = 0.72 + 0.22 * sin(t * 2.8)
		_shaft_glow.scale = Vector2(0.96 + 0.06 * sin(t * 2.2), 0.96 + 0.06 * cos(t * 2.4))

	for i in _fire_lobes.size():
		var lobe: Polygon2D = _fire_lobes[i]
		if not is_instance_valid(lobe):
			continue
		if str(lobe.name).begins_with("FireTongue"):
			lobe.modulate.a = 0.32 + 0.2 * sin(t * 3.5 + float(i))
			lobe.position.y = sin(t * 3.0 + float(i)) * 1.5
		elif str(lobe.name) == "FireCore":
			lobe.scale = Vector2.ONE * (0.92 + 0.1 * sin(t * 3.2))

	if _rim_glow:
		_rim_glow.modulate.a = 0.55 + 0.25 * sin(t * 1.6)
		# Soft crystal white-violet only
		_rim_glow.color = Color(0.72, 0.68, 0.92, 0.18)

	if _core:
		var pulse := 1.0 + 0.018 * sin(t * 2.0)
		_core.scale = Vector2(pulse, pulse)
		var healthy := Color(0.88, 0.86, 0.96, 1.0)
		var hurt := Color(0.8, 0.3, 0.35, 1.0)
		_core.color = healthy.lerp(hurt, 1.0 - _health_t)

	for i in _facets.size():
		var f: Polygon2D = _facets[i]
		if not is_instance_valid(f) or not f.has_meta("base_color"):
			continue
		var base: Color = f.get_meta("base_color")
		var wave := 0.78 + 0.22 * sin(t * 2.0 + float(i) * 0.8)
		f.color = Color(base.r, base.g, base.b, base.a * wave)

	if _heart:
		var hp := 1.0 + 0.08 * sin(t * 2.8)
		_heart.scale = Vector2(hp, hp)
		var pure := Color(0.96, 0.94, 1.0, 0.95)
		var dim := Color(0.7, 0.28, 0.32, 0.8)
		_heart.color = pure.lerp(dim, 1.0 - _health_t)

	if _hp_bar:
		_hp_bar.position = Vector2(-58, 112)


func _on_hp(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_health_t = float(current) / float(maxi(1, maximum))


func get_hurtbox_position() -> Vector2:
	return global_position
