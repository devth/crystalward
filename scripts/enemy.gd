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
var kind_id: String = "thrall"
## Air units ignore ground-only towers / roots; path still follows the road.
var is_flying: bool = false
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
var _kind_skin_key: String = ""
var _sep_radius: float = 48.0
var _min_path_gap: float = 70.0
var _kind_color: Color = Color(0.85, 0.3, 0.45)

var _lane: PackedVector2Array = PackedVector2Array()
var _path_dist: float = 0.0
var _lane_len: float = 0.0
var _lateral: float = 0.0
var _is_elite: bool = false
var _is_boss: bool = false
var _leak_lives: int = 1
var _face_sign: float = 1.0
var _slow: float = 0.0
var _slow_t: float = 0.0
var _mark_mult: float = 1.0
var _mark_t: float = 0.0
var _root_t: float = 0.0
var _move_dir: Vector2 = Vector2.DOWN
var _configured_kind: bool = false
var _garrison_cd: float = 0.0
var _garrison_target: Node2D = null

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

	if not _configured_kind and EnemyKinds:
		configure_kind(EnemyKinds.kind_for_wave(1))
	_lateral = randf_range(-path_slack, path_slack)
	if _lane.is_empty() and PathNetwork:
		assign_lane(PathNetwork.random_lane())

	_build_visuals()
	var bar_col := _kind_color
	FX.style_progress_bar(_bar, bar_col, Color(0.1, 0.04, 0.08, 0.85))
	_bar.max_value = max_hp
	_bar.value = hp
	if is_flying:
		_bar.position = Vector2(-18, -52)
		_bar.size = Vector2(36, 7)
		# AIR tag so flyers read at a glance
		var air_tag := Label.new()
		air_tag.name = "AirTag"
		air_tag.text = "AIR"
		air_tag.position = Vector2(-12, -64)
		air_tag.add_theme_font_size_override("font_size", 9)
		air_tag.add_theme_color_override("font_color", Color(0.7, 0.92, 1.0))
		air_tag.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.15, 0.95))
		air_tag.add_theme_constant_override("outline_size", 2)
		add_child(air_tag)
	else:
		_bar.position = Vector2(-18, -36)
		_bar.size = Vector2(36, 7)
	if _is_elite:
		_bar.size = Vector2(48, 8)
		_bar.position = Vector2(-24, -52 if is_flying else -42)
	_crystal = get_tree().get_first_node_in_group("crystal") as Node2D


## Apply wave kind stats. Call BEFORE add_child when possible; safe after too if visuals not built.
func configure_kind(id: String, base_hp: int = -1, base_speed: float = -1.0) -> void:
	kind_id = id
	_configured_kind = true
	var d: Dictionary = EnemyKinds.def_for(id) if EnemyKinds else {}
	var hp_m := float(d.get("hp_mult", 1.0))
	var spd_m := float(d.get("speed_mult", 1.0))
	if base_hp > 0:
		max_hp = maxi(8, int(float(base_hp) * hp_m))
	else:
		max_hp = maxi(8, int(float(max_hp) * hp_m))
	if base_speed > 0.0:
		move_speed = maxf(24.0, base_speed * spd_m)
	else:
		move_speed = maxf(24.0, move_speed * spd_m)
	path_slack = float(d.get("path_slack", path_slack))
	_sep_radius = float(d.get("sep_radius", 48.0))
	_min_path_gap = float(d.get("min_path_gap", 70.0))
	_kind_skin_key = str(d.get("skin", ""))
	_kind_color = d.get("color", Color(0.85, 0.3, 0.45)) as Color
	is_flying = bool(d.get("flying", false))
	_is_boss = bool(d.get("boss", false))
	_leak_lives = maxi(1, int(d.get("leak_lives", 1)))
	var cdm := float(d.get("crystal_damage_mult", 1.0))
	crystal_damage = maxi(1, int(float(crystal_damage) * cdm))
	var sc_m := float(d.get("scale_mult", 1.0))
	if sc_m != 1.0 and sc_m > 0.0:
		scale = Vector2.ONE * sc_m
	var sm := float(d.get("scale_mult", 1.0))
	if sm != 1.0:
		scale = Vector2(sm, sm)
	if is_inside_tree() and is_instance_valid(_bar):
		hp = max_hp
		_bar.max_value = max_hp
		_bar.value = hp


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
	if _is_boss:
		return
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


