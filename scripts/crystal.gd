extends Node2D
## Lightwell / Crystal — shared lose condition + rich VFX.

@onready var _hp_bar: ProgressBar = $HpBar

var _glow_layers: Array[CanvasItem] = []
var _core: Polygon2D
var _shaft: Polygon2D
var _health_t: float = 1.0


func _ready() -> void:
	add_to_group("crystal")
	# Remove old simple polygons if present
	if has_node("Glow"):
		$Glow.queue_free()
	if has_node("Core"):
		$Core.queue_free()

	_build_visuals()
	GameState.crystal_hp_changed.connect(_on_hp)
	_on_hp(GameState.crystal_hp, GameState.crystal_max_hp)
	z_index = int(global_position.y)
	FX.style_progress_bar(_hp_bar, Color(0.85, 0.65, 0.95), Color(0.08, 0.05, 0.12, 0.9))
	_hp_bar.position = Vector2(-52, 62)
	_hp_bar.size = Vector2(104, 12)

	FX.spark_particles(self, Color(0.45, 0.78, 0.95, 0.85), 22, "glow")
	var dust := FX.spark_particles(self, Color(0.55, 0.8, 0.55, 0.7), 12, "star")
	dust.position = Vector2(0, -20)


func _build_visuals() -> void:
	FX.add_soft_shadow(self, 36, 14, 28)

	# Ground well ring
	var well := FX.make_ellipse_poly(48, 22, 36, Color(0.15, 0.12, 0.22, 0.8))
	well.position = Vector2(0, 18)
	well.z_index = -1
	add_child(well)
	var well_rim := FX.make_ellipse_poly(52, 24, 36, Color(0.45, 0.3, 0.65, 0.25))
	well_rim.position = Vector2(0, 18)
	well_rim.z_index = -1
	add_child(well_rim)

	# Optional DawnLike / dark fantasy object under procedural glow (pixel crystal flesh)
	var obj_tex: Texture2D = AssetPaths.atlas_region(AssetPaths.DAWNLIKE_TREE0, Rect2(0, 0, 16, 32))
	if obj_tex == null:
		obj_tex = AssetPaths.atlas_region(AssetPaths.DARK_FANTASY_ITEMS, Rect2(0, 0, 24, 24))
	if obj_tex:
		var base_spr := AssetPaths.make_pixel_sprite(obj_tex, 3.0)
		base_spr.position = Vector2(0, 6)
		base_spr.modulate = Color(0.55, 0.4, 0.75, 0.55)
		base_spr.z_index = -1
		add_child(base_spr)

	# Outer aura (shader-ish via soft polys)
	var aura := FX.make_ellipse_poly(70, 90, 40, Color(0.5, 0.3, 0.8, 0.14))
	aura.position = Vector2(0, -20)
	add_child(aura)
	_glow_layers.append(aura)

	var aura2 := FX.make_ellipse_poly(48, 64, 36, Color(0.3, 0.6, 0.5, 0.12))
	aura2.position = Vector2(0, -16)
	add_child(aura2)
	_glow_layers.append(aura2)

	# Crystal body — irregular facets
	_core = Polygon2D.new()
	_core.polygon = PackedVector2Array([
		Vector2(0, -56), Vector2(18, -36), Vector2(28, -8), Vector2(18, 22),
		Vector2(6, 36), Vector2(-8, 34), Vector2(-22, 18), Vector2(-30, -6),
		Vector2(-20, -34)
	])
	_core.color = Color(0.55, 0.82, 0.95, 0.98)
	add_child(_core)
	# Bold outline rings for silhouette (PJ readability)
	var outline := _core.duplicate() as Polygon2D
	outline.color = Color(0.12, 0.08, 0.16, 0.85)
	outline.scale = Vector2(1.08, 1.08)
	outline.z_index = -1
	add_child(outline)
	move_child(outline, _core.get_index())

	var facet_l := Polygon2D.new()
	facet_l.polygon = PackedVector2Array([
		Vector2(0, -56), Vector2(-20, -34), Vector2(-8, 0), Vector2(0, 10)
	])
	facet_l.color = Color(0.45, 0.7, 0.6, 0.55)
	add_child(facet_l)

	var facet_r := Polygon2D.new()
	facet_r.polygon = PackedVector2Array([
		Vector2(0, -56), Vector2(18, -36), Vector2(22, 0), Vector2(0, 10)
	])
	facet_r.color = Color(0.45, 0.75, 0.9, 0.4)
	add_child(facet_r)

	var facet_top := Polygon2D.new()
	facet_top.polygon = PackedVector2Array([
		Vector2(0, -56), Vector2(10, -40), Vector2(0, -28), Vector2(-10, -40)
	])
	facet_top.color = Color(0.85, 0.92, 0.98, 0.7)
	add_child(facet_top)

	# Inner light
	var heart := FX.make_ellipse_poly(8, 14, 16, Color(0.75, 0.9, 1.0, 0.85))
	heart.position = Vector2(0, -8)
	add_child(heart)
	_glow_layers.append(heart)

	# Light shaft
	_shaft = Polygon2D.new()
	_shaft.polygon = PackedVector2Array([
		Vector2(-6, -70), Vector2(6, -70), Vector2(14, 40), Vector2(-14, 40)
	])
	_shaft.color = Color(0.45, 0.7, 0.85, 0.12)
	_shaft.z_index = -1
	add_child(_shaft)
	_glow_layers.append(_shaft)

	# Floating shards
	for i in 5:
		var shard := Polygon2D.new()
		var ang := TAU * float(i) / 5.0
		var dist := 34.0 + (i % 2) * 8.0
		shard.position = Vector2(cos(ang), sin(ang) * 0.6) * dist + Vector2(0, -12)
		shard.polygon = PackedVector2Array([
			Vector2(0, -7), Vector2(4, 0), Vector2(0, 5), Vector2(-4, 0)
		])
		shard.color = Color(0.55, 0.78, 0.65, 0.55) if i % 2 == 0 else Color(0.5, 0.72, 0.88, 0.5)
		shard.set_meta("orbit", ang)
		shard.set_meta("dist", dist)
		shard.name = "Shard%d" % i
		add_child(shard)

	# Thorns cradling the well
	for side in [-1, 1]:
		var vine := Line2D.new()
		vine.width = 3.0
		vine.default_color = Color(0.25, 0.5, 0.38, 0.9)
		vine.points = PackedVector2Array([
			Vector2(side * 20, 28),
			Vector2(side * 32, 8),
			Vector2(side * 28, -18),
			Vector2(side * 16, -36),
		])
		add_child(vine)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for layer in _glow_layers:
		if is_instance_valid(layer):
			layer.modulate.a = 0.7 + 0.3 * sin(t * 2.1 + layer.get_instance_id() % 7)
	if _core:
		var pulse := 1.0 + 0.03 * sin(t * 3.0)
		_core.scale = Vector2(pulse, pulse)
		var healthy := Color(0.72, 0.55, 0.95)
		var hurt := Color(0.75, 0.2, 0.3)
		_core.color = healthy.lerp(hurt, 1.0 - _health_t)

	# Orbit shards
	for c in get_children():
		if c is Polygon2D and str(c.name).begins_with("Shard"):
			var ang: float = c.get_meta("orbit") + t * 0.7
			var dist: float = c.get_meta("dist")
			c.position = Vector2(cos(ang), sin(ang) * 0.55) * dist + Vector2(0, -12 + sin(t * 2.0 + ang) * 3.0)
			c.rotation = ang


func _on_hp(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_health_t = float(current) / float(maxi(1, maximum))


func get_hurtbox_position() -> Vector2:
	return global_position
