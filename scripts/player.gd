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
var _skin_modulate: Color = Color.WHITE
var _frame_flip_t: float = 0.0
var _frame_idx: int = 0
var _use_sprite: bool = false
## 2.5D anim sets from Kenney platformer characters
var _anim_idle: Array[Texture2D] = []
var _anim_walk: Array[Texture2D] = []
var _anim_jump: Array[Texture2D] = []
var _anim_fall: Array[Texture2D] = []
var _anim_attack: Array[Texture2D] = []
var _anim_name: String = "idle"
var _attack_anim_t: float = 0.0
var _sprite_base_scale: float = 1.05

## Hop / double-jump (top-down height sim)
var _height: float = 0.0
var _height_vel: float = 0.0
var _jumps_left: int = 2
var _was_airborne: bool = false
var _shadow: Polygon2D = null
var _aura_poly: Polygon2D = null
var _ground_y_bob: float = 0.0

## Swimming in lakes / ponds (PathNetwork water bodies)
var _swimming: bool = false
var _water_depth: float = 0.0
var _was_swimming: bool = false
var _swim_ripple: Polygon2D = null
var _water_clip: Polygon2D = null
var _splash_cd: float = 0.0

const BASE_GRAVITY := 1100.0
const SWIM_SPEED_MULT := 0.58
const SWIM_ACCEL_MULT := 0.7
const SWIM_FRICTION_MULT := 0.55

## Temporary burst powerups (activate in dire situations)
var _sprint_t: float = 0.0
var _sprint_cd: float = 0.0
var _sky_t: float = 0.0
var _sky_cd: float = 0.0
var _dire_cd: float = 0.0
var _sky_bonus_jumps: int = 0

@onready var _label: Label = $Label


func _ready() -> void:
	add_to_group("wardens")
	GameState.register_warden(self)
	# Top-down free roam: walk roads *and* open land. Nothing solid blocks wardens.
	motion_mode = MOTION_MODE_FLOATING
	collision_layer = 2  # player — Area2D interactables detect us
	collision_mask = 0   # no physics walls; land is open
	if has_node("Body"):
		$Body.visible = false
	if has_node("AttackFlash"):
		$AttackFlash.visible = false
	if has_node("Shadow"):
		$Shadow.visible = false

	_build_visuals()
	_jumps_left = Powers.max_jumps() if Powers else 2
	_label.text = "P%d" % (player_index + 1)
	if VisualStyle:
		VisualStyle.style_game_label(_label, 15, true)
		_label.add_theme_color_override("font_color", body_color.lightened(0.35))
	else:
		_label.add_theme_color_override("font_color", body_color.lightened(0.25))
		_label.add_theme_constant_override("outline_size", 5)
	_label.position = Vector2(-18, -52)
	_label.z_index = 20
	z_as_relative = false