func make_boss() -> void:
	## Large slow champion — called after configure_kind + enter tree.
	_is_boss = true
	_is_elite = false
	# Ensure HP bar / label match boss scale
	if _bar:
		_bar.size = Vector2(72, 10)
		_bar.position = Vector2(-36, -52)
		_bar.max_value = max_hp
		_bar.value = hp
	if has_node("AirTag"):
		$AirTag.queue_free()
	var tag := Label.new()
	tag.name = "BossTag"
	tag.text = "BOSS"
	tag.position = Vector2(-18, -68)
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	tag.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.1, 0.95))
	tag.add_theme_constant_override("outline_size", 3)
	add_child(tag)
	var name_l := Label.new()
	name_l.name = "BossName"
	name_l.text = EnemyKinds.display_name(kind_id) if EnemyKinds else kind_id
	name_l.position = Vector2(-48, -82)
	name_l.add_theme_font_size_override("font_size", 11)
	name_l.add_theme_color_override("font_color", Color(0.95, 0.9, 1.0))
	name_l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	name_l.add_theme_constant_override("outline_size", 3)
	add_child(name_l)
	if _visual:
		var crown := Polygon2D.new()
		crown.polygon = PackedVector2Array([
			Vector2(-16, -28), Vector2(-8, -42), Vector2(0, -34), Vector2(8, -42),
			Vector2(16, -28), Vector2(10, -24), Vector2(0, -30), Vector2(-10, -24)
		])
		crown.color = Color(0.55, 0.35, 0.72, 0.9)
		crown.z_index = 5
		_visual.add_child(crown)
		var ring := FX.make_ellipse_poly(36, 20, 28, Color(0.65, 0.4, 0.9, 0.22))
		ring.z_index = -1
		_visual.add_child(ring)
	if _body_sprite and VisualStyle:
		VisualStyle.apply_sprite_outline(_body_sprite, 2.0)
	if Juice:
		Juice.shake(6.0)
	if GameState:
		GameState.message.emit("☠ %s enters the path" % (EnemyKinds.display_name(kind_id) if EnemyKinds else "Boss"))


