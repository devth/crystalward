extends Area2D
## Claimable tree-stump site — queue a living tower (PJ Monsters DNA).

enum State { EMPTY, QUEUED, BUILT }

@export var tower_scene: PackedScene

var state: State = State.EMPTY
var _queue_left: float = 0.0
var _stump: Node2D
var _sprout: Polygon2D

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
	FX.style_progress_bar(_bar, Color(0.55, 0.85, 0.45), Color(0.1, 0.08, 0.06, 0.85))
	_bar.visible = false
	_bar.position = Vector2(-30, -52)
	_bar.size = Vector2(60, 9)
	_label.text = "Build  (%d)" % GameState.TOWER_COST_ESSENCE
	if VisualStyle:
		VisualStyle.style_game_label(_label, 12, true)
	_label.position = Vector2(-48, 28)
	z_index = int(global_position.y)


func _build_visuals() -> void:
	if VisualStyle:
		VisualStyle.make_blob_shadow(self, 30, 12, 12)
	else:
		FX.add_soft_shadow(self, 30, 12, 12)

	_stump = Node2D.new()
	add_child(_stump)

	# Dirt ring
	var dirt := FX.make_ellipse_poly(34, 18, 24, Color(0.4, 0.3, 0.2, 0.75))
	dirt.position = Vector2(0, 6)
	_stump.add_child(dirt)

	# Stump body
	var stump := Polygon2D.new()
	stump.polygon = PackedVector2Array([
		Vector2(-18, 10), Vector2(18, 10), Vector2(16, -4), Vector2(10, -12),
		Vector2(-10, -12), Vector2(-16, -4)
	])
	stump.color = Color(0.48, 0.32, 0.2)
	_stump.add_child(stump)

	# Growth rings
	var ring := FX.make_ellipse_poly(12, 7, 16, Color(0.62, 0.45, 0.28, 0.9))
	ring.position = Vector2(0, -8)
	_stump.add_child(ring)
	var ring2 := FX.make_ellipse_poly(7, 4, 12, Color(0.55, 0.38, 0.22, 0.9))
	ring2.position = Vector2(0, -8)
	_stump.add_child(ring2)

	# Sprout buds
	_sprout = Polygon2D.new()
	_sprout.polygon = PackedVector2Array([
		Vector2(-4, -12), Vector2(0, -28), Vector2(4, -12)
	])
	_sprout.color = Color(0.4, 0.7, 0.45, 0.85)
	_stump.add_child(_sprout)

	var spark := FX.spark_particles(_stump, Color(0.6, 0.95, 0.55, 0.5), 6, "star")
	spark.position = Vector2(0, -16)


func _process(delta: float) -> void:
	if _sprout and state == State.EMPTY:
		_sprout.position.y = sin(Time.get_ticks_msec() * 0.004) * 2.0

	if state != State.QUEUED:
		return
	_queue_left -= delta
	_bar.value = 1.0 - (_queue_left / GameState.TOWER_QUEUE_TIME)
	if _sprout:
		_sprout.scale = Vector2.ONE * (1.0 + (1.0 - _queue_left / GameState.TOWER_QUEUE_TIME) * 1.5)
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
	_label.text = "Growing..."
	GameState.message.emit("Tower sprouting!")
	return true


func _finish_build() -> void:
	state = State.BUILT
	_bar.visible = false
	_label.text = ""
	if _sprout:
		_sprout.visible = false
	if _stump:
		_stump.modulate = Color(0.7, 0.75, 0.7, 0.55)
	if tower_scene:
		var t: Node = tower_scene.instantiate()
		_tower_slot.add_child(t)
	GameState.message.emit("Tree awakened!")
	if FX:
		FX.burst_particles(self, global_position + Vector2(0, -20), Color(0.5, 0.9, 0.45), 18, "star", 0.55)
	if Sfx:
		Sfx.build()


func _on_body_entered(body: Node) -> void:
	if body.has_method("register_build"):
		body.register_build(self)


func _on_body_exited(body: Node) -> void:
	if body.has_method("unregister_build"):
		body.unregister_build(self)