func _build_visuals() -> void:
	_visual_root = Node2D.new()
	_visual_root.name = "Visual"
	add_child(_visual_root)

	var skin: Dictionary = AssetPaths.warden_skin(player_index)
	_skin_modulate = skin.get("modulate", body_color) as Color
	body_color = _skin_modulate
	_sprite_base_scale = float(skin.get("scale", 1.05))
	var glow_col: Color = skin.get("glow", Color(_skin_modulate.r, _skin_modulate.g, _skin_modulate.b, 0.35)) as Color
	_anim_idle = _tex_array(skin.get("idle", []))
	_anim_walk = _tex_array(skin.get("walk", skin.get("frames", [])))
	_anim_jump = _tex_array(skin.get("jump", []))
	_anim_fall = _tex_array(skin.get("fall", []))
	_anim_attack = _tex_array(skin.get("attack", []))
	if _anim_walk.is_empty():
		_anim_walk = _anim_idle.duplicate()
	if _anim_idle.is_empty():
		_anim_idle = _anim_walk.duplicate()

	# Soft ground shadow + layered ethereal aura (Dark Crystal living crystal)
	if VisualStyle:
		_shadow = VisualStyle.make_blob_shadow(_visual_root, 18, 8, 12)
	else:
		_shadow = FX.add_soft_shadow(_visual_root, 18, 8, 12)

	var aura_outer := FX.make_ellipse_poly(28, 32, 28, Color(glow_col.r, glow_col.g, glow_col.b, 0.12))
	aura_outer.z_index = -3
	_visual_root.add_child(aura_outer)
	var aura := FX.make_ellipse_poly(20, 24, 24, Color(_skin_modulate.r, _skin_modulate.g, _skin_modulate.b, 0.28))
	aura.z_index = -2
	_visual_root.add_child(aura)
	_aura_poly = aura
	var aura_core := FX.make_ellipse_poly(10, 12, 16, Color(1.0, 0.95, 0.85, 0.18))
	aura_core.z_index = -1
	_visual_root.add_child(aura_core)

	# Floating crystal shards around the warden
	for i in 3:
		var ang := TAU * float(i) / 3.0 - PI * 0.5
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([
			Vector2(0, -7), Vector2(3.5, -1), Vector2(0, 4), Vector2(-3.5, -1)
		])
		shard.color = _skin_modulate.lightened(0.25)
		shard.color.a = 0.75
		shard.position = Vector2(cos(ang), sin(ang) * 0.75) * 18.0 + Vector2(0, -10)
		shard.z_index = 2
		shard.name = "OrbitShard%d" % i
		_visual_root.add_child(shard)

	var start_tex: Texture2D = _anim_idle[0] if not _anim_idle.is_empty() else null
	if start_tex:
		_use_sprite = true
		_body_sprite = AssetPaths.make_pixel_sprite(start_tex, _sprite_base_scale)
		_body_sprite.modulate = _skin_modulate
		_body_sprite.centered = true
		_body_sprite.offset = Vector2(0, -float(start_tex.get_height()) * 0.18)
		_body_sprite.position = Vector2.ZERO
		_body_sprite.name = "BodySprite"
		_visual_root.add_child(_body_sprite)
		if VisualStyle:
			VisualStyle.apply_sprite_outline(_body_sprite, 1.45)
	else:
		_use_sprite = false
		_build_polygon_fallback()

	# Crystal crest above head
	var crest := Polygon2D.new()
	crest.polygon = PackedVector2Array([
		Vector2(0, -38), Vector2(5, -30), Vector2(2, -26), Vector2(0, -32),
		Vector2(-2, -26), Vector2(-5, -30)
	])
	crest.color = Color(0.95, 0.88, 0.55, 0.9) if player_index == 0 else Color(0.85, 0.7, 1.0, 0.9)
	crest.z_index = 3
	_visual_root.add_child(crest)

	_attack_arc = Polygon2D.new()
	_attack_arc.polygon = PackedVector2Array([
		Vector2(8, -16), Vector2(52, -10), Vector2(50, 10), Vector2(8, 14), Vector2(4, 0)
	])
	_attack_arc.color = Color(_skin_modulate.r, _skin_modulate.g, _skin_modulate.b, 0.65)
	_attack_arc.visible = false
	_visual_root.add_child(_attack_arc)


func _tex_array(v: Variant) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	if v is Array:
		for t in v:
			if t is Texture2D:
				out.append(t as Texture2D)
	return out


func _update_sprite_anim(delta: float) -> void:
	if not _use_sprite or _body_sprite == null:
		return
	if _attack_anim_t > 0.0:
		_attack_anim_t -= delta
	var desired := "idle"
	if _attack_anim_t > 0.0:
		desired = "attack"
	elif is_airborne():
		desired = "jump" if _height_vel > 40.0 else "fall"
	elif velocity.length() > 18.0:
		desired = "walk"
	else:
		desired = "idle"

	var frames: Array[Texture2D] = _anim_idle
	var rate := 0.28
	match desired:
		"walk":
			frames = _anim_walk
			rate = 0.14
		"jump":
			frames = _anim_jump
			rate = 0.2
		"fall":
			frames = _anim_fall
			rate = 0.2
		"attack":
			frames = _anim_attack
			rate = 0.1
		_:
			frames = _anim_idle
			rate = 0.35

	if frames.is_empty():
		return
	if desired != _anim_name:
		_anim_name = desired
		_frame_idx = 0
		_frame_flip_t = 0.0
		_body_sprite.texture = frames[0]
		return
	if frames.size() == 1:
		_body_sprite.texture = frames[0]
		return
	_frame_flip_t += delta
	if _frame_flip_t >= rate:
		_frame_flip_t = 0.0
		_frame_idx = (_frame_idx + 1) % frames.size()
		_body_sprite.texture = frames[_frame_idx]


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


