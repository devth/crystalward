extends Area2D
## Essence node — hold gather; shared progress; cyan crystal well VFX.

@export var respawn_time: float = 4.0

var _progress: float = 0.0
var _depleted: bool = false
var _respawn_left: float = 0.0
var _visual: Node2D
var _crystal: Polygon2D
var _ring: Polygon2D
var _particles: GPUParticles2D

@onready var _bar: ProgressBar = $Progress
@onready var _label: Label = $Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 8
	collision_mask = 2
	if has_node("Body"):
		$Body.visible = false

	_build_visuals()
	FX.style_progress_bar(_bar, Color(0.4, 0.85, 0.9), Color(0.05, 0.1, 0.12, 0.85))
	_bar.max_value = GameState.GATHER_NEED
	_bar.value = 0.0
	_bar.position = Vector2(-26, -42)
	_bar.size = Vector2(52, 8)
	_label.text = "Hold gather"
	_label.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0, 0.85))
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12, 0.9))
	_label.add_theme_constant_override("outline_size", 3)
	_label.position = Vector2(-36, 26)
	z_index = int(global_position.y)


func _build_visuals() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	FX.add_soft_shadow(_visual, 20, 9, 14)

	_ring = FX.make_ellipse_poly(28, 16, 28, Color(0.3, 0.7, 0.8, 0.2))
	_ring.position = Vector2(0, 6)
	_visual.add_child(_ring)

	var pool := FX.make_ellipse_poly(18, 10, 24, Color(0.15, 0.35, 0.4, 0.7))
	pool.position = Vector2(0, 8)
	_visual.add_child(pool)

	_crystal = Polygon2D.new()
	_crystal.polygon = PackedVector2Array([
		Vector2(0, -22), Vector2(12, -4), Vector2(6, 12), Vector2(-6, 12), Vector2(-12, -4)
	])
	_crystal.color = Color(0.45, 0.9, 0.95, 0.92)
	_visual.add_child(_crystal)

	var facet := Polygon2D.new()
	facet.polygon = PackedVector2Array([
		Vector2(0, -22), Vector2(12, -4), Vector2(0, 2), Vector2(-4, -8)
	])
	facet.color = Color(0.85, 1.0, 1.0, 0.45)
	_visual.add_child(facet)

	_particles = FX.spark_particles(_visual, Color(0.5, 0.95, 1.0, 0.85), 14)
	_particles.position = Vector2(0, -8)


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	if _crystal and not _depleted:
		_crystal.position.y = sin(t * 2.4) * 2.5
		_crystal.rotation = sin(t * 1.1) * 0.08
		_ring.modulate.a = 0.5 + 0.5 * sin(t * 3.0)

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


func contribute_gather(delta: float) -> void:
	if _depleted or GameState.is_game_over:
		return
	_progress += GameState.GATHER_PROGRESS_RATE * delta
	_bar.value = _progress
	if _crystal:
		_crystal.modulate = Color(1.4, 1.5, 1.6)
	if _progress >= GameState.GATHER_NEED:
		_complete_gather()


func _complete_gather() -> void:
	GameState.add_essence(GameState.ESSENCE_PER_GATHER)
	GameState.message.emit("+%d Essence" % GameState.ESSENCE_PER_GATHER)
	_depleted = true
	_respawn_left = respawn_time
	if _visual:
		_visual.modulate = Color(0.35, 0.4, 0.45)
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
