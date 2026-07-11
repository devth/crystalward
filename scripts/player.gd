extends CharacterBody2D
class_name Warden
## Player warden — move, gather, queue build, attack. Dark Crystal–esque sprite body.

@export var player_index: int = 0
@export var move_speed: float = 250.0
@export var move_accel: float = 1800.0
@export var move_friction: float = 2200.0
@export var attack_damage: int = 20
@export var attack_cooldown: float = 0.26
@export var attack_range: float = 52.0
@export var body_color: Color = Color(0.55, 0.75, 0.7)

var _attack_cd: float = 0.0
var _facing: Vector2 = Vector2.DOWN
## Horizontal facing for visuals only — kept separate so squash/stretch never fights flip.
var _face_sign: float = 1.0
var _near_gather: Array[Node] = []
var _near_build: Array[Node] = []
var _visual_root: Node2D
var _body_sprite: Sprite2D
var _attack_arc: Polygon2D
var _bob_t: float = 0.0
var _skin_frames: Array[Texture2D] = []
var _skin_modulate: Color = Color.WHITE
var _frame_flip_t: float = 0.0
var _frame_idx: int = 0
var _use_sprite: bool = false

@onready var _label: Label = $Label


func _ready() -> void:
	add_to_group("wardens")
	GameState.register_warden(self)
	collision_layer = 2
	collision_mask = 1
	if has_node("Body"):
		$Body.visible = false
	if has_node("AttackFlash"):
		$AttackFlash.visible = false
	if has_node("Shadow"):
		$Shadow.visible = false

	_build_visuals()
	_label.text = "P%d" % (player_index + 1)
	if VisualStyle:
		VisualStyle.style_game_label(_label, 15, true)
		_label.add_theme_color_override("font_color", body_color.lightened(0.35))
	else:
		_label.add_theme_color_override("font_color", body_color.lightened(0.25))
		_label.add_theme_constant_override("outline_size", 5)
	_label.position = Vector2(-18, -58)
	_label.z_index = 10


func _build_visuals() -> void:
	_visual_root = Node2D.new()
	_visual_root.name = "Visual"
	add_child(_visual_root)
	FX.add_soft_shadow(_visual_root, 16, 7, 12)

	var skin: Dictionary = AssetPaths.warden_skin(player_index)
	_skin_frames = skin.get("frames", []) as Array[Texture2D]
	_skin_modulate = skin.get("modulate", body_color) as Color
	body_color = _skin_modulate
	var scale_mul: float = float(skin.get("scale", 3.6))

	# Soft organic aura — living crystal flesh vibe
	var aura := FX.make_ellipse_poly(22, 26, 24, Color(_skin_modulate.r, _skin_modulate.g, _skin_modulate.b, 0.16))
	aura.z_index = -2
	_visual_root.add_child(aura)
	var aura2 := FX.make_ellipse_poly(14, 16, 18, Color(_skin_modulate.r * 0.7, _skin_modulate.g, _skin_modulate.b * 0.9, 0.12))
	aura2.z_index = -1
	_visual_root.add_child(aura2)

	var mote := FX.spark_particles(_visual_root, Color(_skin_modulate.r, _skin_modulate.g, _skin_modulate.b, 0.55), 8, "glow")
	mote.position = Vector2(0, -6)
	mote.z_index = -1
	var pm := mote.process_material as ParticleProcessMaterial
	if pm:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 14.0
		pm.gravity = Vector3(0, -6, 0)
		pm.initial_velocity_min = 2.0
		pm.initial_velocity_max = 8.0

	if not _skin_frames.is_empty() and _skin_frames[0] != null:
		_use_sprite = true
		# PJ Monsters–scale readability: bigger, outlined sprites
		_body_sprite = AssetPaths.make_pixel_sprite(_skin_frames[0], scale_mul * 1.25)
		_body_sprite.modulate = _skin_modulate
		_body_sprite.position = Vector2(0, -8)
		_body_sprite.name = "BodySprite"
		_visual_root.add_child(_body_sprite)
		# Outline after enter-tree so material sticks on all renderers
		if VisualStyle:
			VisualStyle.apply_sprite_outline(_body_sprite, 1.35)
	else:
		_use_sprite = false
		_build_polygon_fallback()

	# Staff crystal (kept for Dark Crystal ritual staff vibe)
	var staff := Line2D.new()
	staff.width = 2.5
	staff.default_color = Color(0.35, 0.3, 0.28)
	staff.points = PackedVector2Array([Vector2(12, 8), Vector2(16, -18)])
	_visual_root.add_child(staff)
	var gem := Polygon2D.new()
	gem.polygon = PackedVector2Array([
		Vector2(16, -26), Vector2(20, -18), Vector2(16, -14), Vector2(12, -18)
	])
	gem.color = Color(0.65, 0.9, 0.8, 0.95).lerp(_skin_modulate, 0.35)
	gem.name = "StaffGem"
	_visual_root.add_child(gem)

	_attack_arc = Polygon2D.new()
	_attack_arc.polygon = PackedVector2Array([
		Vector2(6, -14), Vector2(46, -6), Vector2(44, 8), Vector2(6, 12)
	])
	_attack_arc.color = Color(_skin_modulate.r, _skin_modulate.g, _skin_modulate.b, 0.55)
	_attack_arc.visible = false
	_visual_root.add_child(_attack_arc)


