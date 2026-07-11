extends CharacterBody2D
class_name Nightspawn
## Nightspawn — follows authored path lanes to the Lightwell.

@export var max_hp: int = 40
@export var move_speed: float = 70.0
@export var crystal_damage: int = 8
@export var dust_drop_chance: float = 0.15
@export var path_slack: float = 18.0  ## lateral wander on the road
@export var waypoint_reach: float = 28.0

var hp: int
var _crystal: Node2D
var _visual: Node2D
var _body_poly: Polygon2D
var _body_sprite: Sprite2D
var _wings: Array[Polygon2D] = []
var _anim_t: float = 0.0
var _use_sprite: bool = false
var _skin_frames: Array[Texture2D] = []
var _skin_modulate: Color = Color(0.72, 0.42, 0.62)
var _frame_idx: int = 0
var _frame_t: float = 0.0

var _lane: PackedVector2Array = PackedVector2Array()
var _wp_index: int = 0
var _lateral: float = 0.0
var _is_elite: bool = false
var _face_sign: float = 1.0
var _slow: float = 0.0
var _slow_t: float = 0.0
var _mark_mult: float = 1.0
var _mark_t: float = 0.0

@onready var _bar: ProgressBar = $HpBar


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	if has_node("Body"):
		$Body.visible = false
	if has_node("Eye"):
		$Eye.visible = false

	_lateral = randf_range(-path_slack, path_slack)
	if _lane.is_empty() and PathNetwork:
		assign_lane(PathNetwork.random_lane())

	_build_visuals()
	FX.style_progress_bar(_bar, Color(0.85, 0.25, 0.4), Color(0.1, 0.04, 0.08, 0.85))
	_bar.max_value = max_hp
	_bar.value = hp
	_bar.position = Vector2(-18, -36)
	_bar.size = Vector2(36, 7)
	if _is_elite:
		_bar.size = Vector2(48, 8)
		_bar.position = Vector2(-24, -42)
	_crystal = get_tree().get_first_node_in_group("crystal") as Node2D


func assign_lane(lane: PackedVector2Array) -> void:
	_lane = lane
	_wp_index = 0
	if _lane.size() > 0:
		# Start near first waypoint with lateral offset
		var n := PathNetwork.path_normal_at(_lane, 0) if PathNetwork else Vector2.RIGHT
		global_position = _lane[0] + n * _lateral + Vector2(randf_range(-12, 12), randf_range(-12, 12))


func make_elite() -> void:
	_is_elite = true
	max_hp = int(max_hp * 2.2)
	hp = max_hp
	move_speed *= 0.85
	crystal_damage = int(crystal_damage * 1.8)
	scale = Vector2(1.35, 1.35)
	# Elite tint + thicker outline (visuals already built in _ready before this runs)
	if _body_sprite:
		_skin_modulate = _skin_modulate.lightened(0.15)
		_skin_modulate.r = minf(1.0, _skin_modulate.r + 0.2)
		_body_sprite.modulate = _skin_modulate
		_apply_outline()
	if _visual:
		var ring := FX.make_ellipse_poly(22, 14, 20, Color(0.95, 0.5, 0.3, 0.25))
		ring.z_index = -1
		_visual.add_child(ring)


func _build_visuals() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	FX.add_soft_shadow(_visual, 14, 6, 10)

	var skin: Dictionary = AssetPaths.random_enemy_skin()
	_skin_frames = skin.get("frames", []) as Array[Texture2D]
	_skin_modulate = skin.get("modulate", Color(0.72, 0.42, 0.62)) as Color
	var scale_mul: float = float(skin.get("scale", 3.4))
	if _is_elite:
		_skin_modulate = _skin_modulate.lightened(0.15)
		_skin_modulate.r = minf(1.0, _skin_modulate.r + 0.2)
		scale_mul *= 1.15

	var aura := FX.make_ellipse_poly(16, 10, 16, Color(0.55, 0.1, 0.25, 0.22))
	aura.z_index = -1
	_visual.add_child(aura)
	if _is_elite:
		var ring := FX.make_ellipse_poly(22, 14, 20, Color(0.95, 0.5, 0.3, 0.25))
		ring.z_index = -1
		_visual.add_child(ring)

	if not _skin_frames.is_empty() and _skin_frames[0] != null:
		_use_sprite = true
		_body_sprite = AssetPaths.make_pixel_sprite(_skin_frames[0], scale_mul * 1.25)
		_body_sprite.modulate = _skin_modulate
		_body_sprite.position = Vector2(0, -6)
		_visual.add_child(_body_sprite)
		_apply_outline()
		return

	_body_poly = Polygon2D.new()
	_body_poly.polygon = PackedVector2Array([
		Vector2(0, -16), Vector2(10, -6), Vector2(12, 6), Vector2(4, 14),
		Vector2(-4, 14), Vector2(-12, 6), Vector2(-10, -6)
	])
	_body_poly.color = Color(0.42, 0.12, 0.28)
	_visual.add_child(_body_poly)


func _apply_outline() -> void:
	if _body_sprite == null or VisualStyle == null:
		return
	var w := 1.35 if _is_elite else 1.25
	VisualStyle.apply_sprite_outline(_body_sprite, w)
	# Retry next frame if material didn't stick (edge case on some render paths)
	if _body_sprite.material == null:
		VisualStyle.call_deferred("apply_sprite_outline", _body_sprite, w)


