extends Node2D
class_name DefenseTower
## Living tree-tower — PixelJunk-style readable silhouette + auto-fire.

@export var fire_range: float = 170.0
@export var fire_rate: float = 0.5
@export var damage: int = 15

var _cd: float = 0.0
var _visual: Node2D
var _canopy: Polygon2D
var _gem: Polygon2D
var _pulse: Polygon2D
var _bob: float = 0.0


func _ready() -> void:
	add_to_group("towers")
	z_index = int(global_position.y)
	if has_node("Body"):
		$Body.visible = false
	if has_node("RangeHint"):
		$RangeHint.visible = false
	if has_node("CrystalTip"):
		$CrystalTip.visible = false
	_build_visuals()
	_bob = randf() * TAU


func _build_visuals() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	if VisualStyle:
		VisualStyle.make_blob_shadow(_visual, 24, 10, 14)
	else:
		FX.add_soft_shadow(_visual, 24, 10, 14)

	# Soft range disc (very light)
	var range_ring := FX.make_ellipse_poly(fire_range * 0.42, fire_range * 0.26, 40, Color(0.95, 0.85, 0.4, 0.06))
	range_ring.z_index = -2
	_visual.add_child(range_ring)

	# Trunk
	var trunk := Polygon2D.new()
	trunk.polygon = PackedVector2Array([
		Vector2(-10, 14), Vector2(10, 14), Vector2(8, -8), Vector2(4, -28),
		Vector2(-4, -28), Vector2(-8, -8)
	])
	trunk.color = Color(0.42, 0.28, 0.18)
	_visual.add_child(trunk)
	var trunk_hi := Polygon2D.new()
	trunk_hi.polygon = PackedVector2Array([
		Vector2(-4, 10), Vector2(2, 10), Vector2(0, -24), Vector2(-5, -20)
	])
	trunk_hi.color = Color(0.55, 0.38, 0.24, 0.7)
	_visual.add_child(trunk_hi)

	# Leaf canopy — bold rounded blobs (PJ tower vibe)
	_canopy = Polygon2D.new()
	_canopy.polygon = PackedVector2Array([
		Vector2(0, -58), Vector2(22, -48), Vector2(28, -28), Vector2(18, -14),
		Vector2(0, -10), Vector2(-18, -14), Vector2(-28, -28), Vector2(-22, -48)
	])
	_canopy.color = Color(0.32, 0.58, 0.38)
	_visual.add_child(_canopy)
	var canopy2 := Polygon2D.new()
	canopy2.polygon = PackedVector2Array([
		Vector2(-6, -52), Vector2(14, -44), Vector2(10, -24), Vector2(-12, -28)
	])
	canopy2.color = Color(0.45, 0.72, 0.48, 0.85)
	_visual.add_child(canopy2)

	# Crystal fruit in canopy
	_gem = Polygon2D.new()
	_gem.polygon = PackedVector2Array([
		Vector2(0, -46), Vector2(8, -34), Vector2(0, -28), Vector2(-8, -34)
	])
	_gem.color = Color(0.95, 0.8, 0.45)
	_visual.add_child(_gem)
	var gem_hi := Polygon2D.new()
	gem_hi.polygon = PackedVector2Array([Vector2(-2, -42), Vector2(3, -38), Vector2(-1, -34)])
	gem_hi.color = Color(1, 0.98, 0.85, 0.75)
	_visual.add_child(gem_hi)

	_pulse = FX.make_ellipse_poly(18, 14, 18, Color(0.95, 0.85, 0.4, 0.18))
	_pulse.position = Vector2(0, -36)
	_visual.add_child(_pulse)

	FX.spark_particles(_visual, Color(0.95, 0.85, 0.5, 0.65), 10, "glow").position = Vector2(0, -36)


func _process(delta: float) -> void:
	if GameState.is_game_over:
		return
	_bob += delta
	if _visual:
		_visual.position.y = sin(_bob * 1.8) * 1.5
		_visual.rotation = sin(_bob * 0.9) * 0.03
	if _gem:
		_gem.position.y = sin(_bob * 2.5) * 1.2
	if _pulse:
		_pulse.scale = Vector2.ONE * (1.0 + 0.12 * sin(_bob * 3.0))
		_pulse.modulate.a = 0.35 + 0.4 * sin(_bob * 3.0)

	_cd = maxf(0.0, _cd - delta)
	if _cd > 0.0:
		return
	var target := _find_target()
	if target:
		_cd = fire_rate
		if target.has_method("take_damage"):
			target.take_damage(damage)
		_muzzle_flash(target.global_position)


func _find_target() -> Node2D:
	var best: Node2D = null
	var best_d := fire_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D:
			var d: float = global_position.distance_to(e.global_position)
			if d < best_d:
				best_d = d
				best = e
	return best


func _muzzle_flash(to: Vector2) -> void:
	var line := Line2D.new()
	line.width = 4.0
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.default_color = Color(1.0, 0.92, 0.55, 0.95)
	line.points = PackedVector2Array([Vector2(0, -36), to - global_position])
	line.z_index = 100
	add_child(line)
	var impact := FX.make_ellipse_poly(8, 8, 12, Color(1.0, 0.95, 0.6, 0.85))
	impact.position = to - global_position
	impact.z_index = 101
	add_child(impact)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(line, "modulate:a", 0.0, 0.14)
	tw.tween_property(impact, "modulate:a", 0.0, 0.18)
	tw.tween_property(impact, "scale", Vector2(2.4, 2.4), 0.18)
	tw.chain().tween_callback(func() -> void:
		line.queue_free()
		impact.queue_free()
	)
