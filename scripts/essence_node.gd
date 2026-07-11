extends Area2D
## Essence node — hold gather; shared progress bar for all wardens.

@export var respawn_time: float = 4.0

var _progress: float = 0.0
var _depleted: bool = false
var _respawn_left: float = 0.0

@onready var _body: Polygon2D = $Body
@onready var _bar: ProgressBar = $Progress
@onready var _label: Label = $Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 8
	collision_mask = 2
	_bar.max_value = GameState.GATHER_NEED
	_bar.value = 0.0
	_label.text = "E hold"
	z_index = int(global_position.y)


func _process(delta: float) -> void:
	if _depleted:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			_depleted = false
			_progress = 0.0
			_body.modulate = Color.WHITE
			_bar.value = 0.0
			_bar.visible = true
			_label.visible = true
		return


func contribute_gather(delta: float) -> void:
	if _depleted or GameState.is_game_over:
		return
	_progress += GameState.GATHER_PROGRESS_RATE * delta
	_bar.value = _progress
	if _progress >= GameState.GATHER_NEED:
		_complete_gather()


func _complete_gather() -> void:
	GameState.add_essence(GameState.ESSENCE_PER_GATHER)
	GameState.message.emit("+%d Essence" % GameState.ESSENCE_PER_GATHER)
	_depleted = true
	_respawn_left = respawn_time
	_body.modulate = Color(0.3, 0.3, 0.35)
	_bar.visible = false
	_label.visible = false
	_progress = 0.0


func _on_body_entered(body: Node) -> void:
	if body.has_method("register_gather"):
		body.register_gather(self)


func _on_body_exited(body: Node) -> void:
	if body.has_method("unregister_gather"):
		body.unregister_gather(self)
