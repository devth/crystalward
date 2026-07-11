extends Node2D
## Lightwell / Crystal — epic ethereal anchor: floating core, golden shaft, radiating energy.

@onready var _hp_bar: ProgressBar = $HpBar

var _glow_layers: Array[CanvasItem] = []
var _float_root: Node2D
var _core: Polygon2D
var _heart: Polygon2D
var _shadow: Polygon2D
var _shaft_layers: Array[Polygon2D] = []
var _energy_rays: Array[Polygon2D] = []
var _pulse_rings: Array[Polygon2D] = []
var _health_t: float = 1.0
var _float_y: float = 0.0


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
	FX.style_progress_bar(_hp_bar, Color(0.95, 0.78, 0.4), Color(0.06, 0.06, 0.1, 0.9))
	_hp_bar.position = Vector2(-56, 72)
	_hp_bar.size = Vector2(112, 12)

	_spawn_energy_particles()


func _build_visuals() -> void:
	# Ground well — ethereal pool the crystal floats above
	var well_outer := FX.make_ellipse_poly(72, 32, 40, Color(0.12, 0.08, 0.18, 0.85))
	well_outer.position = Vector2(0, 28)
	well_outer.z_index = -6
	add_child(well_outer)

	var well_mid := FX.make_ellipse_poly(58, 26, 36, Color(0.22, 0.14, 0.32, 0.55))
	well_mid.position = Vector2(0, 28)
	well_mid.z_index = -5
	add_child(well_mid)
	_glow_layers.append(well_mid)

	var well_gold := FX.make_ellipse_poly(44, 20, 36, Color(0.95, 0.72, 0.32, 0.28))
	well_gold.position = Vector2(0, 28)
	well_gold.z_index = -4
	add_child(well_gold)
	_glow_layers.append(well_gold)

	var well_core := FX.make_ellipse_poly(22, 10, 28, Color(0.98, 0.9, 0.55, 0.35))
	well_core.position = Vector2(0, 28)
	well_core.z_index = -3
	add_child(well_core)
	_glow_layers.append(well_core)

	# Soft ground shadow (scales with float height)
	_shadow = FX.make_ellipse_poly(34, 12, 28, Color(0.05, 0.04, 0.1, 0.55))
	_shadow.position = Vector2(0, 30)
	_shadow.z_index = -2
	add_child(_shadow)

	# Golden light shaft from the heavens (behind floating crystal)
	_build_golden_shaft()

	# Soft radial energy corona on ground
	var corona := FX.make_ellipse_poly(90, 48, 40, Color(0.95, 0.75, 0.4, 0.08))
	corona.position = Vector2(0, 12)
	corona.z_index = -7
	add_child(corona)
	_glow_layers.append(corona)

	# Radiating energy rays (spin slowly)
	for i in 8:
		var ray := Polygon2D.new()
		var ang := TAU * float(i) / 8.0
		var len := 95.0 + float(i % 2) * 25.0
		ray.polygon = PackedVector2Array([
			Vector2(-5, 0), Vector2(5, 0),
			Vector2(3, -len), Vector2(-3, -len)
		])
		ray.color = Color(0.95, 0.78, 0.4, 0.1) if i % 2 == 0 else Color(0.7, 0.55, 0.95, 0.08)
		ray.rotation = ang
		ray.position = Vector2(0, -8)
		ray.z_index = -1
		ray.set_meta("base_ang", ang)
		ray.set_meta("len", len)
		add_child(ray)
		_energy_rays.append(ray)

	# Expanding pulse rings (energy radiating outward)
	for i in 3:
		var ring := FX.make_ellipse_poly(28 + i * 18, 14 + i * 8, 36, Color(0.95, 0.8, 0.45, 0.12 - i * 0.03))
		ring.position = Vector2(0, 18)
		ring.z_index = -3
		ring.set_meta("phase", float(i) * 0.85)
		add_child(ring)
		_pulse_rings.append(ring)

	# Floating crystal assembly
	_float_root = Node2D.new()
	_float_root.name = "FloatRoot"
	_float_root.position = Vector2(0, -18)
	_float_root.z_index = 2
	add_child(_float_root)

	# Soft aura around floating body
	var aura := FX.make_ellipse_poly(70, 90, 40, Color(0.95, 0.72, 0.35, 0.1))
	aura.position = Vector2(0, -8)
	_float_root.add_child(aura)
	_glow_layers.append(aura)

	var aura2 := FX.make_ellipse_poly(48, 64, 36, Color(0.55, 0.85, 0.95, 0.1))
	aura2.position = Vector2(0, -12)
	_float_root.add_child(aura2)
	_glow_layers.append(aura2)

	var aura3 := FX.make_ellipse_poly(32, 44, 32, Color(0.98, 0.88, 0.55, 0.14))
	aura3.position = Vector2(0, -10)
	_float_root.add_child(aura3)
	_glow_layers.append(aura3)

	# Outline shell
	var outline := Polygon2D.new()
	outline.polygon = PackedVector2Array([
		Vector2(0, -72), Vector2(22, -48), Vector2(34, -14), Vector2(26, 18),
		Vector2(12, 38), Vector2(0, 46), Vector2(-12, 36), Vector2(-28, 16),
		Vector2(-36, -12), Vector2(-24, -48)
	])
	outline.color = Color(0.12, 0.1, 0.18, 0.92)
	outline.scale = Vector2(1.1, 1.1)
	outline.z_index = -1
	_float_root.add_child(outline)

	# Main crystal body — taller, more faceted lightwell
	_core = Polygon2D.new()
	_core.polygon = PackedVector2Array([
		Vector2(0, -68), Vector2(20, -46), Vector2(32, -12), Vector2(24, 16),
		Vector2(10, 34), Vector2(0, 42), Vector2(-10, 32), Vector2(-26, 14),
		Vector2(-34, -10), Vector2(-22, -46)
	])
	_core.color = Color(0.72, 0.55, 0.95, 0.98)
	_float_root.add_child(_core)

	# Facets — cool cyan + warm gold highlights
	var facet_l := Polygon2D.new()
	facet_l.polygon = PackedVector2Array([
		Vector2(0, -68), Vector2(-22, -46), Vector2(-12, -4), Vector2(0, 8)
	])
	facet_l.color = Color(0.45, 0.72, 0.7, 0.5)
	_float_root.add_child(facet_l)

	var facet_r := Polygon2D.new()
	facet_r.polygon = PackedVector2Array([
		Vector2(0, -68), Vector2(20, -46), Vector2(24, -2), Vector2(0, 8)
	])
	facet_r.color = Color(0.85, 0.95, 1.0, 0.42)
	_float_root.add_child(facet_r)

	var facet_gold := Polygon2D.new()
	facet_gold.polygon = PackedVector2Array([
		Vector2(0, -68), Vector2(10, -50), Vector2(6, -20), Vector2(0, -8), Vector2(-8, -22)
	])
	facet_gold.color = Color(0.98, 0.88, 0.5, 0.35)
	_float_root.add_child(facet_gold)

	var facet_top := Polygon2D.new()
	facet_top.polygon = PackedVector2Array([
		Vector2(0, -68), Vector2(12, -50), Vector2(0, -36), Vector2(-12, -50)
	])
	facet_top.color = Color(1.0, 0.98, 0.9, 0.85)
	_float_root.add_child(facet_top)

	# Inner heart — molten amber core
	_heart = FX.make_ellipse_poly(10, 18, 18, Color(0.98, 0.88, 0.5, 0.9))
	_heart.position = Vector2(0, -10)
	_float_root.add_child(_heart)
	_glow_layers.append(_heart)

	var heart_hot := FX.make_ellipse_poly(5, 9, 14, Color(1.0, 0.95, 0.75, 0.95))
	heart_hot.position = Vector2(0, -12)
	_float_root.add_child(heart_hot)
	_glow_layers.append(heart_hot)

	# Crown tip crystal
	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([
		Vector2(0, -78), Vector2(8, -64), Vector2(0, -56), Vector2(-8, -64)
	])
	tip.color = Color(0.95, 0.85, 0.55, 0.9)
	_float_root.add_child(tip)

	# Orbiting ethereal shards around the floating core
	for i in 7:
		var shard := Polygon2D.new()
		var ang := TAU * float(i) / 7.0
		var dist := 40.0 + float(i % 3) * 10.0
		shard.position = Vector2(cos(ang), sin(ang) * 0.55) * dist + Vector2(0, -14)
		shard.polygon = PackedVector2Array([
			Vector2(0, -9), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0)
		])
		if i % 3 == 0:
			shard.color = Color(0.95, 0.8, 0.4, 0.7)
		elif i % 3 == 1:
			shard.color = Color(0.6, 0.9, 0.95, 0.65)
		else:
			shard.color = Color(0.8, 0.55, 1.0, 0.6)
		shard.set_meta("orbit", ang)
		shard.set_meta("dist", dist)
		shard.set_meta("bob", rng_phase(i))
		shard.name = "Shard%d" % i
		_float_root.add_child(shard)

	# Soft vines cradling the well (grounded, not floating)
	for side in [-1.0, 1.0]:
		var vine := Line2D.new()
		vine.width = 3.0
		vine.default_color = Color(0.22, 0.48, 0.36, 0.85)
		vine.points = PackedVector2Array([
			Vector2(side * 28, 36),
			Vector2(side * 40, 14),
			Vector2(side * 36, -8),
			Vector2(side * 22, -24),
		])
		vine.z_index = 0
		add_child(vine)
		var bloom := FX.make_ellipse_poly(5, 4, 10, Color(0.95, 0.75, 0.4, 0.55))
		bloom.position = Vector2(side * 22, -24)
		add_child(bloom)


