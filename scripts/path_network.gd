extends Node
## Authored path lanes per campaign map. Autoloaded as PathNetwork.

signal paths_rebuilt

const CRYSTAL := Vector2(0, 40)

var lanes: Array = []
var spawn_anchors: Array[Vector2] = []
var active_lane_set: String = "full"


func _ready() -> void:
	# Campaign may not be ready first frame
	call_deferred("_init_from_campaign")


func _init_from_campaign() -> void:
	if Campaign:
		var m: Dictionary = Campaign.get_map(Campaign.selected_map_id)
		rebuild(str(m.get("lane_set", "full")))
	else:
		rebuild("full")


func rebuild(lane_set: String = "full") -> void:
	active_lane_set = lane_set
	lanes.clear()
	spawn_anchors.clear()
	match lane_set:
		"simple":
			_add_simple()
		"cross":
			_add_cross()
		"diagonal":
			_add_diagonal()
		"winding":
			_add_winding()
		_:
			_add_full()
	paths_rebuilt.emit()


func _add_simple() -> void:
	_add_lane([Vector2(0, -1200), Vector2(0, -600), Vector2(0, -200), CRYSTAL])
	_add_lane([Vector2(0, 1200), Vector2(0, 600), Vector2(0, 250), CRYSTAL])
	_add_lane([Vector2(1200, 40), Vector2(600, 40), Vector2(250, 40), CRYSTAL])
	_add_lane([Vector2(-1200, 40), Vector2(-600, 40), Vector2(-250, 40), CRYSTAL])


func _add_cross() -> void:
	_add_simple()
	_add_lane([Vector2(900, -900), Vector2(450, -450), Vector2(200, -150), CRYSTAL])
	_add_lane([Vector2(-900, 900), Vector2(-450, 450), Vector2(-200, 180), CRYSTAL])
	_add_lane([Vector2(800, 700), Vector2(400, 200), Vector2(150, 80), CRYSTAL])
	_add_lane([Vector2(-800, -700), Vector2(-400, -200), Vector2(-150, 0), CRYSTAL])


func _add_diagonal() -> void:
	_add_lane([Vector2(1200, -1200), Vector2(700, -600), Vector2(300, -200), CRYSTAL])
	_add_lane([Vector2(-1200, -1200), Vector2(-700, -600), Vector2(-300, -200), CRYSTAL])
	_add_lane([Vector2(1200, 1200), Vector2(700, 600), Vector2(300, 220), CRYSTAL])
	_add_lane([Vector2(-1200, 1200), Vector2(-700, 600), Vector2(-300, 220), CRYSTAL])
	_add_lane([Vector2(0, -1400), Vector2(100, -700), Vector2(-50, -300), CRYSTAL])
	_add_lane([Vector2(1400, 0), Vector2(700, 100), Vector2(300, 20), CRYSTAL])


func _add_winding() -> void:
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
	_add_lane([Vector2(0, 1300), Vector2(-150, 700), Vector2(80, 350), CRYSTAL])
	_add_lane([Vector2(-1300, -200), Vector2(-600, 50), Vector2(-280, 40), CRYSTAL])


func _add_full() -> void:
	_add_simple()
	_add_diagonal()
	_add_winding()


func _add_lane(points: Array) -> void:
	var packed := PackedVector2Array()
	for p in points:
		packed.append(p as Vector2)
	lanes.append(packed)
	if packed.size() > 0:
		spawn_anchors.append(packed[0])


func random_lane() -> PackedVector2Array:
	if lanes.is_empty():
		rebuild(active_lane_set)
	return lanes[randi() % lanes.size()]


func lane_count() -> int:
	return lanes.size()


func lane_length(lane: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(lane.size() - 1):
		total += lane[i].distance_to(lane[i + 1])
	return total


## Sample a point along a lane polyline. Returns { pos, tangent, normal, dist, length, at_end }.
func sample_lane(lane: PackedVector2Array, dist: float) -> Dictionary:
	var empty := {
		"pos": CRYSTAL,
		"tangent": Vector2.DOWN,
		"normal": Vector2.RIGHT,
		"dist": 0.0,
		"length": 0.0,
		"at_end": true,
	}
	if lane.is_empty():
		return empty
	if lane.size() == 1:
		empty.pos = lane[0]
		return empty

	var length := lane_length(lane)
	var d := clampf(dist, 0.0, maxf(0.0, length))
	var walked := 0.0
	for i in range(lane.size() - 1):
		var a: Vector2 = lane[i]
		var b: Vector2 = lane[i + 1]
		var seg := a.distance_to(b)
		if seg < 0.001:
			continue
		if walked + seg >= d:
			var t := (d - walked) / seg
			var tangent: Vector2 = (b - a) / seg
			var normal := Vector2(-tangent.y, tangent.x)
			return {
				"pos": a.lerp(b, t),
				"tangent": tangent,
				"normal": normal,
				"dist": d,
				"length": length,
				"at_end": d >= length - 1.0,
			}
		walked += seg

	var last: Vector2 = lane[lane.size() - 1]
	var prev: Vector2 = lane[lane.size() - 2]
	var tan2: Vector2 = (last - prev).normalized()
	if tan2.length_squared() < 0.001:
		tan2 = Vector2.DOWN
	return {
		"pos": last,
		"tangent": tan2,
		"normal": Vector2(-tan2.y, tan2.x),
		"dist": length,
		"length": length,
		"at_end": true,
	}


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


func path_normal_at(lane: PackedVector2Array, index: int) -> Vector2:
	if lane.size() < 2:
		return Vector2.RIGHT
	var i := clampi(index, 0, lane.size() - 2)
	var dir: Vector2 = (lane[i + 1] - lane[i]).normalized()
	return Vector2(-dir.y, dir.x)