func is_airborne() -> bool:
	return _height > 2.0


func is_swimming() -> bool:
	return _swimming


func _physics_process(delta: float) -> void:
	if GameState.is_game_over:
		velocity = Vector2.ZERO
		return

	_attack_cd = maxf(0.0, _attack_cd - delta)
	_splash_cd = maxf(0.0, _splash_cd - delta)
	_tick_bursts(delta)
	_update_water_state(delta)
	_bob_t += delta * (8.0 if velocity.length() > 10.0 else 3.0)
	_update_jump(delta)
	_update_power_auras(delta)

	var dir := _read_move()
	var air_control := 0.85 if is_airborne() else 1.0
	var speed_mult := BurstPowerups.SPRINT_MULT if _sprint_t > 0.0 else 1.0
	if _swimming and not is_airborne():
		speed_mult *= lerpf(SWIM_SPEED_MULT, 0.72, 1.0 - _water_depth)
		air_control *= SWIM_ACCEL_MULT
	var fric := move_friction * (SWIM_FRICTION_MULT if _swimming and not is_airborne() else 1.0)
	var accel := move_accel * air_control
	if dir.length_squared() > 0.01:
		_facing = dir.normalized()
		if absf(_facing.x) > 0.15:
			_face_sign = -1.0 if _facing.x < 0.0 else 1.0
		velocity = velocity.move_toward(
			dir.normalized() * move_speed * air_control * speed_mult,
			accel * delta
		)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, fric * delta)

	# Free roam on paths, open land, and water (swimmable).
	move_and_slide()
	global_position = GameState.clamp_world_position(global_position)
	# Always above ground props — Main must NOT y_sort the whole map layer
	if VisualStyle:
		z_index = VisualStyle.actor_z(global_position.y, _height)
	else:
		z_index = clampi(50 + int(global_position.y) + 2000, 50, 4000)

	_update_sprite_anim(delta)
	_update_swim_visuals(delta)

	if _visual_root:
		var swim_bob := 0.0
		if _swimming and not is_airborne():
			swim_bob = 3.0 + sin(_bob_t * 3.2) * 2.2 + _water_depth * 4.0
		_visual_root.position.y = -_height + swim_bob
		var squash := 1.0
		if is_airborne():
			squash = 1.0 - clampf(_height_vel / 700.0, -0.12, 0.1)
		elif _swimming:
			squash = 0.92 + 0.04 * sin(_bob_t * 4.0)
		_visual_root.scale = Vector2(_face_sign * squash, 1.0 / maxf(0.75, squash))
		if _shadow:
			var s := clampf(1.0 - _height / 120.0, 0.35, 1.0)
			if _swimming:
				s *= 0.45
			_shadow.scale = Vector2(s * absf(_face_sign), s)
			_shadow.modulate.a = (0.28 + 0.4 * s) * (0.35 if _swimming else 1.0)
		# Pulse aura + orbit crystal shards
		if _aura_poly:
			var pulse := 0.9 + 0.12 * sin(_bob_t * 1.6)
			_aura_poly.scale = Vector2(pulse, pulse)
			_aura_poly.modulate.a = 0.85 + 0.15 * sin(_bob_t * 2.2)
		for c in _visual_root.get_children():
			if str(c.name).begins_with("OrbitShard") and c is Node2D:
				var sh := c as Node2D
				var base_ang := float(str(c.name).substr(10).to_int()) * TAU / 3.0 - PI * 0.5
				var ang := base_ang + _bob_t * 1.1
				sh.position = Vector2(cos(ang), sin(ang) * 0.72) * 18.0 + Vector2(0, -10 + sin(_bob_t * 2.0 + ang) * 2.0)

	if _action_just_pressed("jump"):
		_try_jump()
	# Glide: hold jump while falling (negative height_vel) to cap fall speed
	if is_airborne() and _action_pressed("jump") and Powers and Powers.has("crystal_glide") and _height_vel < 0.0:
		_height_vel = maxf(_height_vel, -90.0)

	# Temporary powerups: Rush / Skybound / Dire Strike (per-player: p1_burst_* / p2_burst_*)
	if _action_just_pressed("burst_sprint"):
		_activate_sprint()
	if _action_just_pressed("burst_sky"):
		_activate_skybound()
	if _action_just_pressed("burst_dire"):
		_activate_dire_strike()

	if _action_just_pressed("gather") and not is_airborne():
		# Gather wins over sell when an essence node is in range (no accidental sells).
		if not _near_gather.is_empty():
			_try_gather(delta)
		else:
			# KR sell: tap E on a built pad only when not gathering.
			_try_sell_nearby()
	elif _action_pressed("gather") and not is_airborne():
		# Hold-to-gather only while grounded — never sell on hold.
		if not _near_gather.is_empty():
			_try_gather(delta)
	if _action_just_pressed("build"):
		_try_build()
	if _action_just_pressed("attack"):
		_try_attack()
	if Input.is_action_just_pressed("call_wave"):
		_try_call_wave()
	if Input.is_action_just_pressed("spawn_fairy") or _action_just_pressed("fairy"):
		_try_spawn_fairy()
	# Cycle tower pick anytime (Z/X or shoulders) — different pads can use different types
	if _action_just_pressed("cycle_left") or Input.is_action_just_pressed("cycle_left") \
			or (player_index == 0 and Input.is_action_just_pressed("ui_left")):
		_cycle_pad(-1)
	if _action_just_pressed("cycle_right") or Input.is_action_just_pressed("cycle_right") \
			or (player_index == 0 and Input.is_action_just_pressed("ui_right")):
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
			if n.try_queue_build(player_index):
				return


