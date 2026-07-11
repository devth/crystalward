extends Node2D
## World bootstrap: path-aligned content, atmosphere, juice binding.


@onready var _world: Node2D = $World
@onready var _spawns: Node2D = $Spawns
@onready var _wave_manager: Node = $WaveManager
@onready var _camera: Camera2D = $Camera2D

var _essence_scene: PackedScene
var _site_scene: PackedScene


func _ready() -> void:
	print("Crystalward — devices: ", Input.get_connected_joypads())
	# Fresh match state, then campaign overrides waves/essence/lanes.
	if GameState:
		GameState.reset()
	_apply_campaign_map()
	# Tower roster for this match (campaign tier + map difficulty)
	if TowerTypes and Campaign:
		var m: Dictionary = Campaign.get_map(Campaign.selected_map_id)
		TowerTypes.begin_match(int(m.get("difficulty", 1)))
	elif TowerTypes:
		TowerTypes.begin_match(1)
	print("Path lanes: ", PathNetwork.lane_count() if PathNetwork else 0)
	_essence_scene = load("res://scenes/essence_node.tscn") as PackedScene
	_site_scene = load("res://scenes/tower_site.tscn") as PackedScene
	if Juice and _camera:
		Juice.bind_camera(_camera)
	if Music:
		Music.play(Music.Track.BATTLE)
	GameState.game_over.connect(_on_game_over_music)
	_expand_map_content()
	_build_atmosphere()
	_zone_labels()
	_map_banner()
	# Ensure dirt roads redraw after lanes are final (Ground awaits one frame too).
	call_deferred("_ensure_ground_paths")


func _ensure_ground_paths() -> void:
	if PathNetwork and PathNetwork.lane_count() == 0:
		var m: Dictionary = Campaign.get_map(Campaign.selected_map_id) if Campaign else {}
		PathNetwork.rebuild(str(m.get("lane_set", "simple")))
	var ground := get_node_or_null("Ground")
	if ground and ground.has_method("_build") and PathNetwork and PathNetwork.lane_count() > 0:
		# If Ground built before lanes, paths_rebuilt already handles it; if paths empty on Ground, force.
		# Light nudge: re-emit so Ground refreshes roads.
		PathNetwork.paths_rebuilt.emit()


func _apply_campaign_map() -> void:
	if Campaign == null or PathNetwork == null:
		return
	var m: Dictionary = Campaign.get_map(Campaign.selected_map_id)
	PathNetwork.rebuild(str(m.get("lane_set", "full")))
	GameState.waves_to_win = int(m.get("waves", 8))
	GameState.essence = int(m.get("start_essence", GameState.STARTING_ESSENCE))
	if m.has("lives"):
		var lives: int = int(m.get("lives", GameState.CRYSTAL_MAX_HP))
		GameState.crystal_max_hp = lives
		GameState.crystal_hp = lives
		GameState.crystal_hp_changed.emit(GameState.crystal_hp, GameState.crystal_max_hp)
	GameState.current_wave = 0
	GameState.wave_changed.emit(0, GameState.waves_to_win)
	# Wave manager pacing from map (tutorial glade is intentionally chill)
	if _wave_manager:
		if m.has("first_wave_delay"):
			_wave_manager.set("first_wave_delay", float(m.get("first_wave_delay")))
			_wave_manager.set("_timer", float(m.get("first_wave_delay")))
		if m.has("calm_between_waves"):
			_wave_manager.set("calm_between_waves", float(m.get("calm_between_waves")))


func _map_banner() -> void:
	if Campaign == null:
		return
	var m: Dictionary = Campaign.get_map(Campaign.selected_map_id)
	var extra := ""
	if int(m.get("difficulty", 3)) <= 1:
		extra = " · easy playtest pace"
	GameState.message.emit("%s — %s%s" % [m.get("name"), m.get("blurb"), extra])


func _on_game_over_music(won: bool) -> void:
	if won:
		if Music:
			Music.play(Music.Track.VICTORY)
		if Campaign:
			Campaign.record_victory(Campaign.selected_map_id, GameState.stars)
	# Offer return via R restart; add menu after delay
	await get_tree().create_timer(2.5).timeout
	# Keep playing until R; HUD shows victory