func _build_golden_shaft() -> void:
	## Soft vertical column of golden light bathing the crystal.
	# Wide outer shaft (very soft)
	var outer := Polygon2D.new()
	outer.polygon = PackedVector2Array([
		Vector2(-48, -220), Vector2(48, -220),
		Vector2(28, 40), Vector2(-28, 40)
	])
	outer.color = Color(0.95, 0.78, 0.4, 0.06)
	outer.z_index = -8
	add_child(outer)
	_shaft_layers.append(outer)
	_glow_layers.append(outer)

	# Mid shaft
	var mid := Polygon2D.new()
	mid.polygon = PackedVector2Array([
		Vector2(-26, -200), Vector2(26, -200),
		Vector2(16, 36), Vector2(-16, 36)
	])
	mid.color = Color(0.98, 0.85, 0.5, 0.1)
	mid.z_index = -7
	add_child(mid)
	_shaft_layers.append(mid)
	_glow_layers.append(mid)

	# Bright core shaft
	var core_shaft := Polygon2D.new()
	core_shaft.polygon = PackedVector2Array([
		Vector2(-10, -180), Vector2(10, -180),
		Vector2(7, 32), Vector2(-7, 32)
	])
	core_shaft.color = Color(1.0, 0.95, 0.7, 0.16)
	core_shaft.z_index = -6
	add_child(core_shaft)
	_shaft_layers.append(core_shaft)
	_glow_layers.append(core_shaft)

	# Top bloom of light (where shaft enters frame)
	var top_bloom := FX.make_ellipse_poly(40, 18, 28, Color(1.0, 0.92, 0.6, 0.18))
	top_bloom.position = Vector2(0, -190)
	top_bloom.z_index = -5
	add_child(top_bloom)
	_glow_layers.append(top_bloom)

	# Secondary soft diagonal rays (god-ray feel)
	for i in 3:
		var ray := Polygon2D.new()
		var lean := -0.35 + float(i) * 0.35
		ray.polygon = PackedVector2Array([
			Vector2(-6 + lean * 20.0, -160),
			Vector2(6 + lean * 20.0, -160),
			Vector2(18 + lean * 80.0, 30),
			Vector2(-18 + lean * 80.0, 30)
		])
		ray.color = Color(0.95, 0.78, 0.42, 0.05 + float(i) * 0.01)
		ray.z_index = -8
		add_child(ray)
		_shaft_layers.append(ray)
		_glow_layers.append(ray)