func _try_call_wave() -> void:
	var wm := get_tree().get_first_node_in_group("wave_manager")
	if wm == null:
		wm = get_tree().current_scene.get_node_or_null("WaveManager") if get_tree().current_scene else null
	if wm and wm.has_method("call_early_wave"):
		wm.call("call_early_wave")


func _cycle_pad(dir: int) -> void:
	## Per-player tower pick — cycle unlocked types, preview on nearby pad.
	## On a L1 Aetherbow pad, cycles PHYS/MAG upgrade branch instead.
	if TowerTypes == null:
		return
	# Prefer site-local cycle (handles branch on built dualshot)
	for n in _near_build:
		if n and n.has_method("cycle_type"):
			n.call("cycle_type", dir, player_index)
			return
	var id: String = TowerTypes.cycle_for_player(player_index, dir)
	var d: Dictionary = TowerTypes.def_for(id)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -36), str(d.get("name")), d.get("color"))


func _try_spawn_fairy() -> void:
	if GameState == null:
		return
	var f := GameState.try_spawn_fairy(global_position, player_index)
	if f and FX:
		FX.burst_particles(get_parent(), global_position + Vector2(0, -20), Color(0.8, 0.9, 1.0), 12, "star", 0.4)


func _tick_bursts(delta: float) -> void:
	if _sprint_t > 0.0:
		_sprint_t = maxf(0.0, _sprint_t - delta)
	if _sky_t > 0.0:
		_sky_t = maxf(0.0, _sky_t - delta)
		if _sky_t <= 0.0:
			_sky_bonus_jumps = 0
	_sprint_cd = maxf(0.0, _sprint_cd - delta)
	_sky_cd = maxf(0.0, _sky_cd - delta)
	_dire_cd = maxf(0.0, _dire_cd - delta)


