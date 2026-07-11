extends CharacterBody2D
class_name Warden
## Player warden — move, gather, queue build, attack. Full verb set.

@export var player_index: int = 0  ## 0 or 1 for p1/p2 actions
@export var move_speed: float = 220.0
@export var attack_damage: int = 18
@export var attack_cooldown: float = 0.28
@export var attack_range: float = 48.0
@export var body_color: Color = Color(0.55, 0.75, 0.95)

var _attack_cd: float = 0.0
var _facing: Vector2 = Vector2.DOWN
var _near_gather: Array[Node] = []
var _near_build: Array[Node] = []

@onready var _body: Polygon2D = $Body
@onready var _label: Label = $Label
@onready var _attack_flash: Polygon2D = $AttackFlash


func _ready() -> void:
	add_to_group("wardens")
	GameState.register_warden(self)
	_body.color = body_color
	_label.text = "P%d" % (player_index + 1)
	_attack_flash.visible = false
	collision_layer = 2
	collision_mask = 1


func _exit_tree() -> void:
	GameState.unregister_warden(self)


func _physics_process(delta: float) -> void:
	if GameState.is_game_over:
		velocity = Vector2.ZERO
		return

	_attack_cd = maxf(0.0, _attack_cd - delta)
	var dir := _read_move()
	if dir.length_squared() > 0.01:
		_facing = dir.normalized()
		velocity = dir.normalized() * move_speed
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
	# Isometric-ish feel: bias diagonal on diamond map
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
	query.collision_mask = 4  ## enemies
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hits := space.intersect_shape(query, 16)
	for h in hits:
		var c: Object = h.get("collider")
		if c and c.has_method("take_damage"):
			c.take_damage(attack_damage)


func _flash_attack() -> void:
	_attack_flash.visible = true
	_attack_flash.rotation = _facing.angle()
	var t := create_tween()
	t.tween_property(_attack_flash, "modulate:a", 0.0, 0.15).from(0.9)
	t.tween_callback(func() -> void:
		_attack_flash.visible = false
		_attack_flash.modulate.a = 1.0
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
