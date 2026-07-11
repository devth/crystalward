extends Node
## Authored path lanes: nightspawn follow these routes to the Lightwell.
## Autoloaded as PathNetwork.

signal paths_rebuilt

const CRYSTAL := Vector2(0, 40)

## Each lane: outer spawn → … → crystal. Built in rebuild().
var lanes: Array = []  ## Array of PackedVector2Array
var spawn_anchors: Array[Vector2] = []


func _ready() -> void:
	rebuild()


func rebuild() -> void:
	lanes.clear()
	spawn_anchors.clear()
	# Eight primary approaches + four winding “dark paths”
	_add_lane([
		Vector2(0, -1500), Vector2(40, -1100), Vector2(-30, -700), Vector2(20, -350), CRYSTAL
	])
	_add_lane([
		Vector2(0, 1500), Vector2(-50, 1100), Vector2(40, 700), Vector2(-20, 380), CRYSTAL
	])
	_add_lane([
		Vector2(1500, 40), Vector2(1100, 80), Vector2(700, 20), Vector2(380, 50), CRYSTAL
	])
	_add_lane([
		Vector2(-1500, 40), Vector2(-1100, -40), Vector2(-700, 30), Vector2(-380, 20), CRYSTAL
	])
	# Diagonals with S-curves
	_add_lane([
		Vector2(1200, -1200), Vector2(900, -700), Vector2(550, -450), Vector2(280, -180), CRYSTAL
	])
	_add_lane([
		Vector2(-1200, -1200), Vector2(-850, -750), Vector2(-500, -400), Vector2(-260, -160), CRYSTAL
	])
	_add_lane([
		Vector2(1200, 1200), Vector2(880, 720), Vector2(520, 420), Vector2(270, 200), CRYSTAL
	])
	_add_lane([
		Vector2(-1200, 1200), Vector2(-900, 700), Vector2(-540, 400), Vector2(-250, 190), CRYSTAL
	])
	# Winding forest paths (more interesting)
	_add_lane([
		Vector2(600, -1400), Vector2(900, -900), Vector2(400, -600), Vector2(600, -300),
		Vector2(200, -200), CRYSTAL
	])
	_add_lane([
		Vector2(-1400, 500), Vector2(-900, 200), Vector2(-1000, -200), Vector2(-500, -100),
		Vector2(-220, 60), CRYSTAL
	])
	_add_lane([
		Vector2(1400, -400), Vector2(1000, 100), Vector2(800, 400), Vector2(400, 250),
		Vector2(180, 100), CRYSTAL
	])
	_add_lane([
		Vector2(-700, 1400), Vector2(-200, 1000), Vector2(300, 800), Vector2(100, 400),
		Vector2(40, 200), CRYSTAL
	])
	paths_rebuilt.emit()


func _add_lane(points: Array) -> void:
	var packed := PackedVector2Array()
	for p in points:
		packed.append(p as Vector2)
	lanes.append(packed)
	if packed.size() > 0:
		spawn_anchors.append(packed[0])


func random_lane() -> PackedVector2Array:
	if lanes.is_empty():
		rebuild()
	return lanes[randi() % lanes.size()]


func lane_count() -> int:
	return lanes.size()


## Closest point on any path polyline (for props / debug).
func nearest_on_network(world_pos: Vector2) -> Vector2:
	var best := world_pos
	var best_d := INF
	for lane in lanes:
		var pts: PackedVector2Array = lane
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var proj := _project_point(world_pos, a, b)
			var d := world_pos.distance_squared_to(proj)
			if d < best_d:
				best_d = d
				best = proj
	return best


func _project_point(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var t := 0.0
	var len_sq := ab.length_squared()
	if len_sq > 0.001:
		t = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return a + ab * t


## Lateral offset direction for a path position (for visual width / unit spacing).
func path_normal_at(lane: PackedVector2Array, index: int) -> Vector2:
	if lane.size() < 2:
		return Vector2.RIGHT
	var i := clampi(index, 0, lane.size() - 2)
	var dir: Vector2 = (lane[i + 1] - lane[i]).normalized()
	return Vector2(-dir.y, dir.x)
