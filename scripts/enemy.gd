extends CharacterBody2D
class_name Nightspawn
## Nightspawn — locked to authored path lanes toward the Lightwell.
## Players roam free; monsters stay on the road.

@export var max_hp: int = 40
@export var move_speed: float = 70.0
@export var crystal_damage: int = 8
@export var dust_drop_chance: float = 0.15
@export var path_slack: float = 14.0  ## lateral wander *on* the road (pixels)

var hp: int
var _crystal: Node2D
var _visual: Node2D
var _body_poly: Polygon2D
var _body_sprite: Sprite2D
var _wings: Array[Polygon2D] = []
var _anim_t: float = 0.0
var _use_sprite: bool = false
var _skin_frames: Array[Texture2D] = []
var _anim_walk: Array[Texture2D] = []
var _anim_idle: Array[Texture2D] = []
var _skin_modulate: Color = Color(0.72, 0.42, 0.62)
var _frame_idx: int = 0
var _frame_t: float = 0.0
var _sprite_scale: float = 0.85

var _lane: PackedVector2Array = PackedVector2Array()
var _path_dist: float = 0.0
var _lane_len: float = 0.0
var _lateral: float = 0.0
var _is_elite: bool = false
var _face_sign: float = 1.0
var _slow: float = 0.0
var _slow_t: float = 0.0
var _mark_mult: float = 1.0
var _mark_t: float = 0.0
var _move_dir: Vector2 = Vector2.DOWN

@onready var _bar: ProgressBar = $HpBar


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	# Top-down free motion; no physics blocking — path is authority.
	motion_mode = MOTION_MODE_FLOATING
	collision_layer = 4  # enemy
	collision_mask = 0   # nothing blocks pathing
	z_as_relative = false
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
	_path_dist = 0.0
	_lane_len = PathNetwork.lane_length(_lane) if PathNetwork else 0.0
	if _lane.is_empty():
		return
	if PathNetwork == null:
		global_position = _lane[0]
		return
	var sample: Dictionary = PathNetwork.sample_lane(_lane, 0.0)
	var n: Vector2 = sample.get("normal", Vector2.RIGHT)
	global_position = sample.get("pos", _lane[0]) + n * _lateral
	_move_dir = sample.get("tangent", Vector2.DOWN)


func make_elite() -> void:
	_is_elite = true
	max_hp = int(max_hp * 2.2)
	hp = max_hp
	move_speed *= 0.85
	crystal_damage = int(crystal_damage * 1.8)
	scale = Vector2(1.35, 1.35)
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
	FX.add_soft_shadow(_visual, 16, 7, 12)

	var skin: Dictionary = AssetPaths.random_enemy_skin()
	_skin_modulate = skin.get("modulate", Color(0.72, 0.42, 0.62)) as Color
	_sprite_scale = float(skin.get("scale", 0.85))
	_anim_walk = []
	_anim_idle = []
	for t in skin.get("walk", skin.get("frames", [])):
		if t is Texture2D:
			_anim_walk.append(t as Texture2D)
	for t in skin.get("idle", skin.get("frames", [])):
		if t is Texture2D:
			_anim_idle.append(t as Texture2D)
	if _anim_walk.is_empty():
		_anim_walk = _anim_idle.duplicate()
	_skin_frames = _anim_walk
	if _is_elite:
		_skin_modulate = _skin_modulate.lightened(0.12)
		_sprite_scale *= 1.2

	if _is_elite:
		var ring := FX.make_ellipse_poly(20, 12, 18, Color(0.95, 0.5, 0.3, 0.22))
		ring.z_index = -1
		_visual.add_child(ring)

	if not _skin_frames.is_empty() and _skin_frames[0] != null:
		_use_sprite = true
		_body_sprite = AssetPaths.make_pixel_sprite(_skin_frames[0], _sprite_scale)
		_body_sprite.modulate = _skin_modulate
		_body_sprite.centered = true
		_body_sprite.offset = Vector2(0, -float(_skin_frames[0].get_height()) * 0.15)
		_body_sprite.position = Vector2.ZERO
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
	if _body_sprite.material == null:
		VisualStyle.call_deferred("apply_sprite_outline", _body_sprite, w)


