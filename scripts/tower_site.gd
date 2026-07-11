extends Area2D
## Claimable site — queue a tower with shared bank Essence.

enum State { EMPTY, QUEUED, BUILT }

@export var tower_scene: PackedScene

var state: State = State.EMPTY
var _queue_left: float = 0.0

@onready var _pad: Polygon2D = $Pad
@onready var _bar: ProgressBar = $Progress
@onready var _label: Label = $Label
@onready var _tower_slot: Node2D = $TowerSlot


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 8
	collision_mask = 2
	_bar.visible = false
	_label.text = "Q build (%d)" % GameState.TOWER_COST_ESSENCE
	_pad.color = Color(0.25, 0.35, 0.28, 0.7)
	z_index = int(global_position.y)


func _process(delta: float) -> void:
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
	_label.text = "Building..."
	_pad.color = Color(0.45, 0.4, 0.2, 0.85)
	GameState.message.emit("Tower queued")
	return true


func _finish_build() -> void:
	state = State.BUILT
	_bar.visible = false
	_label.text = "Online"
	_pad.color = Color(0.2, 0.25, 0.35, 0.5)
	if tower_scene:
		var t: Node = tower_scene.instantiate()
		_tower_slot.add_child(t)
	GameState.message.emit("Tower awakened")


func _on_body_entered(body: Node) -> void:
	if body.has_method("register_build"):
		body.register_build(self)


func _on_body_exited(body: Node) -> void:
	if body.has_method("unregister_build"):
		body.unregister_build(self)