func _build_polygon_fallback() -> void:
	var cloak := Polygon2D.new()
	cloak.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(12, -12), Vector2(14, 4), Vector2(8, 16),
		Vector2(0, 14), Vector2(-8, 16), Vector2(-14, 4), Vector2(-12, -12)
	])
	cloak.color = body_color.darkened(0.15)
	_visual_root.add_child(cloak)
	var mask := Polygon2D.new()
	mask.polygon = PackedVector2Array([
		Vector2(0, -26), Vector2(9, -18), Vector2(7, -8), Vector2(0, -4),
		Vector2(-7, -8), Vector2(-9, -18)
	])
	mask.color = Color(0.85, 0.8, 0.95).lerp(body_color, 0.35)
	_visual_root.add_child(mask)


func _exit_tree() -> void:
	GameState.unregister_warden(self)


func _physics_process(delta: float) -> void:
	if GameState.is_game_over:
		velocity = Vector2.ZERO
		return

	_attack_cd = maxf(0.0, _attack_cd - delta)
	_bob_t += delta * (8.0 if velocity.length() > 10.0 else 3.0)

	var dir := _read_move()
	if dir.length_squared() > 0.01:
		_facing = dir.normalized()
		# Only update face sign on meaningful horizontal input (don't flip on pure up/down)
		if absf(_facing.x) > 0.15:
			_face_sign = -1.0 if _facing.x < 0.0 else 1.0
		velocity = velocity.move_toward(dir.normalized() * move_speed, move_accel * delta)
		if _use_sprite and _skin_frames.size() > 1 and _body_sprite:
			_frame_flip_t += delta
			if _frame_flip_t >= 0.16:
				_frame_flip_t = 0.0
				_frame_idx = (_frame_idx + 1) % _skin_frames.size()
				_body_sprite.texture = _skin_frames[_frame_idx]
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_friction * delta)
		if _use_sprite and not _skin_frames.is_empty() and _body_sprite:
			_body_sprite.texture = _skin_frames[0]
			_frame_idx = 0

	move_and_slide()
	global_position = GameState.clamp_world_position(global_position)
	z_index = int(global_position.y)

	# Single scale write: facing sign × squash (never set flip_h / scale elsewhere)
	if _visual_root:
		var moving := velocity.length() > 12.0
		_visual_root.position.y = sin(_bob_t) * (3.0 if moving else 1.2)
		var squash := 1.0 + sin(_bob_t * 2.0) * (0.06 if moving else 0.02)
		_visual_root.scale = Vector2(_face_sign * squash, 1.0 / squash)
		if has_node("Visual/StaffGem"):
			var gem: Polygon2D = $Visual/StaffGem
			gem.modulate = Color(1, 1, 1, 0.75 + 0.25 * sin(_bob_t * 1.3))

	if _action_just_pressed("gather"):
		# Gather wins over sell when an essence node is in range (no accidental sells).
		if not _near_gather.is_empty():
			_try_gather(delta)
		else:
			# KR sell: tap E on a built pad only when not gathering.
			_try_sell_nearby()
	elif _action_pressed("gather"):
		# Hold-to-gather only — never sell on hold (avoids sell spam / gather conflict).
		if not _near_gather.is_empty():
			_try_gather(delta)
	if _action_just_pressed("build"):
		_try_build()
	if _action_just_pressed("attack"):
		_try_attack()
	if Input.is_action_just_pressed("call_wave"):
		_try_call_wave()
	# Cycle tower types on pad (Kingdom Rush shop feel)
	if _near_build.size() > 0:
		if _action_just_pressed("cycle_left") or Input.is_action_just_pressed("ui_left"):
			_cycle_pad(-1)
		if _action_just_pressed("cycle_right") or Input.is_action_just_pressed("ui_right"):
			_cycle_pad(1)