func _physics_process(delta: float) -> void:
	_anim_t += delta
	_frame_t += delta
	if GameState.is_game_over:
		velocity = Vector2.ZERO
		return

	if _crystal == null or not is_instance_valid(_crystal):
		_crystal = get_tree().get_first_node_in_group("crystal") as Node2D

	if _slow_t > 0.0:
		_slow_t -= delta
		if _slow_t <= 0.0:
			_slow = 0.0
	if _mark_t > 0.0:
		_mark_t -= delta
		if _mark_t <= 0.0:
			_mark_mult = 1.0

	var spd := move_speed * (1.0 - clampf(_slow, 0.0, 0.7))

	# Lateral separation only — stay on the road, don't shove off-path
	_apply_lateral_separation(delta)

	if _lane.is_empty() or PathNetwork == null:
		_fallback_to_crystal(spd)
		_finish_frame()
		return

	# Advance along the authored polyline
	_path_dist += spd * delta
	var sample: Dictionary = PathNetwork.sample_lane(_lane, _path_dist)
	var center: Vector2 = sample.get("pos", global_position)
	var normal: Vector2 = sample.get("normal", Vector2.RIGHT)
	var tangent: Vector2 = sample.get("tangent", Vector2.DOWN)
	var at_end: bool = bool(sample.get("at_end", false))
	_lane_len = float(sample.get("length", _lane_len))

	# Ease lateral toward center near the Lightwell so leaks feel clean
	var end_t := 0.0
	if _lane_len > 1.0:
		end_t = clampf(_path_dist / _lane_len, 0.0, 1.0)
	var lat := _lateral * (1.0 - end_t * 0.9)
	var on_path: Vector2 = center + normal * lat

	# Lock to path (authoritative). Velocity is for animation / any readers.
	global_position = on_path
	velocity = tangent * spd
	_move_dir = tangent

	# Leak when path ends or we touch the crystal
	var crystal_pos: Vector2 = _crystal.global_position if _crystal else PathNetwork.CRYSTAL
	if at_end or global_position.distance_to(crystal_pos) < 34.0:
		_leak()
		return

	_finish_frame()


func _apply_lateral_separation(_delta: float) -> void:
	var push := 0.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not (e is Node2D):
			continue
		var d: Vector2 = global_position - e.global_position
		var dist := d.length()
		if dist > 0.1 and dist < 32.0:
			# Prefer left/right along screen x as a stable lateral cue
			var side := signf(d.x) if absf(d.x) > 0.5 else (1.0 if d.y >= 0.0 else -1.0)
			push += side * (1.0 - dist / 32.0) * 10.0
	_lateral = clampf(_lateral + push * 0.08, -path_slack * 1.35, path_slack * 1.35)


func _fallback_to_crystal(spd: float) -> void:
	var target: Vector2 = _crystal.global_position if _crystal else (PathNetwork.CRYSTAL if PathNetwork else Vector2.ZERO)
	var to := target - global_position
	if to.length() < 30.0:
		_leak()
		return
	if to.length() > 1.0:
		velocity = to.normalized() * spd
		global_position += velocity * get_physics_process_delta_time()
		_move_dir = velocity.normalized()
	else:
		velocity = Vector2.ZERO


func _leak() -> void:
	GameState.damage_crystal(crystal_damage)
	if Sfx:
		Sfx.crystal_hurt()
	if Juice:
		Juice.shake(10.0)
		Juice.flash(Color(0.9, 0.2, 0.35, 0.4), 0.15)
	_spawn_death_poof()
	queue_free()


func _finish_frame() -> void:
	if VisualStyle:
		z_index = VisualStyle.actor_z(global_position.y)
	else:
		z_index = clampi(50 + int(global_position.y) + 2000, 50, 4000)
	if _visual:
		_visual.position.y = 0.0
		if _move_dir.x < -0.12:
			_face_sign = -1.0
		elif _move_dir.x > 0.12:
			_face_sign = 1.0
		_visual.scale = Vector2(_face_sign, 1.0)
	# Walk flip while moving along path
	if _use_sprite and _body_sprite and _anim_walk.size() > 0:
		var moving := _move_dir.length() > 0.05
		var frames: Array[Texture2D] = _anim_walk if moving else (_anim_idle if not _anim_idle.is_empty() else _anim_walk)
		var rate := 0.18 if moving else 0.4
		if frames.size() == 1:
			_body_sprite.texture = frames[0]
		elif _frame_t > rate:
			_frame_t = 0.0
			_frame_idx = (_frame_idx + 1) % frames.size()
			if frames[_frame_idx]:
				_body_sprite.texture = frames[_frame_idx]


func apply_slow(amount: float, duration: float) -> void:
	_slow = maxf(_slow, amount)
	_slow_t = maxf(_slow_t, duration)


func apply_mark(mult: float, duration: float) -> void:
	_mark_mult = maxf(_mark_mult, mult)
	_mark_t = maxf(_mark_t, duration)


func is_marked() -> bool:
	return _mark_t > 0.0 and _mark_mult > 1.0


func is_elite() -> bool:
	return _is_elite


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
	GameState.reward_kill(_is_elite, global_position)
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