func _build_visuals() -> void:
	_visual = Node2D.new()
	add_child(_visual)

	# Ground shadow stays on the path (flyers cast a drop-shadow below)
	var shadow_parent := Node2D.new()
	shadow_parent.name = "GroundShadow"
	shadow_parent.z_index = -5
	add_child(shadow_parent)
	if is_flying:
		FX.add_soft_shadow(shadow_parent, 14, 6, 10)
		var pad := FX.make_ellipse_poly(16, 7, 16, Color(0.2, 0.35, 0.55, 0.18))
		pad.position = Vector2(0, 10)
		shadow_parent.add_child(pad)
	else:
		FX.add_soft_shadow(shadow_parent, 18, 8, 12)

	var skin: Dictionary
	if _kind_skin_key != "" and AssetPaths and AssetPaths.has_method("skin_for_kind"):
		skin = AssetPaths.skin_for_kind(_kind_skin_key)
	else:
		skin = AssetPaths.random_enemy_skin() if AssetPaths else {}
	_skin_modulate = skin.get("modulate", _kind_color) as Color
	# Tint toward kind color for wave identity
	_skin_modulate = _skin_modulate.lerp(_kind_color, 0.35)
	_sprite_scale = float(skin.get("scale", 0.85))
	var aura_col: Color = skin.get("aura", Color(_kind_color.r, _kind_color.g, _kind_color.b, 0.3)) as Color
	aura_col = aura_col.lerp(_kind_color, 0.4)
	aura_col.a = 0.32 if not is_flying else 0.4
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
		_skin_modulate = _skin_modulate.lightened(0.15)
		_sprite_scale *= 1.28
		aura_col = Color(1.0, 0.55, 0.25, 0.38)

	# Soft corruption / flight aura
	var aura := FX.make_ellipse_poly(22 if not _is_elite else 28, 14 if not _is_elite else 18, 22, aura_col)
	aura.z_index = -2
	aura.name = "CorruptAura"
	_visual.add_child(aura)

	if is_flying:
		# Ethereal wing silhouettes — flap in _finish_frame
		_wings.clear()
		for sx in [-1.0, 1.0]:
			var wing := Polygon2D.new()
			wing.polygon = PackedVector2Array([
				Vector2(0, -6), Vector2(sx * 22, -14), Vector2(sx * 18, 2), Vector2(sx * 6, 4)
			])
			wing.color = Color(_kind_color.r, _kind_color.g, _kind_color.b, 0.55)
			wing.position = Vector2(sx * 4, -4)
			wing.z_index = -1
			wing.name = "Wing"
			_visual.add_child(wing)
			_wings.append(wing)
		# Soft flight trail
		var trail := FX.make_ellipse_poly(10, 16, 14, Color(_kind_color.r, _kind_color.g, _kind_color.b, 0.12))
		trail.position = Vector2(0, 10)
		trail.z_index = -3
		_visual.add_child(trail)

	if _is_elite:
		var ring := FX.make_ellipse_poly(26, 16, 22, Color(1.0, 0.55, 0.25, 0.28))
		ring.z_index = -1
		_visual.add_child(ring)
		for sx in [-1.0, 1.0]:
			var horn := Polygon2D.new()
			horn.polygon = PackedVector2Array([
				Vector2(0, -22), Vector2(sx * 6, -34), Vector2(sx * 3, -18)
			])
			horn.color = Color(0.95, 0.5, 0.3, 0.9)
			horn.z_index = 2
			_visual.add_child(horn)

	if not _skin_frames.is_empty() and _skin_frames[0] != null:
		_use_sprite = true
		_body_sprite = AssetPaths.make_pixel_sprite(_skin_frames[0], _sprite_scale)
		_body_sprite.modulate = _skin_modulate
		_body_sprite.centered = true
		_body_sprite.offset = Vector2(0, -float(_skin_frames[0].get_height()) * 0.18)
		_body_sprite.position = Vector2.ZERO
		_visual.add_child(_body_sprite)
		_apply_outline()
		return

	_body_poly = Polygon2D.new()
	_body_poly.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(12, -8), Vector2(14, 6), Vector2(5, 16),
		Vector2(-5, 16), Vector2(-14, 6), Vector2(-12, -8)
	])
	_body_poly.color = Color(0.48, 0.12, 0.3)
	_visual.add_child(_body_poly)


func _apply_outline() -> void:
	if _body_sprite == null or VisualStyle == null:
		return
	var w := 1.55 if _is_elite else 1.35
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
	if _root_t > 0.0:
		_root_t -= delta

	var spd := move_speed * (1.0 - clampf(_slow, 0.0, 0.7))
	if _root_t > 0.0:
		spd = 0.0

	# Ground foes stop to fight garrison soldiers on the road
	if not is_flying and _try_fight_garrison(delta):
		_finish_frame()
		return

	# Lateral separation only — stay on the road, don't shove off-path
	_apply_lateral_separation(delta)
	# Keep spacing along the path so packs don't form a single blob
	spd = _path_gap_speed(spd, delta)

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


