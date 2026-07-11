extends Node
## Authored path lanes per campaign map. Autoloaded as PathNetwork.
## Lanes are curvy polylines that wind around forest / mountain features.

signal paths_rebuilt

const CRYSTAL := Vector2(0, 40)

var lanes: Array = []
var spawn_anchors: Array[Vector2] = []
var active_lane_set: String = "full"
## Named landmarks for ground art to plant forests/mountains that roads bend around.
var features: Array[Dictionary] = []  # { "id", "pos", "kind", "radius" }


func _ready() -> void:
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
	features.clear()
	_place_shared_features()
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


func _place_shared_features() -> void:
	# Forests and peaks — roads are authored to arc around these.
	_feature("north_peak", Vector2(-40, -720), "mountain", 160.0)
	_feature("south_ridge", Vector2(80, 780), "mountain", 150.0)
	_feature("west_wood", Vector2(-720, -40), "forest", 200.0)
	_feature("east_wood", Vector2(760, 60), "forest", 190.0)
	_feature("nw_grove", Vector2(-520, -480), "forest", 140.0)
	_feature("ne_grove", Vector2(560, -420), "forest", 130.0)
	_feature("sw_bogwood", Vector2(-480, 520), "forest", 150.0)
	_feature("se_grove", Vector2(540, 560), "forest", 140.0)
	_feature("west_crag", Vector2(-900, 280), "mountain", 120.0)
	_feature("east_crag", Vector2(920, -260), "mountain", 120.0)


func _feature(id: String, pos: Vector2, kind: String, radius: float) -> void:
	features.append({"id": id, "pos": pos, "kind": kind, "radius": radius})


func _add_simple() -> void:
	# Four approach roads that curve around woods and peaks into the Lightwell.
	# North: from far north, slips west of the peak, then into the well.
	_add_curved_lane([
		Vector2(40, -1350),
		Vector2(-220, -1050),
		Vector2(-320, -780),
		Vector2(-180, -520),
		Vector2(60, -300),
		Vector2(20, -120),
		CRYSTAL,
	])
	# South: from far south, arcs east of the ridge.
	_add_curved_lane([
		Vector2(-60, 1350),
		Vector2(240, 1050),
		Vector2(300, 780),
		Vector2(160, 500),
		Vector2(-40, 300),
		Vector2(10, 160),
		CRYSTAL,
	])
	# East: from far east, dips south around east wood then in.
	_add_curved_lane([
		Vector2(1350, 20),
		Vector2(1050, 220),
		Vector2(780, 280),
		Vector2(520, 160),
		Vector2(300, 40),
		Vector2(160, 50),
		CRYSTAL,
	])
	# West: from far west, bows north around west wood.
	_add_curved_lane([
		Vector2(-1350, 80),
		Vector2(-1050, -180),
		Vector2(-780, -260),
		Vector2(-500, -120),
		Vector2(-280, 20),
		Vector2(-150, 50),
		CRYSTAL,
	])


func _add_cross() -> void:
	_add_simple()
	# Diagonals threading between groves
	_add_curved_lane([
		Vector2(1100, -1100), Vector2(700, -780), Vector2(420, -400),
		Vector2(280, -160), Vector2(100, 0), CRYSTAL,
	])
	_add_curved_lane([
		Vector2(-1100, 1100), Vector2(-720, 760), Vector2(-400, 420),
		Vector2(-220, 200), Vector2(-80, 100), CRYSTAL,
	])
	_add_curved_lane([
		Vector2(1000, 900), Vector2(620, 560), Vector2(340, 280),
		Vector2(160, 120), CRYSTAL,
	])
	_add_curved_lane([
		Vector2(-1000, -900), Vector2(-640, -560), Vector2(-360, -280),
		Vector2(-160, -60), CRYSTAL,
	])


func _add_diagonal() -> void:
	_add_curved_lane([
		Vector2(1300, -1300), Vector2(900, -900), Vector2(500, -500),
		Vector2(280, -220), Vector2(100, 0), CRYSTAL,
	])
	_add_curved_lane([
		Vector2(-1300, -1300), Vector2(-860, -860), Vector2(-480, -420),
		Vector2(-240, -160), Vector2(-80, 20), CRYSTAL,
	])
	_add_curved_lane([
		Vector2(1300, 1300), Vector2(880, 880), Vector2(480, 480),
		Vector2(260, 240), Vector2(90, 100), CRYSTAL,
	])
	_add_curved_lane([
		Vector2(-1300, 1300), Vector2(-900, 900), Vector2(-500, 500),
		Vector2(-260, 260), Vector2(-90, 120), CRYSTAL,
	])
	_add_curved_lane([
		Vector2(120, -1450), Vector2(-200, -900), Vector2(160, -500),
		Vector2(-40, -220), CRYSTAL,
	])
	_add_curved_lane([
		Vector2(1450, 80), Vector2(900, -120), Vector2(500, 160),
		Vector2(240, 40), CRYSTAL,
	])


func _add_winding() -> void:
	_add_curved_lane([
		Vector2(520, -1400), Vector2(900, -1000), Vector2(620, -700),
		Vector2(820, -400), Vector2(360, -280), Vector2(140, -80), CRYSTAL,
	])
	_add_curved_lane([
		Vector2(-1450, 420), Vector2(-1000, 120), Vector2(-1100, -260),
		Vector2(-620, -180), Vector2(-320, 40), CRYSTAL,
	])
	_add_curved_lane([
		Vector2(1450, -360), Vector2(1000, 80), Vector2(860, 420),
		Vector2(480, 300), Vector2(200, 120), CRYSTAL,
	])
	_add_curved_lane([
		Vector2(-620, 1450), Vector2(-160, 1050), Vector2(320, 860),
		Vector2(120, 480), Vector2(40, 220), CRYSTAL,
	])
	_add_curved_lane([
		Vector2(-40, 1350), Vector2(-220, 800), Vector2(120, 420), CRYSTAL,
	])
	_add_curved_lane([
		Vector2(-1350, -160), Vector2(-720, 80), Vector2(-300, 30), CRYSTAL,
	])


func _add_full() -> void:
	_add_simple()
	_add_diagonal()
	_add_winding()


## Control points → dense Catmull-Rom polyline so roads look smoothly curved.
func _add_curved_lane(control: Array, samples_per_span: int = 10) -> void:
	var pts: Array[Vector2] = []
	for p in control:
		pts.append(p as Vector2)
	if pts.size() < 2:
		return
	if pts.size() == 2:
		_add_lane(pts)
		return
	var dense: Array[Vector2] = []
	# Pad ends for Catmull-Rom
	var padded: Array[Vector2] = []
	padded.append(pts[0] - (pts[1] - pts[0]) * 0.25)
	for p in pts:
		padded.append(p)
	padded.append(pts[pts.size() - 1] + (pts[pts.size() - 1] - pts[pts.size() - 2]) * 0.25)

	for i in range(1, padded.size() - 2):
		var p0: Vector2 = padded[i - 1]
		var p1: Vector2 = padded[i]
		var p2: Vector2 = padded[i + 1]
		var p3: Vector2 = padded[i + 2]
		var steps := samples_per_span
		for s in range(steps):
			var t := float(s) / float(steps)
			dense.append(_catmull(p0, p1, p2, p3, t))
	dense.append(pts[pts.size() - 1])
	_add_lane(dense)


func _catmull(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * (
		(2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)


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


func dist_to_path(world_pos: Vector2) -> float:
	return world_pos.distance_to(nearest_on_network(world_pos))


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
