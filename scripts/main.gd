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
	# Place essence wells near mid-path (one per lane — glow is the cue, not labels)
	if _essence_scene and PathNetwork:
		var ei := 0
		for lane in PathNetwork.lanes:
			var pts: PackedVector2Array = lane
			if pts.size() < 3:
				continue
			var wi: int = mini(2, pts.size() - 2)
			var n := PathNetwork.path_normal_at(pts, wi)
			var side := 1.0 if ei % 2 == 0 else -1.0
			var pos: Vector2 = pts[wi] + n * (70.0 * side)
			if _too_close_to_group_or_class(pos, "essence_nodes", 140.0):
				continue
			var node: Node2D = _essence_scene.instantiate() as Node2D
			_world.add_child(node)
			node.global_position = pos
			node.add_to_group("essence_nodes")
			ei += 1

	# Tower sites along paths + plaza ring (sparse — readable map)
	if _site_scene and PathNetwork:
		var lane_i := 0
		for lane in PathNetwork.lanes:
			var pts: PackedVector2Array = lane
			for wi in range(1, pts.size() - 1):
				# Every other waypoint, and alternate sides per lane to cut density ~4×
				if wi % 2 == 0:
					continue
				var n := PathNetwork.path_normal_at(pts, wi)
				var side: float = 1.0 if (lane_i + wi) % 2 == 0 else -1.0
				var pos: Vector2 = pts[wi] + n * (100.0 * side)
				if pos.length() < 160.0:
					continue
				if _too_close_to_existing_sites(pos, 140.0):
					continue
				var site: Node2D = _site_scene.instantiate() as Node2D
				_world.add_child(site)
				site.global_position = pos
			lane_i += 1

		# Inner plaza defenses (4 pads, not 6)
		for i in 4:
			var ang := TAU * float(i) / 4.0 + 0.4
			var pos := Vector2(cos(ang), sin(ang) * 0.85) * 210.0 + Vector2(0, 40)
			if _too_close_to_existing_sites(pos, 110.0):
				continue
			var site2: Node2D = _site_scene.instantiate() as Node2D
			_world.add_child(site2)
			site2.global_position = pos

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


func _zone_labels() -> void:
	# Very subtle zone names — never compete with gameplay UI
	var zones := {
		"Lightwell Plaza": Vector2(0, 100),
		"Northern March": Vector2(0, -700),
		"Southern Bog": Vector2(0, 750),
		"Eastern Ruin": Vector2(800, 40),
		"Western Thorn": Vector2(-800, 40),
	}
	for name in zones:
		var lab := Label.new()
		lab.text = name
		lab.position = zones[name] + Vector2(-60, 0)
		lab.z_index = -12
		lab.modulate = Color(0.7, 0.65, 0.85, 0.18)
		lab.add_theme_font_size_override("font_size", 16)
		add_child(lab)


func _too_close_to_group_or_class(pos: Vector2, group: String, min_dist: float) -> bool:
	for n in get_tree().get_nodes_in_group(group):
		if n is Node2D and (n as Node2D).global_position.distance_to(pos) < min_dist:
			return true
	# Also scene-placed essence without group
	for c in _world.get_children():
		if c is Node2D and str(c.name).begins_with("Essence") and c.global_position.distance_to(pos) < min_dist:
			return true
	return false


func _too_close_to_existing_sites(pos: Vector2, min_dist: float) -> bool:
	for c in _world.get_children():
		if c is Node2D and (str(c.name).begins_with("Site") or c.get_script() and str(c.get_script().resource_path).ends_with("tower_site.gd")):
			if c.global_position.distance_to(pos) < min_dist:
				return true
		# Runtime sites
		if c.has_method("try_queue_build") and c.global_position.distance_to(pos) < min_dist:
			return true
	return false


func _build_atmosphere() -> void:
	var ambient := FX.spark_particles(self, Color(0.55, 0.4, 0.85, 0.4), 36, "star")
	ambient.position = Vector2(0, 40)
	var pm := ambient.process_material as ParticleProcessMaterial
	if pm:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 520.0
		pm.gravity = Vector3(0, -2, 0)
		pm.initial_velocity_min = 2.0
		pm.initial_velocity_max = 12.0
		pm.scale_min = 0.5
		pm.scale_max = 1.6

	for i in 5:
		var ray := Polygon2D.new()
		var ang := -0.7 + i * 0.35
		ray.polygon = PackedVector2Array([
			Vector2(0, 20),
			Vector2(cos(ang - 0.12) * 50, sin(ang - 0.12) * 40 - 90),
			Vector2(cos(ang + 0.12) * 280, sin(ang + 0.12) * 160 - 260),
			Vector2(cos(ang - 0.12) * 280, sin(ang - 0.12) * 160 - 260),
		])
		ray.color = Color(0.55, 0.4, 0.85, 0.035 + i * 0.008)
		ray.z_index = -20
		ray.position = Vector2(0, 40)
		add_child(ray)

	# Legend botanical grade — warm green-gold forest light
	var grade := CanvasModulate.new()
	grade.color = Color(1.04, 1.02, 0.96)
	add_child(grade)

	# Soft bloom / vignette post
	var post := CanvasLayer.new()
	post.set_script(load("res://scripts/post_fx.gd"))
	add_child(post)