func _activate_sprint() -> void:
	if _sprint_cd > 0.0 or GameState.is_game_over:
		return
	_sprint_t = BurstPowerups.SPRINT_DURATION
	_sprint_cd = BurstPowerups.SPRINT_CD
	GameState.message.emit("Rush!")
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -30), "RUSH", Color(1.0, 0.85, 0.3))
	if FX:
		FX.burst_particles(get_parent(), global_position, Color(1.0, 0.9, 0.4), 10, "star", 0.3)
	if Sfx:
		Sfx.build()
	if Juice:
		Juice.flash(Color(1.0, 0.9, 0.3, 0.15), 0.1)


func _activate_skybound() -> void:
	if _sky_cd > 0.0 or GameState.is_game_over:
		return
	_sky_t = BurstPowerups.SKY_DURATION
	_sky_cd = BurstPowerups.SKY_CD
	_sky_bonus_jumps = BurstPowerups.SKY_EXTRA_JUMPS
	_jumps_left = _max_jumps_now()
	GameState.message.emit("Skybound!")
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -30), "SKY", Color(0.6, 0.85, 1.0))
	if FX:
		FX.burst_particles(get_parent(), global_position, Color(0.6, 0.85, 1.0), 12, "magic", 0.35)
	if Sfx:
		Sfx.wave_start()


func _activate_dire_strike() -> void:
	if _dire_cd > 0.0 or GameState.is_game_over:
		return
	var target := _nearest_enemy(BurstPowerups.DIRE_RANGE)
	if target == null:
		GameState.message.emit("No foe in range for Dire Strike")
		return
	_dire_cd = BurstPowerups.DIRE_CD
	# Lunge toward target
	var to: Vector2 = target.global_position - global_position
	if to.length() > 1.0:
		global_position += to.normalized() * minf(BurstPowerups.DIRE_LUNGE, to.length() - 12.0)
		global_position = GameState.clamp_world_position(global_position)
	# Hop flourish
	if _height < 8.0:
		_height_vel = 220.0
		_height = maxf(_height, 4.0)
	if target.has_method("take_damage"):
		target.take_damage(BurstPowerups.DIRE_DAMAGE)
	FloatingText.spawn(get_parent(), target.global_position + Vector2(0, -20), str(BurstPowerups.DIRE_DAMAGE), Color(1.0, 0.4, 0.35))
	GameState.message.emit("Dire Strike!")
	if FX:
		FX.burst_particles(get_parent(), target.global_position, Color(1.0, 0.35, 0.4), 18, "spark", 0.4)
		FX.burst_particles(get_parent(), global_position, Color(1.0, 0.7, 0.5), 10, "magic", 0.3)
	if Juice:
		Juice.shake(7.0)
		Juice.flash(Color(1.0, 0.3, 0.25, 0.25), 0.12)
	if Sfx:
		Sfx.hit()
	# Brief attack arc flash
	_facing = to.normalized() if to.length() > 0.1 else _facing
	_flash_attack()


func _nearest_enemy(max_range: float) -> Node2D:
	var best: Node2D = null
	var best_d := max_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D:
			var d: float = global_position.distance_to(e.global_position)
			if d < best_d:
				best_d = d
				best = e
	return best


func _max_jumps_now() -> int:
	var base := Powers.max_jumps() if Powers else 2
	if _sky_t > 0.0:
		return base + _sky_bonus_jumps
	return base


func get_burst_status() -> Dictionary:
	return {
		"sprint_t": _sprint_t,
		"sprint_cd": _sprint_cd,
		"sky_t": _sky_t,
		"sky_cd": _sky_cd,
		"dire_cd": _dire_cd,
	}


func _update_water_state(_delta: float) -> void:
	_water_depth = 0.0
	if PathNetwork and PathNetwork.has_method("water_depth_at"):
		_water_depth = float(PathNetwork.water_depth_at(global_position))
	# Airborne over water doesn't count as swimming until you splash down
	_swimming = _water_depth > 0.08 and _height < 18.0
	if _swimming and not _was_swimming:
		_on_enter_water()
	elif not _swimming and _was_swimming:
		_on_exit_water()
	_was_swimming = _swimming