func _spawn_energy_particles() -> void:
	if FX == null:
		return
	# Rising golden energy from the well
	var rise := FX.spark_particles(self, Color(0.98, 0.85, 0.45, 0.65), 22, "glow")
	rise.position = Vector2(0, 20)
	rise.z_index = 4
	rise.lifetime = 2.2
	rise.amount = 22
	var pm := rise.process_material as ParticleProcessMaterial
	if pm:
		pm.direction = Vector3(0, -1, 0)
		pm.spread = 28.0
		pm.initial_velocity_min = 18.0
		pm.initial_velocity_max = 48.0
		pm.gravity = Vector3(0, -12.0, 0)
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 22.0
		pm.scale_min = 0.4
		pm.scale_max = 1.1

	# Orbiting cyan/violet motes around the floating crystal
	var orbit := FX.spark_particles(self, Color(0.65, 0.9, 0.98, 0.55), 16, "star")
	orbit.position = Vector2(0, -20)
	orbit.z_index = 5
	orbit.lifetime = 2.8
	orbit.amount = 16
	var pm2 := orbit.process_material as ParticleProcessMaterial
	if pm2:
		pm2.direction = Vector3(0, -1, 0)
		pm2.spread = 180.0
		pm2.initial_velocity_min = 4.0
		pm2.initial_velocity_max = 18.0
		pm2.gravity = Vector3(0, -2.0, 0)
		pm2.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm2.emission_sphere_radius = 38.0

	# Soft outward radiation pulses
	var radiate := FX.spark_particles(self, Color(0.95, 0.75, 0.4, 0.4), 12, "magic")
	radiate.position = Vector2(0, 0)
	radiate.z_index = 3
	radiate.lifetime = 1.8
	radiate.amount = 12
	var pm3 := radiate.process_material as ParticleProcessMaterial
	if pm3:
		pm3.direction = Vector3(0, -1, 0)
		pm3.spread = 180.0
		pm3.initial_velocity_min = 12.0
		pm3.initial_velocity_max = 36.0
		pm3.gravity = Vector3(0, 0, 0)
		pm3.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm3.emission_sphere_radius = 8.0


