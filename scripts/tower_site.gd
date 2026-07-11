extends Area2D
## Claimable site — queue a tower with shared bank Essence.

enum State { EMPTY, QUEUED, BUILT }

@export var tower_scene: PackedScene

var state: State = State.EMPTY
var _queue_left: float = 0.0
var _pad: Polygon2D
var _runes: Array[Polygon2D] = []

@onready var _bar: ProgressBar = $Progress
@onready var _label: Label = $Label
@onready var _tower_slot: Node2D = $TowerSlot


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 8
	collision_mask = 2
	if has_node("Pad"):
		$Pad.visible = false

	_build_visuals()
	FX.style_progress_bar(_bar, Color(0.85, 0.7, 0.35), Color(0.1, 0.08, 0.05, 0.85))
	_bar.visible = false
	_bar.position = Vector2(-30, -44)
	_bar.size = Vector2(60, 8)
	_label.text = "Build  (%d)" % GameState.TOWER_COST_ESSENCE
	_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.75, 0.85))
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.06, 0.9))
	_label.add_theme_constant_override("outline_size", 3)
	_label.position = Vector2(-42, 28)
	z_index = int(global_position.y)


func _build_visuals() -> void:
	FX.add_soft_shadow(self, 28, 12, 10)

	_pad = Polygon2D.new()
	_pad.polygon = PackedVector2Array([
		Vector2(0, -30), Vector2(38, 0), Vector2(0, 30), Vector2(-38, 0)
	])
	_pad.color = Color(0.22, 0.32, 0.26, 0.75)
	add_child(_pad)

	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(22, 0), Vector2(0, 18), Vector2(-22, 0)
	])
	inner.color = Color(0.18, 0.24, 0.22, 0.9)
	inner.name = "Inner"
	add_child(inner)

	# Rune ticks
	for i in 4:
		var a := TAU * 0.25 * float(i) + PI * 0.25
		var r := Polygon2D.new()
		var p := Vector2(cos(a), sin(a)) * 20.0
		r.polygon = PackedVector2Array([
			p + Vector2(-3, -3), p + Vector2(3, -3), p + Vector2(0, 4)
		])
		r.color = Color(0.55, 0.75, 0.55, 0.55)
		add_child(r)
		_runes.append(r)

	var mist := FX.make_ellipse_poly(26, 16, 20, Color(0.4, 0.6, 0.45, 0.08))
	mist.z_index = -1
	add_child(mist)


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for i in _runes.size():
		_runes[i].modulate.a = 0.35 + 0.4 * sin(t * 2.0 + i) if state == State.EMPTY else 0.15

	if state != State.QUEUED:
		return
	_queue_left -= delta
	_bar.value = 1.0 - (_queue_left / GameState.TOWER_QUEUE_TIME)
	if _queue_left <= 0.0:
		_finish_build()


func try_queue_build() -> bool:
	if state != State.EMPTY or GameState.is_game_over:
		return false
	if not GameState.try_spend_essence(GameState.TOWER_COST_ESSENCE):
		return false
	state = State.QUEUED
	_queue_left = GameState.TOWER_QUEUE_TIME
	_bar.visible = true
	_bar.max_value = 1.0
	_bar.value = 0.0
	_label.text = "Awakening..."
	_pad.color = Color(0.45, 0.4, 0.22, 0.85)
	GameState.message.emit("Tower queued")
	return true


func _finish_build() -> void:
	state = State.BUILT
	_bar.visible = false
	_label.text = ""
	_pad.color = Color(0.15, 0.2, 0.28, 0.45)
	if has_node("Inner"):
		$Inner.color = Color(0.12, 0.15, 0.2, 0.5)
	if tower_scene:
		var t: Node = tower_scene.instantiate()
		_tower_slot.add_child(t)
	GameState.message.emit("Tower awakened")
	FX.burst_particles(self, global_position, Color(0.9, 0.75, 0.4, 0.9), 18, "magic", 0.55)
	FX.burst_particles(self, global_position, Color(0.7, 0.9, 0.55, 0.75), 10, "star", 0.45)


func _on_body_entered(body: Node) -> void:
	if body.has_method("register_build"):
		body.register_build(self)


func _on_body_exited(body: Node) -> void:
	if body.has_method("unregister_build"):
		body.unregister_build(self)