func _expand_map_content() -> void:
	# Scene-placed essence/sites are dense near the well — hide them so
	# runtime placement owns spacing (harvest vs build no longer stacked).
	_retire_scene_economy_nodes()

	# Tower sites first (along path arc), then essence in gaps between them.
	if _site_scene and PathNetwork:
		var single_lane := PathNetwork.lane_count() <= 1
		var site_spacing := 260.0 if single_lane else 300.0
		var pad_offset := 78.0  # off road enough to not block walking the dirt
		var lane_i := 0
		for lane in PathNetwork.lanes:
			var pts: PackedVector2Array = lane
			if pts.size() < 3:
				continue
			var length := PathNetwork.lane_length(pts)
			var d := 180.0  # skip spawn mouth
			var side_flip := 1.0 if lane_i % 2 == 0 else -1.0
			while d < length - 160.0:
				var sample: Dictionary = PathNetwork.sample_lane(pts, d)
				var center: Vector2 = sample.get("pos", Vector2.ZERO)
				var normal: Vector2 = sample.get("normal", Vector2.RIGHT)
				# Alternate sides so pads don't face each other
				var side := side_flip
				side_flip *= -1.0
				var pos: Vector2 = center + normal * (pad_offset * side)
				if pos.length() < 160.0:
					d += site_spacing * 0.5
					continue
				if _too_close_to_existing_sites(pos, site_spacing * 0.85):
					d += site_spacing * 0.4
					continue
				if _too_close_to_group_or_class(pos, "essence_nodes", 160.0):
					d += site_spacing * 0.35
					continue
				var site: Node2D = _site_scene.instantiate() as Node2D
				_world.add_child(site)
				site.global_position = pos
				d += site_spacing
			lane_i += 1

		# Sparse plaza pads — far enough from well and each other
		var plaza_n := 2 if single_lane else 3
		for i in plaza_n:
			var ang := TAU * float(i) / float(plaza_n) + 0.55
			var pos := Vector2(cos(ang), sin(ang) * 0.85) * 260.0 + Vector2(0, 40)
			if PathNetwork and PathNetwork.dist_to_path(pos) < 90.0:
				continue
			if _too_close_to_existing_sites(pos, 200.0):
				continue
			var site2: Node2D = _site_scene.instantiate() as Node2D
			_world.add_child(site2)
			site2.global_position = pos

	# Essence wells: midpoints between tower pads so harvest never stacks on build
	if _essence_scene and PathNetwork:
		var site_list: Array[Node2D] = []
		for c in _world.get_children():
			if c is Node2D and c.has_method("try_queue_build") and _node_counts_for_spacing(c):
				site_list.append(c as Node2D)
		site_list.sort_custom(func(a: Node2D, b: Node2D) -> bool:
			return a.global_position.distance_to(PathNetwork.CRYSTAL) > b.global_position.distance_to(PathNetwork.CRYSTAL)
		)
		var want := 3 if PathNetwork.lane_count() <= 1 else maxi(2, PathNetwork.lane_count())
		var placed := 0
		for i in range(site_list.size() - 1):
			if placed >= want:
				break
			var a: Node2D = site_list[i]
			var b: Node2D = site_list[i + 1]
			# Only use pairs that are reasonably spaced (true midpoints along the line)
			if a.global_position.distance_to(b.global_position) < 200.0:
				continue
			var mid: Vector2 = (a.global_position + b.global_position) * 0.5
			var on_path: Vector2 = PathNetwork.nearest_on_network(mid)
			var away: Vector2 = mid - on_path
			if away.length_squared() < 4.0:
				var tan := (b.global_position - a.global_position).normalized()
				away = Vector2(-tan.y, tan.x)
			var dir := away.normalized()
			var pos: Vector2 = on_path + dir * 145.0
			if not _economy_pos_ok(pos, 165.0, 190.0):
				pos = on_path - dir * 145.0
			if not _economy_pos_ok(pos, 165.0, 190.0):
				pos = on_path + dir * 180.0
			if not _economy_pos_ok(pos, 155.0, 180.0):
				continue
			var node: Node2D = _essence_scene.instantiate() as Node2D
			_world.add_child(node)
			node.global_position = pos
			node.add_to_group("essence_nodes")
			placed += 1

	# Far spawn markers at path portals
	if PathNetwork:
		var i := 0
		for anchor in PathNetwork.spawn_anchors:
			var m := Marker2D.new()
			m.name = "LaneSpawn%d" % i
			m.position = anchor
			_spawns.add_child(m)
			i += 1

	if _wave_manager and _wave_manager.has_method("refresh_spawn_points"):
		_wave_manager.refresh_spawn_points()