func rng_phase(i: int) -> float:
	return float(i) * 1.37


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001

	# Magical float bob
	_float_y = -14.0 + sin(t * 1.35) * 7.0 + sin(t * 2.7) * 2.0
	if _float_root:
		_float_root.position.y = _float_y
		_float_root.position.x = sin(t * 0.7) * 1.5
		_float_root.rotation = sin(t * 0.55) * 0.035

	# Shadow shrinks slightly as crystal lifts
	if _shadow:
		var lift := clampf((-_float_y - 8.0) / 20.0, 0.0, 1.0)
		var sc := 1.05 - lift * 0.25
		_shadow.scale = Vector2(sc, sc)
		_shadow.modulate.a = 0.45 + (1.0 - lift) * 0.25

	# Glow breathe
	for layer in _glow_layers:
		if is_instance_valid(layer):
			var phase := float(layer.get_instance_id() % 11) * 0.4
			layer.modulate.a = 0.65 + 0.35 * sin(t * 2.0 + phase)

	# Core pulse + health tint (healthy = ethereal violet/gold, hurt = crimson)
	if _core:
		var pulse := 1.0 + 0.04 * sin(t * 2.8) + 0.02 * sin(t * 5.5)
		_core.scale = Vector2(pulse, pulse)
		var healthy := Color(0.72, 0.55, 0.95)
		var hurt := Color(0.8, 0.18, 0.28)
		_core.color = healthy.lerp(hurt, 1.0 - _health_t)

	if _heart:
		var hp := 1.0 + 0.12 * sin(t * 4.2)
		_heart.scale = Vector2(hp, hp * 1.05)
		var gold := Color(0.98, 0.88, 0.5, 0.9)
		var dim := Color(0.7, 0.25, 0.3, 0.75)
		_heart.color = gold.lerp(dim, 1.0 - _health_t)

	# Golden shaft gently breathes and sways
	for i in _shaft_layers.size():
		var s := _shaft_layers[i]
		if not is_instance_valid(s):
			continue
		var phase := float(i) * 0.6
		s.modulate.a = 0.7 + 0.3 * sin(t * 1.4 + phase)
		if i < 3:
			s.scale.x = 1.0 + 0.06 * sin(t * 1.1 + phase)

	# Energy rays spin slowly
	for i in _energy_rays.size():
		var ray := _energy_rays[i]
		if not is_instance_valid(ray):
			continue
		var base: float = ray.get_meta("base_ang")
		ray.rotation = base + t * 0.22
		ray.modulate.a = 0.55 + 0.45 * sin(t * 1.8 + float(i))

	# Pulse rings expand and fade in a loop
	for ring in _pulse_rings:
		if not is_instance_valid(ring):
			continue
		var phase: float = ring.get_meta("phase")
		var cycle := fposmod(t * 0.55 + phase, 1.0)
		var sc := 0.6 + cycle * 1.8
		ring.scale = Vector2(sc, sc * 0.55)
		ring.modulate.a = (1.0 - cycle) * (0.35 + 0.25 * _health_t)

	# Orbit shards around float root
	if _float_root:
		for c in _float_root.get_children():
			if c is Polygon2D and str(c.name).begins_with("Shard"):
				var ang: float = c.get_meta("orbit") + t * 0.85
				var dist: float = c.get_meta("dist")
				var bob: float = c.get_meta("bob")
				c.position = Vector2(cos(ang), sin(ang) * 0.5) * dist + Vector2(0, -10 + sin(t * 2.2 + bob) * 4.0)
				c.rotation = ang + t * 0.5
				c.modulate.a = 0.55 + 0.35 * sin(t * 3.0 + bob)

	# Keep hp bar readable (don't float away with crystal)
	if _hp_bar:
		_hp_bar.position = Vector2(-56, 72)


func _on_hp(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_health_t = float(current) / float(maxi(1, maximum))


func get_hurtbox_position() -> Vector2:
	return global_position
