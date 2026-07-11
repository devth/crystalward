extends Node2D
class_name HelperFairy
## Auto-helper: prioritizes loot pickups, then essence wells.

enum Mode { SEEK_LOOT, SEEK_WELL, GATHER, IDLE }

@export var fly_speed: float = 150.0
@export var gather_rate_mult: float = 0.55

func _fly_speed() -> float:
	return fly_speed * (Powers.fairy_speed_mult() if Powers else 1.0)

func _gather_mult() -> float:
	return gather_rate_mult * (Powers.fairy_gather_mult() if Powers else 1.0)
@export var gather_range: float = 36.0
@export var loot_range: float = 30.0
@export var owner_index: int = 0

var mode: Mode = Mode.SEEK_LOOT
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
	var glow := FX.make_ellipse_poly(14, 14, 16, Color(_tint.r, _tint.g, _tint.b, 0.25))
	glow.z_index = -1
	_visual.add_child(glow)
	var body := FX.make_ellipse_poly(5, 6, 12, _tint)
	body.position = Vector2(0, -4)
	_visual.add_child(body)
	var head := FX.make_ellipse_poly(3.5, 3.5, 10, Color(1.0, 0.95, 0.9))
	head.position = Vector2(0, -12)
	_visual.add_child(head)
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
	z_as_relative = false
	if VisualStyle:
		z_index = VisualStyle.actor_z(global_position.y) + 10
	else:
		z_index = 5010 + int(global_position.y)

	# Always prefer nearby loot if any exists
	if mode != Mode.SEEK_LOOT:
		var near_loot := _find_best_loot()
		if near_loot and global_position.distance_to(near_loot.global_position) < 420.0:
			_target = near_loot
			mode = Mode.SEEK_LOOT

	match mode:
		Mode.SEEK_LOOT:
			_seek_loot(delta)
		Mode.SEEK_WELL:
			_seek_well(delta)
		Mode.GATHER:
			_gather(delta)
		Mode.IDLE:
			_idle_hover(delta)


func _seek_loot(delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or not _target.is_in_group("loot"):
		_target = _find_best_loot()
	if _target == null:
		# No loot — fall back to wells
		_target = _find_best_well()
		mode = Mode.SEEK_WELL if _target else Mode.IDLE
		return
	var dest: Vector2 = _target.global_position
	var to := dest - global_position
	if to.length() <= loot_range:
		if _target.has_method("collect"):
			_target.collect()
		_target = null
		# Immediately look for more loot
		var more := _find_best_loot()
		if more:
			_target = more
		else:
			mode = Mode.SEEK_WELL
		return
	global_position += to.normalized() * (_fly_speed() * 1.15) * delta
	global_position = GameState.clamp_world_position(global_position)
	_face(to)


func _seek_well(delta: float) -> void:
	# Opportunistic loot while flying to wells
	var loot := _find_best_loot()
	if loot and global_position.distance_to(loot.global_position) < 200.0:
		_target = loot
		mode = Mode.SEEK_LOOT
		return
	if _target == null or not is_instance_valid(_target) or not _well_available(_target):
		_target = _find_best_well()
	if _target == null:
		mode = Mode.IDLE
		return
	var dest: Vector2 = _target.global_position + Vector2(0, -8)
	var to := dest - global_position
	if to.length() <= gather_range:
		mode = Mode.GATHER
		return
	global_position += to.normalized() * _fly_speed() * delta
	global_position = GameState.clamp_world_position(global_position)
	_face(to)


func _gather(delta: float) -> void:
	# Interrupt for loot on the ground
	var loot := _find_best_loot()
	if loot and global_position.distance_to(loot.global_position) < 120.0:
		_target = loot
		mode = Mode.SEEK_LOOT
		return
	if _target == null or not is_instance_valid(_target) or not _well_available(_target):
		_target = null
		mode = Mode.SEEK_LOOT
		return
	if global_position.distance_to(_target.global_position) > gather_range * 1.4:
		mode = Mode.SEEK_WELL
		return
	var orbit := Vector2(cos(_bob * 0.5), sin(_bob * 0.5)) * 10.0
	var want: Vector2 = _target.global_position + orbit + Vector2(0, -10)
	global_position = global_position.lerp(want, 1.0 - exp(-6.0 * delta))
	if _target.has_method("contribute_gather"):
		_target.contribute_gather(delta * _gather_mult())


func _idle_hover(delta: float) -> void:
	var home := PathNetwork.CRYSTAL if PathNetwork else Vector2(0, 40)
	home += Vector2(cos(_bob * 0.3 + owner_index) * 40.0, sin(_bob * 0.4) * 20.0 - 30.0)
	global_position = global_position.lerp(home, 1.0 - exp(-2.0 * delta))
	var loot := _find_best_loot()
	if loot:
		_target = loot
		mode = Mode.SEEK_LOOT
		return
	if int(_bob * 3.0) % 5 == 0:
		var w := _find_best_well()
		if w:
			_target = w
			mode = Mode.SEEK_WELL


func _face(to: Vector2) -> void:
	if _visual == null:
		return
	if to.x < -2.0:
		_visual.scale.x = -1.0
	elif to.x > 2.0:
		_visual.scale.x = 1.0


func _well_available(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.has_method("is_available"):
		return node.is_available()
	return node.get("_depleted") != true


func _find_best_loot() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	var tree := get_tree()
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("loot"):
		if not (n is Node2D):
			continue
		if n.get("_claimed") == true:
			continue
		var d: float = global_position.distance_to(n.global_position)
		# Prefer closer loot; slight preference for dust when equal-ish
		if d < best_d:
			best_d = d
			best = n
	return best


func _find_best_well() -> Node2D:
	var best: Node2D = null
	var best_score := -INF
	var tree := get_tree()
	if tree == null:
		return null
	for n in tree.get_nodes_in_group("essence_nodes"):
		if not (n is Node2D) or not _well_available(n):
			continue
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
