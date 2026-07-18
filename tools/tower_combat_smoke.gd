extends SceneTree
## Headless smoke: build a tower, spawn an enemy in range, assert damage.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== tower combat smoke ===")
	var gs = root.get_node_or_null("/root/GameState")
	var path_net = root.get_node_or_null("/root/PathNetwork")
	var tower_types = root.get_node_or_null("/root/TowerTypes")
	print("GameState=", gs, " PathNetwork=", path_net, " TowerTypes=", tower_types)
	if path_net and path_net.has_method("rebuild"):
		path_net.rebuild("single")
		print("lanes=", path_net.lane_count())
	if gs and gs.has_method("reset"):
		gs.reset()
		gs.is_game_over = false

	var world := Node2D.new()
	world.name = "World"
	root.add_child(world)

	var tower_ps: PackedScene = load("res://scenes/tower.tscn") as PackedScene
	var enemy_ps: PackedScene = load("res://scenes/enemy.tscn") as PackedScene
	if tower_ps == null or enemy_ps == null:
		printerr("FAIL: missing scenes")
		quit(1)
		return

	var tower: Node2D = tower_ps.instantiate() as Node2D
	tower.set("type_id", "dualshot")
	world.add_child(tower)
	if tower.has_method("configure"):
		tower.call("configure", "dualshot", 24)
	tower.global_position = Vector2(0, 200)
	print("tower fire_range=", tower.get("fire_range"), " damage=", tower.get("damage"), " fire_rate=", tower.get("fire_rate"))
	print("tower in group towers=", tower.is_in_group("towers"))
	print("tower process=", tower.is_processing())

	var enemy: Node2D = enemy_ps.instantiate() as Node2D
	enemy.set("max_hp", 100)
	enemy.set("move_speed", 0.0)
	world.add_child(enemy)
	if enemy.has_method("assign_lane"):
		var lane := PackedVector2Array([Vector2(0, 200), Vector2(0, 40)])
		enemy.call("assign_lane", lane)
	enemy.global_position = Vector2(80, 200)
	print("enemy hp=", enemy.get("hp"), " dist=", tower.global_position.distance_to(enemy.global_position))
	print("enemy in group=", enemy.is_in_group("enemies"))

	var hp0: int = int(enemy.get("hp"))
	for i in 120:
		await process_frame
		if not is_instance_valid(enemy):
			print("PASS: enemy killed at frame", i)
			quit(0)
			return

	var hp1: int = int(enemy.get("hp")) if is_instance_valid(enemy) else -1
	print("hp after frames: ", hp0, " -> ", hp1)
	if tower.has_method("_find_target"):
		var t = tower.call("_find_target")
		print("find_target=", t, " enemies=", root.get_tree().get_nodes_in_group("enemies").size())
	if tower.has_method("_fire_at") and is_instance_valid(enemy):
		tower.call("_fire_at", enemy)
		print("after force fire hp=", enemy.get("hp"))
	if hp1 < hp0:
		print("PASS: tower dealt damage via process")
		quit(0)
	else:
		printerr("FAIL: tower process did not damage")
		quit(1)