func _try_fight_garrison(delta: float) -> bool:
	## Return true if this frame is spent meleeing a garrison unit (blocked).
	var unit := _nearest_garrison(58.0)
	if unit == null:
		_garrison_target = null
		return false
	_garrison_target = unit
	velocity = Vector2.ZERO
	_move_dir = (unit.global_position - global_position).normalized()
	_garrison_cd = maxf(0.0, _garrison_cd - delta)
	if _garrison_cd <= 0.0:
		_garrison_cd = 0.65
		var dmg := maxi(3, int(float(crystal_damage) * 0.85))
		if unit.has_method("take_damage"):
			unit.call("take_damage", dmg)
		if FloatingText:
			FloatingText.spawn(get_parent(), unit.global_position + Vector2(0, -18), str(dmg), Color(0.95, 0.45, 0.4))
	return true


func _nearest_garrison(max_dist: float) -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var best: Node2D = null
	var best_d := max_dist * max_dist
	for u in tree.get_nodes_in_group("garrison_units"):
		if not (u is Node2D) or not is_instance_valid(u):
			continue
		if u.has_method("is_blocking") and not bool(u.call("is_blocking")):
			continue
		var d2: float = global_position.distance_squared_to(u.global_position)
		if d2 < best_d:
			best_d = d2
			best = u
	return best


func _apply_lateral_separation(_delta: float) -> void:
	var push := 0.0
	var r := _sep_radius
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not (e is Node2D):
			continue
		var d: Vector2 = global_position - e.global_position
		var dist := d.length()
		if dist > 0.1 and dist < r:
			# Fan left/right across the road so packs don't stack in one lane stripe
			var side := signf(d.x) if absf(d.x) > 0.35 else (1.0 if hash(get_instance_id()) % 2 == 0 else -1.0)
			if absf(_lateral) < 4.0:
				side = 1.0 if (get_instance_id() % 2) == 0 else -1.0
			push += side * (1.0 - dist / r) * 16.0
	_lateral = clampf(_lateral + push * 0.14, -path_slack * 1.45, path_slack * 1.45)


func _path_gap_speed(spd: float, delta: float) -> float:
	## Don't close within min_path_gap of the unit ahead on the same road.
	if spd <= 0.0 or delta <= 0.0:
		return spd
	var gap := _min_path_gap
	var best_ahead := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not is_instance_valid(e):
			continue
		var td: float = -1.0
		if e.has_method("get_path_dist"):
			td = float(e.call("get_path_dist"))
		else:
			continue
		if td > _path_dist and td < best_ahead:
			best_ahead = td
	if best_ahead < INF:
		var room: float = best_ahead - _path_dist - gap
		if room < spd * delta:
			return maxf(0.0, room / delta)
	return spd


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
	# Bosses can cost multiple lives when they reach the Lightwell
	var lives := _leak_lives if _is_boss else 1
	for _i in lives:
		GameState.damage_crystal(crystal_damage)
	if _is_boss and GameState:
		GameState.message.emit("☠ %s breached the Lightwell (−%d ♥)" % [
			EnemyKinds.display_name(kind_id) if EnemyKinds else "Boss", lives
		])
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
		# Flyers hover well above the path; ground units stay locked
		var hover := (-22.0 + sin(_anim_t * 2.6) * 4.5) if is_flying else 0.0
		_visual.position.y = hover
		if _move_dir.x < -0.12:
			_face_sign = -1.0
		elif _move_dir.x > 0.12:
			_face_sign = 1.0
		# Rooted: squash + green tint; normal face flip
		var ys := 1.0
		if _root_t > 0.0:
			ys = 0.82
			if _body_sprite:
				_body_sprite.modulate = _skin_modulate.lerp(Color(0.35, 0.75, 0.4), 0.45)
		elif _body_sprite and _body_sprite.modulate != _skin_modulate:
			_body_sprite.modulate = _body_sprite.modulate.lerp(_skin_modulate, 0.2)
		_visual.scale = Vector2(_face_sign, ys)
		var aura := _visual.get_node_or_null("CorruptAura")
		if aura is Node2D:
			var p := 0.92 + 0.1 * sin(_anim_t * 3.0)
			(aura as Node2D).scale = Vector2(p, p)
		# Flap wings
		for w in _wings:
			if is_instance_valid(w):
				var side := 1.0 if w.position.x >= 0.0 else -1.0
				w.rotation = side * sin(_anim_t * 9.0) * 0.35
				w.scale.y = 0.85 + 0.2 * absf(sin(_anim_t * 9.0))
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
	if EnemyKinds:
		var d: Dictionary = EnemyKinds.def_for(kind_id)
		if "mist" in d.get("resist_channels", []):
			amount *= 0.4
			duration *= 0.6
		if "slow_aura" in d.get("resist_specials", []) or "aura_slow" in d.get("resist_specials", []):
			amount *= 0.5
	# Flyers still slow, but less (harder to pin)
	if is_flying:
		amount *= 0.75
	_slow = maxf(_slow, amount)
	_slow_t = maxf(_slow_t, duration)


