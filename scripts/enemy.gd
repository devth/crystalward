extends CharacterBody2D
class_name Nightspawn
## Nightspawn — walks toward crystal, damages it on contact.

@export var max_hp: int = 40
@export var move_speed: float = 70.0
@export var crystal_damage: int = 8
@export var dust_drop_chance: float = 0.15

var hp: int
var _crystal: Node2D
var _visual: Node2D
var _body_poly: Polygon2D
var _wings: Array[Polygon2D] = []
var _anim_t: float = 0.0

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

	_build_visuals()
	FX.style_progress_bar(_bar, Color(0.85, 0.25, 0.4), Color(0.1, 0.04, 0.08, 0.85))
	_bar.max_value = max_hp
	_bar.value = hp
	_bar.position = Vector2(-18, -34)
	_bar.size = Vector2(36, 7)
	_crystal = get_tree().get_first_node_in_group("crystal") as Node2D


func _build_visuals() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	FX.add_soft_shadow(_visual, 14, 6, 10)

	var aura := FX.make_ellipse_poly(18, 14, 18, Color(0.55, 0.1, 0.25, 0.2))
	aura.z_index = -1
	_visual.add_child(aura)

	_body_poly = Polygon2D.new()
	_body_poly.polygon = PackedVector2Array([
		Vector2(0, -16), Vector2(10, -6), Vector2(12, 6), Vector2(4, 14),
		Vector2(-4, 14), Vector2(-12, 6), Vector2(-10, -6)
	])
	_body_poly.color = Color(0.42, 0.12, 0.28)
	_visual.add_child(_body_poly)

	var belly := Polygon2D.new()
	belly.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(5, 2), Vector2(0, 10), Vector2(-5, 2)
	])
	belly.color = Color(0.55, 0.18, 0.32)
	_visual.add_child(belly)

	# Mandible / horns
	for side in [-1.0, 1.0]:
		var horn := Polygon2D.new()
		horn.polygon = PackedVector2Array([
			Vector2(side * 6, -10), Vector2(side * 14, -20), Vector2(side * 8, -8)
		])
		horn.color = Color(0.25, 0.08, 0.18)
		_visual.add_child(horn)

	var eye := FX.make_ellipse_poly(3.5, 4.5, 12, Color(0.95, 0.25, 0.35))
	eye.position = Vector2(0, -6)
	_visual.add_child(eye)
	var pupil := FX.make_ellipse_poly(1.4, 1.8, 8, Color(0.15, 0.02, 0.05))
	pupil.position = Vector2(0, -6)
	_visual.add_child(pupil)

	# Ragged wing-flaps
	for side in [-1.0, 1.0]:
		var wing := Polygon2D.new()
		wing.polygon = PackedVector2Array([
			Vector2(side * 4, -4), Vector2(side * 22, -10), Vector2(side * 18, 4), Vector2(side * 6, 6)
		])
		wing.color = Color(0.35, 0.08, 0.22, 0.75)
		_visual.add_child(wing)
		_wings.append(wing)


func _physics_process(delta: float) -> void:
	_anim_t += delta
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
		_spawn_death_poof()
		queue_free()
		return

	velocity = to.normalized() * move_speed
	move_and_slide()
	z_index = int(global_position.y)

	if _visual:
		_visual.rotation = lerp_angle(_visual.rotation, to.angle() + PI * 0.5, 0.15)
		_visual.position.y = sin(_anim_t * 10.0) * 1.5
		for i in _wings.size():
			var w := _wings[i]
			var flap := sin(_anim_t * 12.0 + i) * 0.25
			w.rotation = flap * (1.0 if i == 0 else -1.0)


func take_damage(amount: int) -> void:
	hp -= amount
	_bar.value = hp
	if _body_poly:
		_body_poly.modulate = Color(1.8, 1.5, 1.5)
		var t := create_tween()
		t.tween_property(_body_poly, "modulate", Color.WHITE, 0.12)
	if hp <= 0:
		_die()


func _die() -> void:
	if randf() < dust_drop_chance:
		GameState.add_crystal_dust(1)
		GameState.message.emit("+1 Crystal dust")
	_spawn_death_poof()
	queue_free()


func _spawn_death_poof() -> void:
	# One-shot particles left in parent
	var parent := get_parent()
	if parent == null:
		return
	var p := FX.spark_particles(parent, Color(0.7, 0.2, 0.35, 0.9), 14)
	p.global_position = global_position
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.45
	p.emitting = true
	var pm := p.process_material as ParticleProcessMaterial
	if pm:
		pm.initial_velocity_min = 40.0
		pm.initial_velocity_max = 90.0
		pm.gravity = Vector3(0, 40, 0)
	# Cleanup
	var tree := parent.get_tree()
	if tree:
		tree.create_timer(0.6).timeout.connect(p.queue_free)
