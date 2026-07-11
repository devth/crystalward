extends Area2D
class_name LootDrop
## Ground loot from nightspawn — players walk over or fairies auto-collect.

enum Kind { ESSENCE, DUST }

@export var kind: Kind = Kind.ESSENCE
@export var amount: int = 2
@export var pickup_radius: float = 28.0
@export var magnet_radius: float = 55.0
@export var lifetime: float = 45.0

var _age: float = 0.0
var _visual: Node2D
var _claimed: bool = false
var _bob: float = 0.0
var _pop: float = 0.0


func _ready() -> void:
	add_to_group("loot")
	collision_layer = 0
	collision_mask = 2  # players
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = pickup_radius
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	_bob = randf() * TAU
	_build_visuals()
	# Pop out on spawn
	scale = Vector2(0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Scatter impulse (visual only — move slightly)
	var scatter := Vector2(randf_range(-28, 28), randf_range(-18, 18))
	var start := global_position
	tw.parallel().tween_property(self, "global_position", start + scatter, 0.25).set_ease(Tween.EASE_OUT)


func _build_visuals() -> void:
	_visual = Node2D.new()
	add_child(_visual)
	if VisualStyle:
		VisualStyle.make_blob_shadow(_visual, 8, 4, 6)
	var col := Color(0.45, 0.95, 0.9) if kind == Kind.ESSENCE else Color(0.85, 0.7, 1.0)
	var glow := FX.make_ellipse_poly(12, 12, 14, Color(col.r, col.g, col.b, 0.3))
	glow.z_index = -1
	_visual.add_child(glow)
	var gem := Polygon2D.new()
	if kind == Kind.ESSENCE:
		gem.polygon = PackedVector2Array([
			Vector2(0, -10), Vector2(7, -2), Vector2(4, 8), Vector2(-4, 8), Vector2(-7, -2)
		])
	else:
		gem.polygon = PackedVector2Array([
			Vector2(0, -9), Vector2(8, 0), Vector2(0, 9), Vector2(-8, 0)
		])
	gem.color = col
	_visual.add_child(gem)
	var hi := Polygon2D.new()
	hi.polygon = PackedVector2Array([Vector2(-2, -6), Vector2(2, -4), Vector2(0, -1)])
	hi.color = Color(1, 1, 1, 0.65)
	_visual.add_child(hi)
	if FX:
		var p := FX.spark_particles(_visual, Color(col.r, col.g, col.b, 0.55), 4, "glow")
		p.position = Vector2(0, -2)


func _process(delta: float) -> void:
	if _claimed or GameState.is_game_over:
		return
	_age += delta
	_bob += delta * 5.0
	if _visual:
		_visual.position.y = sin(_bob) * 2.5
		_visual.rotation = sin(_bob * 0.7) * 0.15
	z_as_relative = false
	if VisualStyle:
		z_index = VisualStyle.actor_z(global_position.y) + 5
	else:
		z_index = 5005 + int(global_position.y)
	# Blink when about to expire
	if _age > lifetime - 5.0 and _visual:
		_visual.modulate.a = 0.4 + 0.6 * absf(sin(_bob * 4.0))
	if _age >= lifetime:
		queue_free()
		return
	# Magnet toward nearest fairy or warden
	var magnet := _nearest_collector()
	if magnet and global_position.distance_to(magnet.global_position) < magnet_radius:
		var to := magnet.global_position - global_position
		global_position += to.normalized() * 160.0 * delta
		if to.length() < pickup_radius:
			collect()


func _nearest_collector() -> Node2D:
	var best: Node2D = null
	var best_d := magnet_radius
	var tree := get_tree()
	if tree == null:
		return null
	for g in ["wardens", "helper_fairies"]:
		# wardens are in GameState; fairies in group
		pass
	if GameState:
		for w in GameState.wardens:
			if is_instance_valid(w):
				var d: float = global_position.distance_to(w.global_position)
				if d < best_d:
					best_d = d
					best = w
	for f in tree.get_nodes_in_group("helper_fairies"):
		if f is Node2D:
			var d2: float = global_position.distance_to(f.global_position)
			if d2 < best_d:
				best_d = d2
				best = f
	return best


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("wardens") or body.has_method("register_gather"):
		collect()


func collect() -> bool:
	if _claimed or GameState.is_game_over:
		return false
	_claimed = true
	match kind:
		Kind.ESSENCE:
			GameState.add_essence(amount)
			FloatingText.spawn(get_parent(), global_position, "+%d" % amount, Color(1.0, 0.9, 0.35))
		Kind.DUST:
			GameState.add_crystal_dust(amount)
			FloatingText.spawn(get_parent(), global_position, "+dust", Color(0.85, 0.7, 1.0))
	if Sfx:
		Sfx.gather()
	if FX:
		FX.burst_particles(get_parent(), global_position, Color(0.7, 0.95, 0.9), 8, "glow", 0.3)
	queue_free()
	return true


static func spawn_essence(parent: Node, pos: Vector2, amount: int = 2) -> void:
	# Kind.ESSENCE = 0 — use int so static callers never need enum access
	_spawn(parent, pos, 0, amount)


static func spawn_dust(parent: Node, pos: Vector2, amount: int = 1) -> void:
	# Kind.DUST = 1
	_spawn(parent, pos, 1, amount)


static func _spawn(parent: Node, pos: Vector2, kind_i: int, amount: int) -> void:
	if parent == null:
		return
	var scene: PackedScene = load("res://scenes/loot_drop.tscn") as PackedScene
	var node: Area2D
	if scene:
		node = scene.instantiate() as Area2D
	else:
		node = Area2D.new()
		node.set_script(load("res://scripts/loot_drop.gd"))
	if node == null:
		return
	# Set kind/amount BEFORE add_child so _ready/_build_visuals sees correct kind
	node.set("kind", kind_i)
	node.set("amount", amount)
	# Local position before enter tree so scatter tween starts from drop site
	if parent is Node2D:
		node.position = (parent as Node2D).to_local(pos)
	parent.add_child(node)
	if not (parent is Node2D):
		node.global_position = pos