func _economy_pos_ok(pos: Vector2, min_site: float, min_essence: float) -> bool:
	if pos.length() < 140.0:
		return false
	if PathNetwork and PathNetwork.dist_to_path(pos) < 90.0:
		return false
	if _too_close_to_existing_sites(pos, min_site):
		return false
	if _too_close_to_group_or_class(pos, "essence_nodes", min_essence):
		return false
	return true


func _retire_scene_economy_nodes() -> void:
	## Remove authored Essence*/Site* near the well — they stacked harvest & build.
	if _world == null:
		return
	var doomed: Array[Node] = []
	for c in _world.get_children():
		if not (c is Node2D):
			continue
		var n := str(c.name)
		if n.begins_with("Essence") or n.begins_with("Site"):
			doomed.append(c)
	for c in doomed:
		_world.remove_child(c)
		c.free()


func _zone_labels() -> void:
	# Intentionally empty — zone text cluttered the playfield.
	pass


func _node_counts_for_spacing(n: Node) -> bool:
	if n == null or not is_instance_valid(n):
		return false
	if n is CanvasItem and not (n as CanvasItem).visible:
		return false
	if n.process_mode == Node.PROCESS_MODE_DISABLED:
		return false
	return true


func _too_close_to_group_or_class(pos: Vector2, group: String, min_dist: float) -> bool:
	for n in get_tree().get_nodes_in_group(group):
		if not _node_counts_for_spacing(n):
			continue
		if n is Node2D and (n as Node2D).global_position.distance_to(pos) < min_dist:
			return true
	return false


func _too_close_to_existing_sites(pos: Vector2, min_dist: float) -> bool:
	for c in _world.get_children():
		if not _node_counts_for_spacing(c):
			continue
		if c.has_method("try_queue_build") and c.global_position.distance_to(pos) < min_dist:
			return true
	return false


func _build_atmosphere() -> void:
	# Spec: cold violet night + warm amber Lightwell shafts
	var ambient := FX.spark_particles(self, Color(0.6, 0.45, 0.9, 0.35), 28, "star")
	ambient.position = Vector2(0, 40)
	var pm := ambient.process_material as ParticleProcessMaterial
	if pm:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 480.0
		pm.gravity = Vector3(0, -1.5, 0)
		pm.initial_velocity_min = 1.5
		pm.initial_velocity_max = 9.0
		pm.scale_min = 0.4
		pm.scale_max = 1.4

	# Amber god-rays from the well (warm crystal light)
	for i in 4:
		var ray := Polygon2D.new()
		var ang := -0.85 + i * 0.4
		ray.polygon = PackedVector2Array([
			Vector2(0, 20),
			Vector2(cos(ang - 0.1) * 40, sin(ang - 0.1) * 30 - 70),
			Vector2(cos(ang + 0.1) * 260, sin(ang + 0.1) * 140 - 240),
			Vector2(cos(ang - 0.1) * 260, sin(ang - 0.1) * 140 - 240),
		])
		ray.color = Color(0.95, 0.75, 0.4, 0.04 + i * 0.008)
		ray.z_index = -20
		ray.position = Vector2(0, 40)
		add_child(ray)
	# Cool violet side shafts
	for i in 3:
		var ray2 := Polygon2D.new()
		var ang2 := 0.9 + i * 0.45
		ray2.polygon = PackedVector2Array([
			Vector2(0, 30),
			Vector2(cos(ang2 - 0.1) * 30, sin(ang2 - 0.1) * 50 - 40),
			Vector2(cos(ang2 + 0.1) * 220, sin(ang2 + 0.1) * 180 - 80),
			Vector2(cos(ang2 - 0.1) * 220, sin(ang2 - 0.1) * 180 - 80),
		])
		ray2.color = Color(0.5, 0.35, 0.85, 0.03)
		ray2.z_index = -20
		ray2.position = Vector2(0, 40)
		add_child(ray2)

	# Soft dark fairy-tale grade — cool violet night + slightly lifted midtones
	var grade := CanvasModulate.new()
	grade.color = Color(0.92, 0.9, 1.02)
	add_child(grade)

	# Soft bloom / vignette post
	var post := CanvasLayer.new()
	post.set_script(load("res://scripts/post_fx.gd"))
	add_child(post)
