extends Node2D
## Lightwell / Crystal — clear faceted anchor. Shape first, glow second.

@onready var _hp_bar: ProgressBar = $HpBar

var _float_root: Node2D
var _core: Polygon2D
var _heart: Polygon2D
var _shadow: Polygon2D
var _rim_glow: Polygon2D
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
	FX.style_progress_bar(_hp_bar, Color(0.95, 0.82, 0.45), Color(0.08, 0.07, 0.12, 0.9))
	_hp_bar.position = Vector2(-48, 58)
	_hp_bar.size = Vector2(96, 11)


func _build_visuals() -> void:
	# Stone well base — readable ring, not a fog disc
	var well_shadow := FX.make_ellipse_poly(48, 20, 28, Color(0.08, 0.06, 0.12, 0.55))
	well_shadow.position = Vector2(0, 26)
	well_shadow.z_index = -4
	add_child(well_shadow)

	var well := FX.make_ellipse_poly(40, 16, 28, Color(0.22, 0.18, 0.28, 0.9))
	well.position = Vector2(0, 24)
	well.z_index = -3
	add_child(well)

	var well_rim := FX.make_ellipse_poly(36, 14, 26, Color(0.38, 0.32, 0.42, 0.85))
	well_rim.position = Vector2(0, 22)
	well_rim.z_index = -2
	add_child(well_rim)

	# Tiny warm pool inside the well (not a huge corona)
	var pool := FX.make_ellipse_poly(18, 8, 18, Color(0.95, 0.78, 0.4, 0.35))
	pool.position = Vector2(0, 22)
	pool.z_index = -1
	add_child(pool)

	_shadow = FX.make_ellipse_poly(22, 8, 18, Color(0.06, 0.04, 0.1, 0.5))
	_shadow.position = Vector2(0, 28)
	_shadow.z_index = -1
	add_child(_shadow)

	# Thin soft shaft behind crystal (very low alpha — does not wash the form)
	var shaft := Polygon2D.new()
	shaft.polygon = PackedVector2Array([
		Vector2(-8, -140), Vector2(8, -140), Vector2(5, 20), Vector2(-5, 20)
	])
	shaft.color = Color(1.0, 0.92, 0.65, 0.08)
	shaft.z_index = -5
	add_child(shaft)

	# Floating crystal — hard facets + dark outline
	_float_root = Node2D.new()
	_float_root.name = "FloatRoot"
	_float_root.position = Vector2(0, -10)
	_float_root.z_index = 4
	add_child(_float_root)

	# Small rim glow *behind* facets only
	_rim_glow = FX.make_ellipse_poly(22, 30, 20, Color(0.95, 0.85, 0.55, 0.18))
	_rim_glow.position = Vector2(0, -8)
	_rim_glow.z_index = -1
	_float_root.add_child(_rim_glow)

	# Dark outline shell for silhouette
	var outline := Polygon2D.new()
	outline.polygon = PackedVector2Array([
		Vector2(0, -58), Vector2(18, -38), Vector2(26, -8), Vector2(18, 18),
		Vector2(6, 30), Vector2(0, 34), Vector2(-6, 30), Vector2(-18, 16),
		Vector2(-26, -8), Vector2(-18, -38)
	])
	outline.color = Color(0.1, 0.08, 0.14, 0.95)
	outline.scale = Vector2(1.12, 1.12)
	outline.z_index = 0
	_float_root.add_child(outline)

	# Main body — solid, opaque, readable
	_core = Polygon2D.new()
	_core.polygon = PackedVector2Array([
		Vector2(0, -54), Vector2(16, -36), Vector2(24, -8), Vector2(16, 16),
		Vector2(5, 28), Vector2(0, 32), Vector2(-5, 28), Vector2(-16, 14),
		Vector2(-24, -8), Vector2(-16, -36)
	])
	_core.color = Color(0.72, 0.82, 0.95, 1.0)
	_core.z_index = 1
	_float_root.add_child(_core)

	# Facets — clear planar cuts
	var facet_l := Polygon2D.new()
	facet_l.polygon = PackedVector2Array([
		Vector2(0, -54), Vector2(-16, -36), Vector2(-10, -2), Vector2(0, 6)
	])
	facet_l.color = Color(0.45, 0.65, 0.82, 0.85)
	facet_l.z_index = 2
	_float_root.add_child(facet_l)

	var facet_r := Polygon2D.new()
	facet_r.polygon = PackedVector2Array([
		Vector2(0, -54), Vector2(16, -36), Vector2(18, -2), Vector2(0, 6)
	])
	facet_r.color = Color(0.9, 0.96, 1.0, 0.75)
	facet_r.z_index = 2
	_float_root.add_child(facet_r)

	var facet_gold := Polygon2D.new()
	facet_gold.polygon = PackedVector2Array([
		Vector2(0, -54), Vector2(8, -40), Vector2(4, -16), Vector2(0, -6), Vector2(-6, -18)
	])
	facet_gold.color = Color(0.98, 0.9, 0.55, 0.55)
	facet_gold.z_index = 3
	_float_root.add_child(facet_gold)

	var facet_top := Polygon2D.new()
	facet_top.polygon = PackedVector2Array([
		Vector2(0, -54), Vector2(9, -40), Vector2(0, -28), Vector2(-9, -40)
	])
	facet_top.color = Color(1.0, 0.98, 0.92, 0.95)
	facet_top.z_index = 3
	_float_root.add_child(facet_top)

	# Amber heart (small, inside body)
	_heart = FX.make_ellipse_poly(6, 11, 12, Color(0.98, 0.85, 0.4, 0.95))
	_heart.position = Vector2(0, -6)
	_heart.z_index = 4
	_float_root.add_child(_heart)

	# Crown tip
	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([
		Vector2(0, -64), Vector2(6, -52), Vector2(0, -46), Vector2(-6, -52)
	])
	tip.color = Color(0.98, 0.92, 0.65, 0.98)
	tip.z_index = 4
	_float_root.add_child(tip)

	# Two small orbiting shards only (secondary, not clutter)
	for i in 2:
		var shard := Polygon2D.new()
		var ang := float(i) * PI + 0.4
		shard.polygon = PackedVector2Array([
			Vector2(0, -7), Vector2(4, 0), Vector2(0, 5), Vector2(-4, 0)
		])
		shard.color = Color(0.85, 0.92, 1.0, 0.8) if i == 0 else Color(0.95, 0.85, 0.5, 0.8)
		shard.set_meta("orbit", ang)
		shard.set_meta("dist", 34.0)
		shard.name = "Shard%d" % i
		shard.z_index = 5
		_float_root.add_child(shard)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001

	_float_y = -8.0 + sin(t * 1.2) * 4.0
	if _float_root:
		_float_root.position.y = _float_y
		_float_root.position.x = sin(t * 0.55) * 1.0
		_float_root.rotation = sin(t * 0.45) * 0.025

	if _shadow:
		var lift := clampf((-_float_y - 4.0) / 16.0, 0.0, 1.0)
		var sc := 1.0 - lift * 0.2
		_shadow.scale = Vector2(sc, sc)
		_shadow.modulate.a = 0.4 + (1.0 - lift) * 0.2

	if _rim_glow:
		_rim_glow.modulate.a = 0.7 + 0.3 * sin(t * 1.8)

	if _core:
		var pulse := 1.0 + 0.02 * sin(t * 2.4)
		_core.scale = Vector2(pulse, pulse)
		var healthy := Color(0.72, 0.82, 0.95, 1.0)
		var hurt := Color(0.85, 0.28, 0.35, 1.0)
		_core.color = healthy.lerp(hurt, 1.0 - _health_t)

	if _heart:
		var hp := 1.0 + 0.08 * sin(t * 3.5)
		_heart.scale = Vector2(hp, hp)
		var gold := Color(0.98, 0.85, 0.4, 0.95)
		var dim := Color(0.75, 0.3, 0.3, 0.8)
		_heart.color = gold.lerp(dim, 1.0 - _health_t)

	if _float_root:
		for c in _float_root.get_children():
			if c is Polygon2D and str(c.name).begins_with("Shard"):
				var ang: float = c.get_meta("orbit") + t * 0.65
				var dist: float = c.get_meta("dist")
				c.position = Vector2(cos(ang), sin(ang) * 0.5) * dist + Vector2(0, -6)
				c.rotation = ang

	if _hp_bar:
		_hp_bar.position = Vector2(-48, 58)


func _on_hp(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_health_t = float(current) / float(maxi(1, maximum))


func get_hurtbox_position() -> Vector2:
	return global_position
