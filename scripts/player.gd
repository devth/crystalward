extends CharacterBody2D
class_name Warden
## Player warden — move, gather, queue build, attack. Full verb set.

@export var player_index: int = 0
@export var move_speed: float = 220.0
@export var attack_damage: int = 18
@export var attack_cooldown: float = 0.28
@export var attack_range: float = 48.0
@export var body_color: Color = Color(0.55, 0.75, 0.95)

var _attack_cd: float = 0.0
var _facing: Vector2 = Vector2.DOWN
var _near_gather: Array[Node] = []
var _near_build: Array[Node] = []
var _visual_root: Node2D
var _cloak: Polygon2D
var _mask: Polygon2D
var _attack_arc: Polygon2D
var _bob_t: float = 0.0

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
	_label.add_theme_color_override("font_color", body_color.lightened(0.25))
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.1, 0.9))
	_label.add_theme_constant_override("outline_size", 4)
	_label.position = Vector2(-18, -48)
	_label.z_index = 10


func _build_visuals() -> void:
	_visual_root = Node2D.new()
	_visual_root.name = "Visual"
	add_child(_visual_root)
	FX.add_soft_shadow(_visual_root, 16, 7, 12)

	# Cloak / body
	_cloak = Polygon2D.new()
	_cloak.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(12, -12), Vector2(14, 4), Vector2(8, 16),
		Vector2(0, 14), Vector2(-8, 16), Vector2(-14, 4), Vector2(-12, -12)
	])
	_cloak.color = body_color.darkened(0.15)
	_visual_root.add_child(_cloak)

	var trim := Polygon2D.new()
	trim.polygon = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(6, 6), Vector2(-6, 6)
	])
	trim.color = body_color.lightened(0.1)
	_visual_root.add_child(trim)

	# Ritual mask
	_mask = Polygon2D.new()
	_mask.polygon = PackedVector2Array([
		Vector2(0, -26), Vector2(9, -18), Vector2(7, -8), Vector2(0, -4),
		Vector2(-7, -8), Vector2(-9, -18)
	])
	_mask.color = Color(0.85, 0.8, 0.95).lerp(body_color, 0.35)
	_visual_root.add_child(_mask)

	var eye_l := FX.make_ellipse_poly(2.2, 2.8, 10, Color(0.95, 0.9, 0.5, 0.95))
	eye_l.position = Vector2(-3.5, -16)
	_visual_root.add_child(eye_l)
	var eye_r := FX.make_ellipse_poly(2.2, 2.8, 10, Color(0.95, 0.9, 0.5, 0.95))
	eye_r.position = Vector2(3.5, -16)
	_visual_root.add_child(eye_r)

	# Staff crystal
	var staff := Line2D.new()
	staff.width = 2.5
	staff.default_color = Color(0.35, 0.3, 0.28)
	staff.points = PackedVector2Array([Vector2(12, 8), Vector2(16, -18)])
	_visual_root.add_child(staff)
	var gem := Polygon2D.new()
	gem.polygon = PackedVector2Array([
		Vector2(16, -26), Vector2(20, -18), Vector2(16, -14), Vector2(12, -18)
	])
	gem.color = Color(0.65, 0.9, 0.8, 0.95).lerp(body_color, 0.3)
	gem.name = "StaffGem"
	_visual_root.add_child(gem)

	_attack_arc = Polygon2D.new()
	_attack_arc.polygon = PackedVector2Array([
		Vector2(6, -14), Vector2(46, -6), Vector2(44, 8), Vector2(6, 12)
	])
	_attack_arc.color = Color(body_color.r, body_color.g, body_color.b, 0.55)
	_attack_arc.visible = false
	_visual_root.add_child(_attack_arc)

	# Soft personal glow
	var glow := FX.make_ellipse_poly(20, 24, 20, Color(body_color.r, body_color.g, body_color.b, 0.12))
	glow.z_index = -1
	_visual_root.add_child(glow)


func _exit_tree() -> void:
	GameState.unregister_warden(self)


func _physics_process(delta: float) -> void:
	if GameState.is_game_over:
		velocity = Vector2.ZERO
		return

	_attack_cd = maxf(0.0, _attack_cd - delta)
	_bob_t += delta * (8.0 if velocity.length() > 10.0 else 3.0)
	if _visual_root:
		_visual_root.position.y = sin(_bob_t) * (2.2 if velocity.length() > 10.0 else 1.0)
		if has_node("Visual/StaffGem"):
			var gem: Polygon2D = $Visual/StaffGem
			gem.modulate = Color(1, 1, 1, 0.75 + 0.25 * sin(_bob_t * 1.3))

	var dir := _read_move()
	if dir.length_squared() > 0.01:
		_facing = dir.normalized()
		velocity = dir.normalized() * move_speed
		if _visual_root:
			_visual_root.scale.x = -1.0 if _facing.x < -0.15 else 1.0
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	z_index = int(global_position.y)

	if _action_pressed("gather"):
		_try_gather(delta)
	if _action_just_pressed("build"):
		_try_build()
	if _action_just_pressed("attack"):
		_try_attack()


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


func _try_build() -> void:
	for n in _near_build:
		if n and n.has_method("try_queue_build"):
			if n.try_queue_build():
				return


func _try_attack() -> void:
	if _attack_cd > 0.0:
		return
	_attack_cd = attack_cooldown
	_flash_attack()
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
	for h in hits:
		var c: Object = h.get("collider")
		if c and c.has_method("take_damage"):
			c.take_damage(attack_damage)


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