func _on_enter_water() -> void:
	# Cancel residual fall into a soft water settle
	if _height_vel < 0.0:
		_height_vel *= 0.2
	_height = minf(_height, 6.0)
	_spawn_water_splash(1.0)
	if Juice:
		Juice.flash(Color(0.35, 0.65, 0.9, 0.12), 0.1)


func _on_exit_water() -> void:
	_spawn_water_splash(0.55)
	if _body_sprite:
		_body_sprite.modulate = _skin_modulate
	if _water_clip and is_instance_valid(_water_clip):
		_water_clip.visible = false
	if _swim_ripple and is_instance_valid(_swim_ripple):
		_swim_ripple.visible = false


func _spawn_water_splash(strength: float = 1.0) -> void:
	if _splash_cd > 0.0:
		return
	_splash_cd = 0.18
	if FX:
		FX.burst_particles(
			get_parent() if get_parent() else self,
			global_position,
			Color(0.55, 0.85, 1.0, 0.75),
			int(10.0 * strength),
			"glow",
			0.35
		)
		FX.burst_particles(
			get_parent() if get_parent() else self,
			global_position,
			Color(0.7, 0.9, 1.0, 0.55),
			int(6.0 * strength),
			"spark",
			0.28
		)
	# Expanding ripple ring
	var ring := FX.make_ellipse_poly(12, 7, 18, Color(0.5, 0.85, 1.0, 0.45)) if FX else null
	if ring:
		ring.position = Vector2.ZERO
		ring.z_index = 8
		add_child(ring)
		var tw := create_tween()
		tw.tween_property(ring, "scale", Vector2(2.8 * strength, 1.8 * strength), 0.35)
		tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.35)
		tw.tween_callback(ring.queue_free)


func _update_swim_visuals(delta: float) -> void:
	if not _swimming:
		if _body_sprite and _body_sprite.modulate != _skin_modulate:
			_body_sprite.modulate = _body_sprite.modulate.lerp(_skin_modulate, clampf(delta * 8.0, 0.0, 1.0))
		return
	# Cool water tint while submerged
	if _body_sprite:
		var wet := _skin_modulate.lerp(Color(0.45, 0.75, 0.95), 0.28 + _water_depth * 0.2)
		_body_sprite.modulate = _body_sprite.modulate.lerp(wet, clampf(delta * 6.0, 0.0, 1.0))
	# Ripple under warden
	if _swim_ripple == null or not is_instance_valid(_swim_ripple):
		_swim_ripple = FX.make_ellipse_poly(16, 9, 18, Color(0.5, 0.85, 1.0, 0.3)) if FX else Polygon2D.new()
		if _swim_ripple.get_parent() == null:
			_swim_ripple.z_index = 6
			add_child(_swim_ripple)
	_swim_ripple.visible = true
	var move_n := clampf(velocity.length() / 120.0, 0.35, 1.4)
	_swim_ripple.scale = Vector2(0.9 + move_n * 0.35, 0.7 + move_n * 0.2) * (0.95 + 0.08 * sin(_bob_t * 5.0))
	_swim_ripple.modulate.a = 0.2 + 0.15 * move_n + 0.08 * sin(_bob_t * 4.0)
	# Soft water surface plane at waist
	if _water_clip == null or not is_instance_valid(_water_clip):
		_water_clip = FX.make_ellipse_poly(18, 8, 16, Color(0.25, 0.55, 0.7, 0.35)) if FX else Polygon2D.new()
		if _water_clip.get_parent() == null:
			_water_clip.z_index = 12
			add_child(_water_clip)
	_water_clip.visible = true
	_water_clip.position = Vector2(0, 6 + sin(_bob_t * 3.0) * 1.5)
	_water_clip.scale = Vector2(1.0 + _water_depth * 0.2, 0.85)
	_water_clip.modulate.a = 0.22 + _water_depth * 0.2
	# Moving splash trail
	if velocity.length() > 40.0 and _splash_cd <= 0.0 and randf() < 0.12:
		_spawn_water_splash(0.35)


