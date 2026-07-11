extends CharacterBody2D
class_name Nightspawn
## Nightspawn — walks toward crystal, damages it on contact.

@export var max_hp: int = 40
@export var move_speed: float = 70.0
@export var crystal_damage: int = 8
@export var dust_drop_chance: float = 0.15

var hp: int
var _crystal: Node2D

@onready var _body: Polygon2D = $Body
@onready var _bar: ProgressBar = $HpBar


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	_bar.max_value = max_hp
	_bar.value = hp
	_crystal = get_tree().get_first_node_in_group("crystal") as Node2D


func _physics_process(delta: float) -> void:
	if GameState.is_game_over:
		velocity = Vector2.ZERO
		return
	if _crystal == null or not is_instance_valid(_crystal):
		_crystal = get_tree().get_first_node_in_group("crystal") as Node2D
		return

	var target: Vector2 = _crystal.global_position
	var to := target - global_position
	if to.length() < 28.0:
		GameState.damage_crystal(crystal_damage)
		queue_free()
		return

	velocity = to.normalized() * move_speed
	move_and_slide()
	z_index = int(global_position.y)
	_body.rotation = to.angle() + PI * 0.5


func take_damage(amount: int) -> void:
	hp -= amount
	_bar.value = hp
	_body.modulate = Color(1.5, 1.5, 1.5)
	var t := create_tween()
	t.tween_property(_body, "modulate", Color.WHITE, 0.1)
	if hp <= 0:
		_die()


func _die() -> void:
	if randf() < dust_drop_chance:
		GameState.add_crystal_dust(1)
		GameState.message.emit("+1 Crystal dust")
	queue_free()
