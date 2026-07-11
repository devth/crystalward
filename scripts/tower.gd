extends Node2D
class_name DefenseTower
## Living tree-tower with KR-style levels, range ring, sell value.

@export var fire_range: float = 170.0
@export var fire_rate: float = 0.5
@export var damage: int = 15

var level: int = 1
var invested_essence: int = 0
var _cd: float = 0.0
var _visual: Node2D
var _canopy: Polygon2D
var _gem: Polygon2D
var _pulse: Polygon2D
var _range_ring: Polygon2D
var _level_label: Label
var _bob: float = 0.0
var show_range: bool = false


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
	set_range_visible(false)


func set_invested(amount: int) -> void:
	invested_essence = amount


func sell_value() -> int:
	return int(float(invested_essence) * GameState.TOWER_SELL_REFUND)


func set_range_visible(v: bool) -> void:
	show_range = v
	if _range_ring:
		_range_ring.visible = v


func try_upgrade() -> bool:
	if level >= GameState.TOWER_MAX_LEVEL:
		GameState.message.emit("Tower max level")
		return false
	if not GameState.try_spend_essence(GameState.TOWER_UPGRADE_COST):
		return false
	level += 1
	invested_essence += GameState.TOWER_UPGRADE_COST
	damage = 15 + (level - 1) * 8
	fire_rate = maxf(0.28, 0.5 - (level - 1) * 0.07)
	fire_range = 170.0 + (level - 1) * 25.0
	_apply_level_look()
	GameState.message.emit("Tower upgraded to Lv%d!" % level)
	if Sfx:
		Sfx.build()
	if Juice:
		Juice.shake(3.0)
	if FX:
		FX.burst_particles(self, global_position + Vector2(0, -30), Color(1.0, 0.9, 0.4), 16, "star", 0.5)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -40), "Lv%d" % level, Color(1.0, 0.85, 0.3))
	return true


func _apply_level_look() -> void:
	if _level_label:
		_level_label.text = "Lv%d" % level
	if _canopy:
		var greens := [
			Color(0.32, 0.58, 0.38),
			Color(0.28, 0.62, 0.42),
			Color(0.35, 0.7, 0.48),
		]
		_canopy.color = greens[mini(level - 1, 2)]
	if _gem:
		_gem.scale = Vector2.ONE * (1.0 + (level - 1) * 0.2)
	if _range_ring:
		_range_ring.scale = Vector2.ONE * (fire_range / 170.0)


func _build_visuals() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	if VisualStyle:
		VisualStyle.make_blob_shadow(_visual, 24, 10, 14)
	else:
		FX.add_soft_shadow(_visual, 24, 10, 14)

	# KR-style range disc
	_range_ring = FX.make_ellipse_poly(fire_range * 0.5, fire_range * 0.32, 48, Color(0.3, 0.75, 0.4, 0.14))
	_range_ring.z_index = -2
	_visual.add_child(_range_ring)
	var range_edge := FX.make_ellipse_poly(fire_range * 0.5, fire_range * 0.32, 48, Color(0.4, 0.9, 0.5, 0.0))
	# outline via larger ring underneath
	var outline := FX.make_ellipse_poly(fire_range * 0.52, fire_range * 0.34, 48, Color(0.2, 0.9, 0.35, 0.12))
	outline.z_index = -3
	_visual.add_child(outline)

	var trunk := Polygon2D.new()
	trunk.polygon = PackedVector2Array([
		Vector2(-10, 14), Vector2(10, 14), Vector2(8, -8), Vector2(4, -28),
		Vector2(-4, -28), Vector2(-8, -8)
	])
	trunk.color = Color(0.42, 0.28, 0.18)
	_visual.add_child(trunk)

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

	_gem = Polygon2D.new()
	_gem.polygon = PackedVector2Array([
		Vector2(0, -46), Vector2(8, -34), Vector2(0, -28), Vector2(-8, -34)
	])
	_gem.color = Color(0.95, 0.8, 0.45)
	_visual.add_child(_gem)

	_pulse = FX.make_ellipse_poly(18, 14, 18, Color(0.95, 0.85, 0.4, 0.18))
	_pulse.position = Vector2(0, -36)
	_visual.add_child(_pulse)

	_level_label = Label.new()
	_level_label.text = "Lv1"
	_level_label.position = Vector2(-14, 12)
	_level_label.add_theme_font_size_override("font_size", 11)
	_level_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	_level_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_level_label.add_theme_constant_override("outline_size", 3)
	_visual.add_child(_level_label)

	FX.spark_particles(_visual, Color(0.95, 0.85, 0.5, 0.65), 10, "glow").position = Vector2(0, -36)


func _process(delta: float) -> void:
	if GameState.is_game_over:
		return
	_bob += delta
	if _visual:
		_visual.position.y = sin(_bob * 1.8) * 1.5
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
			FloatingText.spawn(get_parent(), target.global_position + Vector2(0, -16), str(damage), Color(1.0, 0.85, 0.4))
		_muzzle_flash(target.global_position)


func _find_target() -> Node2D:
	var best: Node2D = null
	var best_d := fire_range
	# KR-style: prefer enemy furthest along path (closest to crystal)
	var crystal_pos := PathNetwork.CRYSTAL if PathNetwork else Vector2.ZERO
	var best_progress := -1.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D:
			var d: float = global_position.distance_to(e.global_position)
			if d > fire_range:
				continue
			# Prefer those closer to crystal (higher threat)
			var progress := 1.0 / maxf(40.0, e.global_position.distance_to(crystal_pos))
			if progress > best_progress:
				best_progress = progress
				best = e
				best_d = d
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
	tw.tween_property(line, "modulate:a", 0.0, 0.12)
	tw.tween_property(impact, "modulate:a", 0.0, 0.15)
	tw.tween_property(impact, "scale", Vector2(2.4, 2.4), 0.15)
	tw.chain().tween_callback(func() -> void:
		line.queue_free()
		impact.queue_free()
	)