func _physics_process(delta: float) -> void:
	_anim_t += delta
	_frame_t += delta
	if GameState.is_game_over:
		velocity = Vector2.ZERO
		return

	var target := _current_path_target()
	if _crystal == null or not is_instance_valid(_crystal):
		_crystal = get_tree().get_first_node_in_group("crystal") as Node2D

	# Final approach / damage crystal
	if _crystal and global_position.distance_to(_crystal.global_position) < 30.0:
		GameState.damage_crystal(crystal_damage)
		if Sfx:
			Sfx.crystal_hurt()
		if Juice:
			Juice.shake(10.0)
			Juice.flash(Color(0.9, 0.2, 0.35, 0.4), 0.15)
		_spawn_death_poof()
		queue_free()
		return

	var to := target - global_position
	if to.length() < waypoint_reach:
		_wp_index = mini(_wp_index + 1, maxi(0, _lane.size() - 1))
		target = _current_path_target()
		to = target - global_position

	# Soft separation from nearby enemies
	var sep := Vector2.ZERO
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not (e is Node2D):
			continue
		var d: Vector2 = global_position - e.global_position
		var dist := d.length()
		if dist > 0.1 and dist < 36.0:
			sep += d.normalized() * (1.0 - dist / 36.0)
	if sep.length() > 0.01:
		to += sep.normalized() * 40.0

	if _slow_t > 0.0:
		_slow_t -= delta
		if _slow_t <= 0.0:
			_slow = 0.0
	if _mark_t > 0.0:
		_mark_t -= delta
		if _mark_t <= 0.0:
			_mark_mult = 1.0

	var spd := move_speed * (1.0 - clampf(_slow, 0.0, 0.7))
	if to.length() > 1.0:
		velocity = to.normalized() * spd
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	z_index = int(global_position.y)

	# Animate — single scale write (face sign only; never fight sprite flip_h)
	if _visual:
		_visual.position.y = sin(_anim_t * 10.0) * 1.5
		if to.x < -2.0:
			_face_sign = -1.0
		elif to.x > 2.0:
			_face_sign = 1.0
		_visual.scale = Vector2(_face_sign, 1.0)
	if _use_sprite and _body_sprite and _skin_frames.size() > 1 and _frame_t > 0.18:
		_frame_t = 0.0
		_frame_idx = (_frame_idx + 1) % _skin_frames.size()
		if _skin_frames[_frame_idx]:
			_body_sprite.texture = _skin_frames[_frame_idx]


func _current_path_target() -> Vector2:
	if _lane.is_empty():
		if _crystal:
			return _crystal.global_position
		return global_position
	var i := clampi(_wp_index, 0, _lane.size() - 1)
	var base: Vector2 = _lane[i]
	var n := PathNetwork.path_normal_at(_lane, i) if PathNetwork else Vector2.RIGHT
	# Ease lateral toward 0 near the end
	var end_t := float(i) / float(maxi(1, _lane.size() - 1))
	var lat := _lateral * (1.0 - end_t * 0.85)
	return base + n * lat


func apply_slow(amount: float, duration: float) -> void:
	_slow = maxf(_slow, amount)
	_slow_t = maxf(_slow_t, duration)


func apply_mark(mult: float, duration: float) -> void:
	_mark_mult = maxf(_mark_mult, mult)
	_mark_t = maxf(_mark_t, duration)


func is_marked() -> bool:
	return _mark_t > 0.0 and _mark_mult > 1.0


func take_damage(amount: int) -> void:
	if is_marked():
		amount = int(amount * _mark_mult)
	hp -= amount
	_bar.value = hp
	if _body_sprite:
		_body_sprite.modulate = Color(1.8, 1.5, 1.5)
		var t := create_tween()
		t.tween_property(_body_sprite, "modulate", _skin_modulate, 0.12)
	elif _body_poly:
		_body_poly.modulate = Color(1.8, 1.5, 1.5)
		var t2 := create_tween()
		t2.tween_property(_body_poly, "modulate", Color.WHITE, 0.12)
	if Sfx:
		Sfx.hit()
	if Juice and amount >= 12:
		Juice.shake(2.5)
	if hp <= 0:
		_die()


func _die() -> void:
	# Kingdom Rush–style kill bounty
	GameState.reward_kill(_is_elite, global_position)
	if randf() < dust_drop_chance * (2.0 if _is_elite else 1.0):
		GameState.add_crystal_dust(1 if not _is_elite else 2)
		FloatingText.spawn(get_parent(), global_position + Vector2(0, -28), "+dust", Color(0.85, 0.7, 1.0))
	if _is_elite and Juice:
		Juice.shake(8.0)
		Juice.flash(Color(1.0, 0.6, 0.3, 0.3), 0.12)
	_spawn_death_poof()
	queue_free()


func _spawn_death_poof() -> void:
	var parent := get_parent()
	if parent == null:
		return
	if FX:
		FX.burst_particles(parent, global_position, Color(0.75, 0.35, 0.85, 0.9), 12, "magic", 0.45)
		FX.burst_particles(parent, global_position, Color(0.55, 0.5, 0.6, 0.75), 8, "puff", 0.5)