func _read_move() -> Vector2:
	var prefix := "p%d_" % (player_index + 1)
	var x := Input.get_axis(prefix + "left", prefix + "right")
	var y := Input.get_axis(prefix + "up", prefix + "down")
	return Vector2(x, y)


func _action_pressed(action: String) -> bool:
	return Input.is_action_pressed("p%d_%s" % [player_index + 1, action])


func _action_just_pressed(action: String) -> bool:
	return Input.is_action_just_pressed("p%d_%s" % [player_index + 1, action])


func _try_gather(delta: float) -> void:
	for n in _near_gather:
		if n and n.has_method("contribute_gather"):
			n.contribute_gather(delta)
			return


func _try_sell_nearby() -> void:
	for n in _near_build:
		if n == null or not is_instance_valid(n):
			continue
		# Prefer explicit API (State.BUILT == 2, but don't hardcode enum ints).
		if n.has_method("can_sell") and not n.can_sell():
			continue
		if n.has_method("try_sell") and n.try_sell():
			return


func _try_build() -> void:
	for n in _near_build:
		if n and n.has_method("try_queue_build"):
			if n.try_queue_build():
				return


func _try_call_wave() -> void:
	var wm := get_tree().get_first_node_in_group("wave_manager")
	if wm == null:
		wm = get_tree().current_scene.get_node_or_null("WaveManager") if get_tree().current_scene else null
	if wm and wm.has_method("call_early_wave"):
		wm.call("call_early_wave")


func _cycle_pad(dir: int) -> void:
	for n in _near_build:
		if n and n.has_method("cycle_type"):
			n.call("cycle_type", dir)
			return
	if TowerTypes:
		TowerTypes.cycle(dir)



func _try_attack() -> void:
	if _attack_cd > 0.0:
		return
	_attack_cd = attack_cooldown
	_flash_attack()
	if Sfx:
		Sfx.attack()
	var space := get_world_2d().direct_space_state
	var origin := global_position + _facing * 12.0
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = attack_range
	query.shape = circle
	query.transform = Transform2D(0.0, origin)
	query.collision_mask = 4
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hits := space.intersect_shape(query, 16)
	var hit_any := false
	for h in hits:
		var c: Object = h.get("collider")
		if c and c.has_method("take_damage"):
			c.take_damage(attack_damage)
			hit_any = true
	if hit_any and Juice:
		Juice.shake(3.0)
	if FX:
		FX.burst_particles(
			self,
			global_position + _facing * 20.0,
			Color(1.0, 0.95, 0.7, 0.9),
			6,
			"spark",
			0.28
		)


func _flash_attack() -> void:
	if _attack_arc == null:
		return
	_attack_arc.visible = true
	_attack_arc.rotation = _facing.angle()
	_attack_arc.modulate.a = 0.85
	var burst_pos := global_position + _facing * 22.0
	FX.burst_particles(
		get_parent(),
		burst_pos,
		Color(body_color.r, body_color.g, body_color.b, 0.9).lightened(0.2),
		10,
		"spark",
		0.32
	)
	var t := create_tween()
	t.tween_property(_attack_arc, "modulate:a", 0.0, 0.16)
	t.tween_callback(func() -> void:
		_attack_arc.visible = false
		_attack_arc.modulate.a = 1.0
	)


func register_gather(node: Node) -> void:
	if node not in _near_gather:
		_near_gather.append(node)


func unregister_gather(node: Node) -> void:
	_near_gather.erase(node)


func register_build(node: Node) -> void:
	if node not in _near_build:
		_near_build.append(node)


func unregister_build(node: Node) -> void:
	_near_build.erase(node)
