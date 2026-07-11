extends Node2D
## World bootstrap + atmosphere + large-map content spawns.


@onready var _world: Node2D = $World
@onready var _spawns: Node2D = $Spawns
@onready var _wave_manager: Node = $WaveManager

var _essence_scene: PackedScene
var _site_scene: PackedScene


func _ready() -> void:
	print("Crystalward — devices: ", Input.get_connected_joypads())
	_essence_scene = load("res://scenes/essence_node.tscn") as PackedScene
	_site_scene = load("res://scenes/tower_site.tscn") as PackedScene
	_expand_map_content()
	_build_atmosphere()


func _expand_map_content() -> void:
	# Crystal stays at origin-ish (0, 40) via scene. Extra gather nodes in a wide ring.
	if _essence_scene:
		var essence_count := 10
		for i in essence_count:
			var ang := TAU * float(i) / float(essence_count) + 0.35
			var radius := lerpf(350.0, 900.0, float(i % 5) / 4.0)
			var pos := Vector2(cos(ang), sin(ang) * 0.8) * radius
			# Skip if too close to existing scene essence
			if _too_close_to_group_or_class(pos, "essence_nodes", 90.0):
				pos += Vector2(cos(ang + 0.4), sin(ang + 0.4)) * 80.0
			var node: Node2D = _essence_scene.instantiate() as Node2D
			_world.add_child(node)
			node.global_position = pos
			node.add_to_group("essence_nodes")

	# Additional tower sites in two rings
	if _site_scene:
		var sites: Array[Vector2] = []
		for i in 8:
			var ang := TAU * float(i) / 8.0 + 0.2
			sites.append(Vector2(cos(ang), sin(ang) * 0.85) * 280.0)
		for i in 8:
			var ang2 := TAU * float(i) / 8.0 + 0.45
			sites.append(Vector2(cos(ang2), sin(ang2) * 0.85) * 520.0)
		# Far outposts
		for i in 4:
			var ang3 := TAU * float(i) / 4.0 + 0.1
			sites.append(Vector2(cos(ang3), sin(ang3) * 0.8) * 780.0)
		for pos in sites:
			if _too_close_to_existing_sites(pos, 70.0):
				continue
			var site: Node2D = _site_scene.instantiate() as Node2D
			_world.add_child(site)
			site.global_position = pos

	# Far enemy spawn markers (800–1400 out) — wave manager picks them all up
	var far_radii: Array[float] = [850.0, 1000.0, 1150.0, 1300.0]
	var dirs: Array[Vector2] = [
		Vector2(0, -1), Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0),
		Vector2(0.75, -0.65), Vector2(-0.75, -0.65), Vector2(0.75, 0.65), Vector2(-0.75, 0.65),
		Vector2(0.4, -0.9), Vector2(-0.4, 0.9), Vector2(0.95, 0.3), Vector2(-0.95, -0.3),
	]
	var idx := 0
	for r in far_radii:
		for d in dirs:
			if idx % 3 == 0:  # thin a bit — still many markers
				var m := Marker2D.new()
				m.name = "SpawnFar%d" % idx
				m.position = d.normalized() * r * Vector2(1.0, 0.82)
				_spawns.add_child(m)
			idx += 1

	if _wave_manager and _wave_manager.has_method("refresh_spawn_points"):
		_wave_manager.refresh_spawn_points()


func _too_close_to_group_or_class(pos: Vector2, group: String, min_dist: float) -> bool:
	for n in get_tree().get_nodes_in_group(group):
		if n is Node2D and (n as Node2D).global_position.distance_to(pos) < min_dist:
			return true
	# Also check existing World essence instances by name pattern
	if _world:
		for c in _world.get_children():
			if c is Node2D and str(c.name).begins_with("Essence"):
				if (c as Node2D).global_position.distance_to(pos) < min_dist:
					return true
	return false


func _too_close_to_existing_sites(pos: Vector2, min_dist: float) -> bool:
	if _world == null:
		return false
	for c in _world.get_children():
		if c is Node2D and (str(c.name).begins_with("Site") or c.get_script() and str(c.get_script().resource_path).ends_with("tower_site.gd")):
			if (c as Node2D).global_position.distance_to(pos) < min_dist:
				return true
	return false


func _build_atmosphere() -> void:
	var ambient := FX.spark_particles(self, Color(0.55, 0.4, 0.85, 0.35), 36)
	ambient.position = Vector2(0, 40)
	var pm := ambient.process_material as ParticleProcessMaterial
	if pm:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 420.0
		pm.gravity = Vector3(0, -2, 0)
		pm.initial_velocity_min = 2.0
		pm.initial_velocity_max = 12.0
		pm.scale_min = 0.6
		pm.scale_max = 1.8

	# Soft god-ray polygons from crystal
	for i in 3:
		var ray := Polygon2D.new()
		var ang := -0.5 + i * 0.5
		ray.polygon = PackedVector2Array([
			Vector2(0, 20),
			Vector2(cos(ang - 0.15) * 40, sin(ang - 0.15) * 40 - 80),
			Vector2(cos(ang + 0.15) * 320, sin(ang + 0.15) * 160 - 280),
			Vector2(cos(ang - 0.15) * 320, sin(ang - 0.15) * 160 - 280),
		])
		ray.color = Color(0.55, 0.4, 0.85, 0.04 + i * 0.01)
		ray.z_index = -20
		ray.position = Vector2(0, 40)
		add_child(ray)
