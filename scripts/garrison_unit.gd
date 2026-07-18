extends Node2D
class_name GarrisonUnit
## Path blocker spawned by Garrison towers — leaves the pad, holds the road, can die.

var max_hp: int = 48
var hp: int = 48
var damage: int = 9
var attack_range: float = 52.0
var attack_rate: float = 0.55
var move_speed: float = 95.0
var home_tower: Node2D = null
var rally_point: Vector2 = Vector2.ZERO
var path_dist: float = 0.0

var _cd: float = 0.0
var _visual: Node2D
var _body: Polygon2D
var _bar: ProgressBar
var _bob: float = 0.0
var _fight_target: Node2D = null
var _alive: bool = true


func _ready() -> void:
	add_to_group("garrison_units")
	hp = max_hp
	z_as_relative = false
	_build_visuals()
	_bob = randf() * TAU
	_refresh_z()


func configure(p_hp: int, p_dmg: int, p_range: float, tower: Node2D, rally: Vector2) -> void:
	max_hp = maxi(8, p_hp)
	hp = max_hp
	damage = maxi(1, p_dmg)
	attack_range = maxf(28.0, p_range)
	home_tower = tower
	rally_point = rally
	if is_inside_tree():
		_sync_bar()


func _build_visuals() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	if VisualStyle:
		VisualStyle.make_blob_shadow(_visual, 12, 6, 10)
	elif FX:
		FX.add_soft_shadow(_visual, 12, 6, 10)

	# Small shield-bearer silhouette
	var cloak := Polygon2D.new()
	cloak.polygon = PackedVector2Array([
		Vector2(-7, 6), Vector2(7, 6), Vector2(6, -4), Vector2(3, -14),
		Vector2(0, -18), Vector2(-3, -14), Vector2(-6, -4)
	])
	cloak.color = Color(0.55, 0.42, 0.3)
	_visual.add_child(cloak)
	_body = cloak

	var shield := Polygon2D.new()
	shield.polygon = PackedVector2Array([
		Vector2(4, -2), Vector2(12, -6), Vector2(12, 6), Vector2(4, 8)
	])
	shield.color = Color(0.72, 0.78, 0.88)
	_visual.add_child(shield)

	var helm := Polygon2D.new()
	helm.polygon = PackedVector2Array([
		Vector2(-4, -14), Vector2(4, -14), Vector2(3, -20), Vector2(0, -22), Vector2(-3, -20)
	])
	helm.color = Color(0.85, 0.7, 0.45)
	_visual.add_child(helm)

	_bar = ProgressBar.new()
	_bar.position = Vector2(-14, -30)
	_bar.size = Vector2(28, 5)
	_bar.max_value = max_hp
	_bar.value = hp
	_bar.show_percentage = false
	_bar.z_index = 5
	if FX:
		FX.style_progress_bar(_bar, Color(0.55, 0.85, 0.45), Color(0.1, 0.08, 0.06, 0.85))
	add_child(_bar)


func _sync_bar() -> void:
	if _bar:
		_bar.max_value = max_hp
		_bar.value = hp


func _refresh_z() -> void:
	if VisualStyle:
		z_index = VisualStyle.actor_z(global_position.y) + 2
	else:
		z_index = clampi(52 + int(global_position.y) + 2000, 50, 4000)


func _process(delta: float) -> void:
	if not _alive or (GameState != null and GameState.is_game_over):
		return
	_bob += delta
	if _visual:
		_visual.position.y = sin(_bob * 4.0) * 1.2

	_cd = maxf(0.0, _cd - delta)

	# Move toward rally if far
	var to_rally := rally_point - global_position
	var at_rally := to_rally.length() < 10.0
	if not at_rally and _fight_target == null:
		var step := move_speed * delta
		if to_rally.length() <= step:
			global_position = rally_point
		else:
			global_position += to_rally.normalized() * step
		_refresh_z()

	# Find ground enemy in range
	_fight_target = _find_enemy()
	if _fight_target and is_instance_valid(_fight_target):
		var to_e: Vector2 = _fight_target.global_position - global_position
		if to_e.length() > attack_range * 0.45:
			global_position += to_e.normalized() * move_speed * 0.85 * delta
			_refresh_z()
		if _cd <= 0.0 and to_e.length() <= attack_range:
			_cd = attack_rate
			_strike(_fight_target)
	_sync_bar()


func _find_enemy() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var best: Node2D = null
	var best_d := attack_range * attack_range
	for e in tree.get_nodes_in_group("enemies"):
		if not (e is Node2D) or not is_instance_valid(e):
			continue
		if e.get("is_flying") != null and bool(e.get("is_flying")):
			continue
		var d2: float = global_position.distance_squared_to(e.global_position)
		if d2 <= best_d:
			best_d = d2
			best = e
	return best


func _strike(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.has_method("take_damage"):
		target.call("take_damage", damage, "thorn", "soldiers", "garrison")
	if FloatingText:
		FloatingText.spawn(get_parent(), target.global_position + Vector2(0, -12), str(damage), Color(0.85, 0.7, 0.4))
	if _visual:
		var tw := create_tween()
		tw.tween_property(_visual, "scale", Vector2(1.15, 0.9), 0.05)
		tw.tween_property(_visual, "scale", Vector2.ONE, 0.1)
	if FX:
		FX.burst_particles(self, target.global_position, Color(0.75, 0.55, 0.35), 4, "spark", 0.18)


func take_damage(amount: int, _channel: String = "", _special: String = "", _role: String = "") -> void:
	if not _alive:
		return
	hp -= maxi(1, amount)
	_sync_bar()
	if _body:
		_body.modulate = Color(1.6, 0.8, 0.8)
		var tw := create_tween()
		tw.tween_property(_body, "modulate", Color.WHITE, 0.12)
	if hp <= 0:
		_die()


func _die() -> void:
	if not _alive:
		return
	_alive = false
	if home_tower and is_instance_valid(home_tower) and home_tower.has_method("on_soldier_died"):
		home_tower.call("on_soldier_died", self)
	if FX:
		FX.burst_particles(get_parent() if get_parent() else self, global_position, Color(0.7, 0.5, 0.35), 10, "spark", 0.3)
	queue_free()


func get_path_dist() -> float:
	return path_dist


func is_blocking() -> bool:
	return _alive
