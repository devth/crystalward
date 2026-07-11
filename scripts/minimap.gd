extends Control
## Top-right minimap of crystal, wardens, enemies, paths.

@export var map_radius: float = 1600.0
@export var view_size: float = 140.0

func _ready() -> void:
	custom_minimum_size = Vector2(view_size, view_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := view_size
	var center := Vector2(r * 0.5, r * 0.5)
	# Background
	draw_circle(center, r * 0.48, Color(0.05, 0.07, 0.06, 0.9))
	draw_arc(center, r * 0.48, 0, TAU, 48, Color(0.5, 0.45, 0.32, 0.65), 2.0)

	# Paths
	if PathNetwork:
		for lane in PathNetwork.lanes:
			var pts: PackedVector2Array = lane
			for i in range(pts.size() - 1):
				var a := _world_to_mini(pts[i], center)
				var b := _world_to_mini(pts[i + 1], center)
				draw_line(a, b, Color(0.55, 0.4, 0.25, 0.55), 1.8)

	# Crystal
	draw_circle(_world_to_mini(PathNetwork.CRYSTAL if PathNetwork else Vector2.ZERO, center), 4.0, Color(0.55, 0.85, 0.95, 0.95))

	# Enemies / wardens / fairies
	var tree := get_tree()
	if tree:
		for e in tree.get_nodes_in_group("enemies"):
			if e is Node2D:
				draw_circle(_world_to_mini(e.global_position, center), 2.0, Color(0.9, 0.25, 0.4, 0.85))
		for w in GameState.wardens:
			if is_instance_valid(w):
				var c := Color(0.45, 0.85, 0.7) if w.get("player_index") == 0 else Color(0.95, 0.7, 0.4)
				draw_circle(_world_to_mini(w.global_position, center), 3.0, c)
		for f in tree.get_nodes_in_group("helper_fairies"):
			if f is Node2D:
				draw_circle(_world_to_mini(f.global_position, center), 1.5, Color(0.85, 0.95, 1.0, 0.9))
		for loot in tree.get_nodes_in_group("loot"):
			if loot is Node2D:
				draw_circle(_world_to_mini(loot.global_position, center), 1.2, Color(1.0, 0.9, 0.35, 0.85))


func _process(_delta: float) -> void:
	queue_redraw()


func _world_to_mini(world: Vector2, center: Vector2) -> Vector2:
	var n := world / map_radius
	n.x = clampf(n.x, -1.0, 1.0)
	n.y = clampf(n.y, -1.0, 1.0)
	return center + n * (view_size * 0.42)