func apply_mark(mult: float, duration: float) -> void:
	if EnemyKinds:
		var d: Dictionary = EnemyKinds.def_for(kind_id)
		if "mark" in d.get("resist_specials", []):
			mult = 1.0 + (mult - 1.0) * 0.35
	_mark_mult = maxf(_mark_mult, mult)
	_mark_t = maxf(_mark_t, duration)


func apply_root(duration: float) -> void:
	# Roots cannot grab air units
	if is_flying:
		return
	if EnemyKinds:
		var d: Dictionary = EnemyKinds.def_for(kind_id)
		if "root" in d.get("resist_specials", []) or "thorn" in d.get("resist_channels", []):
			if "root" in d.get("resist_specials", []):
				return
			duration *= 0.45
	_root_t = maxf(_root_t, duration)


func is_rooted() -> bool:
	return _root_t > 0.0


func is_marked() -> bool:
	return _mark_t > 0.0 and _mark_mult > 1.0


func is_elite() -> bool:
	return _is_elite


func is_boss() -> bool:
	return _is_boss


func get_leak_lives() -> int:
	return _leak_lives


func is_air() -> bool:
	return is_flying


func is_ground() -> bool:
	return not is_flying


func get_kind_id() -> String:
	return kind_id


func get_path_dist() -> float:
	return _path_dist


## Apply tower matchup. channel/special/role from tower def.
func damage_mult_from_tower(channel: String, special: String, role: String) -> float:
	if EnemyKinds:
		return EnemyKinds.damage_mult(kind_id, channel, special, role)
	return 1.0


func take_damage(amount: int, from_channel: String = "", from_special: String = "", from_role: String = "") -> void:
	var matchup := 1.0
	if from_channel != "" or from_special != "" or from_role != "":
		matchup = damage_mult_from_tower(from_channel, from_special, from_role)
		amount = maxi(1, int(float(amount) * matchup))
	if is_marked():
		amount = int(amount * _mark_mult)
	hp -= amount
	_bar.value = hp
	# Flash: gold on strong matchup, steel on resist
	var flash := Color(1.8, 1.5, 1.5)
	if matchup >= 1.35:
		flash = Color(1.6, 1.9, 0.7)
	elif matchup <= 0.65:
		flash = Color(0.7, 0.75, 1.0)
	if _body_sprite:
		_body_sprite.modulate = flash
		var t := create_tween()
		t.tween_property(_body_sprite, "modulate", _skin_modulate, 0.12)
	elif _body_poly:
		_body_poly.modulate = flash
		var t2 := create_tween()
		t2.tween_property(_body_poly, "modulate", Color.WHITE, 0.12)
	if Sfx:
		Sfx.hit()
	if Juice and amount >= 12:
		Juice.shake(2.5)
	if hp <= 0:
		_die()


func _die() -> void:
	if _is_boss:
		GameState.reward_kill(true, global_position, true)
		if GameState:
			GameState.message.emit("✦ %s falls. The Lightwell holds." % (
				EnemyKinds.display_name(kind_id) if EnemyKinds else "Boss"
			))
		if Juice:
			Juice.shake(14.0)
			Juice.flash(Color(0.75, 0.55, 0.95, 0.4), 0.25)
	else:
		GameState.reward_kill(_is_elite, global_position, false)
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
