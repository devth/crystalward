extends Node2D
class_name DefenseTower
## Auto-fires at nearest nightspawn; organic crystal turret look.

@export var fire_range: float = 160.0
@export var fire_rate: float = 0.55
@export var damage: int = 14

var _cd: float = 0.0
var _visual: Node2D
var _gem: Polygon2D
var _pulse: Polygon2D


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


func _build_visuals() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	FX.add_soft_shadow(_visual, 22, 10, 16)

	# Range whisper (very subtle)
	var range_ring := FX.make_ellipse_poly(fire_range * 0.45, fire_range * 0.28, 40, Color(0.9, 0.75, 0.4, 0.05))
	range_ring.z_index = -2
	_visual.add_child(range_ring)

	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-16, 12), Vector2(16, 12), Vector2(12, 2), Vector2(-12, 2)
	])
	base.color = Color(0.2, 0.22, 0.28)
	_visual.add_child(base)

	var stem := Polygon2D.new()
	stem.polygon = PackedVector2Array([
		Vector2(-8, 4), Vector2(8, 4), Vector2(6, -18), Vector2(-6, -18)
	])
	stem.color = Color(0.35, 0.42, 0.55)
	_visual.add_child(stem)

	# Moss wrap
	var moss := Polygon2D.new()
	moss.polygon = PackedVector2Array([
		Vector2(-10, 6), Vector2(-4, -4), Vector2(2, 2), Vector2(-6, 10)
	])
	moss.color = Color(0.28, 0.48, 0.38, 0.8)
	_visual.add_child(moss)

	_gem = Polygon2D.new()
	_gem.polygon = PackedVector2Array([
		Vector2(0, -40), Vector2(12, -24), Vector2(8, -10), Vector2(-8, -10), Vector2(-12, -24)
	])
	_gem.color = Color(0.85, 0.7, 0.4, 0.95)
	_visual.add_child(_gem)

	var gem_hi := Polygon2D.new()
	gem_hi.polygon = PackedVector2Array([
		Vector2(0, -40), Vector2(8, -26), Vector2(0, -18), Vector2(-4, -26)
	])
	gem_hi.color = Color(1.0, 0.95, 0.75, 0.55)
	_visual.add_child(gem_hi)

	_pulse = FX.make_ellipse_poly(16, 12, 18, Color(0.95, 0.8, 0.4, 0.15))
	_pulse.position = Vector2(0, -22)
	_visual.add_child(_pulse)

	FX.spark_particles(_visual, Color(0.95, 0.8, 0.45, 0.6), 8).position = Vector2(0, -22)


func _process(delta: float) -> void:
	if GameState.is_game_over:
		return
	var t := Time.get_ticks_msec() * 0.001
	if _gem:
		_gem.position.y = sin(t * 2.5) * 1.5
	if _pulse:
		_pulse.scale = Vector2.ONE * (1.0 + 0.15 * sin(t * 3.0))
		_pulse.modulate.a = 0.4 + 0.4 * sin(t * 3.0)

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
	line.width = 3.0
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.default_color = Color(0.95, 0.85, 0.45, 0.95)
	line.points = PackedVector2Array([Vector2(0, -22), to - global_position])
	line.z_index = 100
	add_child(line)

	# Impact spark at target end
	var impact := FX.make_ellipse_poly(6, 6, 10, Color(1.0, 0.9, 0.5, 0.8))
	impact.position = to - global_position
	impact.z_index = 101
	add_child(impact)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(line, "modulate:a", 0.0, 0.14)
	tw.tween_property(impact, "modulate:a", 0.0, 0.18)
	tw.tween_property(impact, "scale", Vector2(2.2, 2.2), 0.18)
	tw.chain().tween_callback(func() -> void:
		line.queue_free()
		impact.queue_free()
	)