func _try_jump() -> void:
	var max_j := _max_jumps_now()
	if _jumps_left <= 0:
		return
	var is_double := _height > 4.0 or _jumps_left < max_j
	_jumps_left -= 1
	var jv := Powers.jump_velocity() if Powers else 380.0
	if _sky_t > 0.0:
		jv *= BurstPowerups.SKY_JUMP_MULT
	# Leap from water surface
	if _swimming and not is_double:
		jv *= 0.88
		_spawn_water_splash(0.85)
	_height_vel = jv
	if is_double:
		_height_vel *= 0.92
		if FX:
			FX.burst_particles(get_parent(), global_position, Color(0.7, 0.85, 1.0), 8, "star", 0.25)
	if Sfx:
		Sfx.attack()


func _update_jump(delta: float) -> void:
	# _height_vel: positive = rising, negative = falling
	var g_scale := Powers.gravity_scale() if Powers else 1.0
	var g := BASE_GRAVITY * g_scale
	# Water cushions falls
	if _swimming and _height_vel < 0.0:
		g *= 0.45
		_height_vel = maxf(_height_vel, -160.0)
	if _height > 0.0 or _height_vel != 0.0:
		_height_vel -= g * delta
		_height += _height_vel * delta
		if _height <= 0.0:
			var was_high := _was_airborne and _height_vel < -200.0
			var from_double := _jumps_left == 0
			_height = 0.0
			_height_vel = 0.0
			_jumps_left = _max_jumps_now()
			if _was_airborne:
				_on_landed(was_high, from_double)
			_was_airborne = false
		else:
			_was_airborne = true
	else:
		_jumps_left = _max_jumps_now()
		_was_airborne = false


func _on_landed(hard: bool, from_air_jump: bool) -> void:
	if _swimming or (PathNetwork and PathNetwork.has_method("in_water") and PathNetwork.in_water(global_position)):
		_spawn_water_splash(1.15 if hard else 0.7)
		return
	if FX:
		FX.burst_particles(get_parent(), global_position, Color(0.6, 0.8, 0.5, 0.5), 6, "puff", 0.2)
	if Powers and Powers.has("pollen_burst"):
		_spawn_pollen_cloud()
	if Powers and Powers.has("stomp") and (hard or from_air_jump):
		_stomp_damage()


func _spawn_pollen_cloud() -> void:
	if FX:
		FX.burst_particles(get_parent(), global_position, Color(0.85, 0.7, 1.0, 0.7), 16, "star", 0.45)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and global_position.distance_to(e.global_position) < 90.0:
			if e.has_method("apply_slow"):
				e.call("apply_slow", 0.55, 1.4)


func _stomp_damage() -> void:
	if Juice:
		Juice.shake(5.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and global_position.distance_to(e.global_position) < 70.0:
			if e.has_method("take_damage"):
				e.call("take_damage", 22)
				FloatingText.spawn(get_parent(), e.global_position, "22", Color(0.5, 1.0, 0.55))


func _update_power_auras(delta: float) -> void:
	if _aura_poly and Powers:
		if Powers.has("low_gravity"):
			_aura_poly.color = Color(0.6, 0.75, 1.0, 0.2 + 0.08 * sin(_bob_t * 2.0))
			_aura_poly.scale = Vector2.ONE * (1.15 + 0.1 * sin(_bob_t))
		elif Powers.has("loot_magnet"):
			_aura_poly.color = Color(1.0, 0.85, 0.4, 0.15)
		else:
			_aura_poly.color = Color(_skin_modulate.r, _skin_modulate.g, _skin_modulate.b, 0.16)
			_aura_poly.scale = Vector2.ONE
	# Loot magnet while airborne
	if Powers and Powers.has("loot_magnet") and is_airborne():
		for loot in get_tree().get_nodes_in_group("loot"):
			if loot is Node2D and global_position.distance_to(loot.global_position) < 120.0:
				loot.global_position = loot.global_position.lerp(global_position, 1.0 - exp(-8.0 * delta))
				if loot.global_position.distance_to(global_position) < 28.0 and loot.has_method("collect"):
					loot.collect()



func _try_attack() -> void:
	if _attack_cd > 0.0:
		return
	_attack_cd = attack_cooldown
	_attack_anim_t = 0.22
	_anim_name = ""  # force anim refresh
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
