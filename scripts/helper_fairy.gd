extends Node2D
class_name HelperFairy
## Auto-gather fairy — flies to essence wells and gathers for the shared bank.
## Spawned by wardens (Legend-style helpers).

enum Mode { SEEK, GATHER, IDLE }

@export var fly_speed: float = 140.0
@export var gather_rate_mult: float = 0.55  ## slower than a warden (balance)
@export var gather_range: float = 36.0
@export var owner_index: int = 0

var mode: Mode = Mode.SEEK
var _target: Node2D = null
var _bob: float = 0.0
var _visual: Node2D
var _wing_l: Polygon2D
var _wing_r: Polygon2D
var _tint: Color = Color(0.85, 0.75, 1.0)


func _ready() -> void:
	add_to_group("helper_fairies")
	_bob = randf() * TAU
	_tint = Color(0.7, 0.95, 0.9) if owner_index == 0 else Color(0.95, 0.7, 0.95)
	_build_visuals()
	if GameState:
		GameState.register_fairy(self)


func _exit_tree() -> void:
	if GameState:
		GameState.unregister_fairy(self)


func _build_visuals() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	if VisualStyle:
		VisualStyle.make_blob_shadow(_visual, 10, 5, 8)
	# Glow
	var glow := FX.make_ellipse_poly(14, 14, 16, Color(_tint.r, _tint.g, _tint.b, 0.25))
	glow.z_index = -1
	_visual.add_child(glow)
	# Body
	var body := FX.make_ellipse_poly(5, 6, 12, _tint)
	body.position = Vector2(0, -4)
	_visual.add_child(body)
	# Head
	var head := FX.make_ellipse_poly(3.5, 3.5, 10, Color(1.0, 0.95, 0.9))
	head.position = Vector2(0, -12)
	_visual.add_child(head)
	# Wings
	_wing_l = Polygon2D.new()
	_wing_l.polygon = PackedVector2Array([
		Vector2(-2, -6), Vector2(-16, -14), Vector2(-14, -2), Vector2(-4, 0)
	])
	_wing_l.color = Color(0.85, 0.9, 1.0, 0.55)
	_visual.add_child(_wing_l)
	_wing_r = Polygon2D.new()
	_wing_r.polygon = PackedVector2Array([
		Vector2(2, -6), Vector2(16, -14), Vector2(14, -2), Vector2(4, 0)
	])
	_wing_r.color = Color(0.85, 0.9, 1.0, 0.55)
	_visual.add_child(_wing_r)
	# Sparkle trail
	if FX:
		var p := FX.spark_particles(_visual, Color(_tint.r, _tint.g, _tint.b, 0.6), 6, "star")
		p.position = Vector2(0, -4)
		var pm := p.process_material as ParticleProcessMaterial
		if pm:
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			pm.emission_sphere_radius = 6.0
			pm.initial_velocity_min = 2.0
			pm.initial_velocity_max = 8.0
			pm.gravity = Vector3(0, 10, 0)


func _process(delta: float) -> void:
	if GameState.is_game_over:
		return
	_bob += delta * 8.0
	if _visual:
		_visual.position.y = sin(_bob) * 3.0
		if _wing_l:
			_wing_l.rotation = sin(_bob * 2.5) * 0.35
		if _wing_r:
			_wing_r.rotation = -sin(_bob * 2.5) * 0.35
	z_index = int(global_position.y)

	match mode:
		Mode.SEEK:
			_seek(delta)
		Mode.GATHER:
			_gather(delta)
		Mode.IDLE:
			_idle_hover(delta)


func _seek(delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or not _target_available(_target):
		_target = _find_best_well()
	if _target == null:
		mode = Mode.IDLE
		return
	var dest: Vector2 = _target.global_position + Vector2(0, -8)
	var to := dest - global_position
	if to.length() <= gather_range:
		mode = Mode.GATHER
		return
	global_position += to.normalized() * fly_speed * delta
	global_position = GameState.clamp_world_position(global_position)
	if _visual and to.x < -2.0:
		_visual.scale.x = -1.0
	elif _visual and to.x > 2.0:
		_visual.scale.x = 1.0


func _gather(delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or not _target_available(_target):
		_target = null
		mode = Mode.SEEK
		return
	if global_position.distance_to(_target.global_position) > gather_range * 1.4:
		mode = Mode.SEEK
		return
	# Orbit slightly while gathering
	var orbit := Vector2(cos(_bob * 0.5), sin(_bob * 0.5)) * 10.0
	var want: Vector2 = _target.global_position + orbit + Vector2(0, -10)
	global_position = global_position.lerp(want, 1.0 - exp(-6.0 * delta))
	if _target.has_method("contribute_gather"):
		# Reduced rate vs player
		_target.contribute_gather(delta * gather_rate_mult)


func _idle_hover(delta: float) -> void:
	# Hover near crystal while waiting for wells
	var home := PathNetwork.CRYSTAL if PathNetwork else Vector2(0, 40)
	home += Vector2(cos(_bob * 0.3 + owner_index) * 40.0, sin(_bob * 0.4) * 20.0 - 30.0)
	global_position = global_position.lerp(home, 1.0 - exp(-2.0 * delta))
	# Recheck wells occasionally
	if int(_bob * 3.0) % 5 == 0:
		var w := _find_best_well()
		if w:
			_target = w
			mode = Mode.SEEK


func _target_available(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.has_method("is_available"):
		return node.is_available()
	# Fallback: depleted flag
	if node.get("_depleted") == true:
		return false
	return true


func _find_best_well() -> Node2D:
	var best: Node2D = null
	var best_score := -INF
	var tree := get_tree()
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("essence_nodes"):
		if not (n is Node2D):
			continue
		if not _target_available(n):
			continue
		# Prefer nearer wells, lightly prefer ones with fewer fairies already
		var d: float = global_position.distance_to(n.global_position)
		var crowd := 0
		for f in tree.get_nodes_in_group("helper_fairies"):
			if f != self and f.get("_target") == n:
				crowd += 1
		var score := 1000.0 / maxf(40.0, d) - crowd * 2.5
		if score > best_score:
			best_score = score
			best = n
	return best
