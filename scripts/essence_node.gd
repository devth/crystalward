extends Area2D
## Essence fruit well — hold gather; shared progress. PJ-style glowing orbs.

@export var respawn_time: float = 4.0

var _progress: float = 0.0
var _depleted: bool = false
var _respawn_left: float = 0.0
var _visual: Node2D
var _fruit: Polygon2D
var _leaf: Polygon2D
var _particles: GPUParticles2D
var _bob: float = 0.0

@onready var _bar: ProgressBar = $Progress
@onready var _label: Label = $Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 8
	collision_mask = 2
	if has_node("Body"):
		$Body.visible = false

	_bob = randf() * TAU
	_build_visuals()
	FX.style_progress_bar(_bar, Color(0.45, 0.95, 0.9), Color(0.05, 0.1, 0.12, 0.85))
	_bar.max_value = GameState.GATHER_NEED
	_bar.value = 0.0
	_bar.position = Vector2(-26, -48)
	_bar.size = Vector2(52, 9)
	_label.text = "Hold gather"
	if VisualStyle:
		VisualStyle.style_game_label(_label, 12, true)
	_label.position = Vector2(-40, 26)
	z_index = int(global_position.y)
	add_to_group("essence_nodes")


func _build_visuals() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	if VisualStyle:
		VisualStyle.make_blob_shadow(_visual, 20, 9, 14)
	else:
		FX.add_soft_shadow(_visual, 20, 9, 14)

	# Grass tuft base
	var grass := Polygon2D.new()
	grass.polygon = PackedVector2Array([
		Vector2(-16, 10), Vector2(-8, -2), Vector2(0, 8), Vector2(8, -4), Vector2(16, 10)
	])
	grass.color = Color(0.35, 0.6, 0.35)
	_visual.add_child(grass)

	# Stem
	var stem := Line2D.new()
	stem.width = 3.0
	stem.default_color = Color(0.3, 0.5, 0.28)
	stem.points = PackedVector2Array([Vector2(0, 6), Vector2(0, -8)])
	_visual.add_child(stem)

	_leaf = Polygon2D.new()
	_leaf.polygon = PackedVector2Array([
		Vector2(2, -4), Vector2(14, -12), Vector2(4, 2)
	])
	_leaf.color = Color(0.4, 0.7, 0.4)
	_visual.add_child(_leaf)

	# Glowing fruit (essence)
	_fruit = Polygon2D.new()
	_fruit.polygon = PackedVector2Array([
		Vector2(0, -28), Vector2(12, -16), Vector2(10, -2), Vector2(0, 4),
		Vector2(-10, -2), Vector2(-12, -16)
	])
	_fruit.color = Color(0.45, 0.95, 0.92)
	_visual.add_child(_fruit)
	var hi := Polygon2D.new()
	hi.polygon = PackedVector2Array([
		Vector2(-4, -22), Vector2(2, -20), Vector2(-2, -12)
	])
	hi.color = Color(0.9, 1.0, 1.0, 0.7)
	_visual.add_child(hi)

	var glow := FX.make_ellipse_poly(18, 16, 20, Color(0.5, 0.95, 0.9, 0.18))
	glow.position = Vector2(0, -12)
	glow.z_index = -1
	_visual.add_child(glow)

	_particles = FX.spark_particles(_visual, Color(0.55, 1.0, 0.95, 0.85), 14, "glow")
	_particles.position = Vector2(0, -12)


func _process(delta: float) -> void:
	_bob += delta
	if _fruit and not _depleted:
		_fruit.position.y = sin(_bob * 2.6) * 2.8
		_fruit.rotation = sin(_bob * 1.2) * 0.08
		if _leaf:
			_leaf.rotation = sin(_bob * 1.5) * 0.12

	if _depleted:
		_respawn_left -= delta
		if _respawn_left <= 0.0:
			_depleted = false
			_progress = 0.0
			if _visual:
				_visual.modulate = Color.WHITE
			if _particles:
				_particles.emitting = true
			_bar.value = 0.0
			_bar.visible = true
			_label.visible = true
		return


func is_available() -> bool:
	return not _depleted and not GameState.is_game_over


func is_depleted() -> bool:
	return _depleted


func contribute_gather(delta: float) -> void:
	if _depleted or GameState.is_game_over:
		return
	_progress += GameState.GATHER_PROGRESS_RATE * delta
	_bar.value = _progress
	if _fruit:
		_fruit.modulate = Color(1.4, 1.5, 1.5)
	if _progress >= GameState.GATHER_NEED:
		_complete_gather()


func _complete_gather() -> void:
	GameState.add_essence(GameState.ESSENCE_PER_GATHER)
	GameState.message.emit("+%d Essence" % GameState.ESSENCE_PER_GATHER)
	if Sfx:
		Sfx.gather()
	if FX:
		FX.burst_particles(self, global_position + Vector2(0, -12), Color(0.5, 0.95, 0.9), 14, "glow", 0.45)
	_depleted = true
	_respawn_left = respawn_time
	if _visual:
		_visual.modulate = Color(0.45, 0.5, 0.48)
	if _particles:
		_particles.emitting = false
	_bar.visible = false
	_label.visible = false
	_progress = 0.0


func _on_body_entered(body: Node) -> void:
	if body.has_method("register_gather"):
		body.register_gather(self)


func _on_body_exited(body: Node) -> void:
	if body.has_method("unregister_gather"):
		body.unregister_gather(self)
