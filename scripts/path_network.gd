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
		"simple", "meander":
			_add_meander()  # even "simple" maps get a rich path network
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
	# Forests and peaks — roads snake around these islands.
	_feature("north_peak", Vector2(-80, -680), "mountain", 150.0)
	_feature("south_ridge", Vector2(100, 720), "mountain", 140.0)
	_feature("west_wood", Vector2(-680, -80), "forest", 180.0)
	_feature("east_wood", Vector2(700, 40), "forest", 170.0)
	_feature("nw_grove", Vector2(-480, -420), "forest", 130.0)
	_feature("ne_grove", Vector2(520, -380), "forest", 120.0)
	_feature("sw_bogwood", Vector2(-440, 480), "forest", 140.0)
	_feature("se_grove", Vector2(500, 520), "forest", 130.0)
	_feature("west_crag", Vector2(-860, 240), "mountain", 110.0)
	_feature("east_crag", Vector2(880, -220), "mountain", 110.0)
	_feature("mid_north_knoll", Vector2(200, -400), "mountain", 80.0)
	_feature("mid_south_knoll", Vector2(-180, 380), "forest", 90.0)


func _feature(id: String, pos: Vector2, kind: String, radius: float) -> void:
	features.append({"id": id, "pos": pos, "kind": kind, "radius": radius})


func _add_meander() -> void:
	## Tutorial+ network: 6 long S-curve approaches that weave past woods & peaks.
	# North-west meander — S-curve around north peak and nw grove
	_add_curved_lane([
		Vector2(-180, -1400),
		Vector2(160, -1180),
		Vector2(280, -960),
		Vector2(40, -800),
		Vector2(-300, -700),
		Vector2(-380, -520),
		Vector2(-160, -380),
		Vector2(80, -280),
		Vector2(-40, -140),
		CRYSTAL,
	], 12)
	# North-east loop — hugs east of peak, dips past mid knoll
	_add_curved_lane([
		Vector2(220, -1380),
		Vector2(420, -1120),
		Vector2(360, -880),
		Vector2(160, -720),
		Vector2(320, -520),
		Vector2(200, -340),
		Vector2(60, -200),
		Vector2(20, -80),
		CRYSTAL,
	], 12)
	# South-east serpentine
	_add_curved_lane([
		Vector2(120, 1400),
		Vector2(-200, 1180),
		Vector2(-280, 940),
		Vector2(40, 800),
		Vector2(340, 680),
		Vector2(300, 480),
		Vector2(80, 360),
		Vector2(-60, 220),
		Vector2(20, 120),
		CRYSTAL,
	], 12)
	# South-west bog crawl
	_add_curved_lane([
		Vector2(-260, 1380),
		Vector2(-480, 1120),
		Vector2(-360, 880),
		Vector2(-120, 720),
		Vector2(-320, 540),
		Vector2(-200, 360),
		Vector2(-40, 240),
		Vector2(10, 120),
		CRYSTAL,
	], 12)
	# East river-bend — long switchback around east wood
	_add_curved_lane([
		Vector2(1400, -80),
		Vector2(1180, 180),
		Vector2(980, 320),
		Vector2(720, 260),
		Vector2(600, 60),
		Vector2(720, -120),
		Vector2(480, -80),
		Vector2(340, 80),
		Vector2(200, 40),
		Vector2(100, 50),
		CRYSTAL,
	], 12)
	# West thorn spiral — around west wood then south then in
	_add_curved_lane([
		Vector2(-1400, 40),
		Vector2(-1180, -200),
		Vector2(-960, -320),
		Vector2(-720, -200),
		Vector2(-640, 40),
		Vector2(-780, 200),
		Vector2(-520, 220),
		Vector2(-360, 80),
		Vector2(-200, 20),
		Vector2(-90, 45),
		CRYSTAL,
	], 12)


func _add_simple() -> void:
	# Alias kept for older call sites
	_add_meander()


func _add_cross() -> void:
	_add_meander()
	# Extra diagonal braids between groves
	_add_curved_lane([
		Vector2(1200, -1200), Vector2(900, -980), Vector2(640, -700),
		Vector2(480, -420), Vector2(300, -200), Vector2(140, -40),
		Vector2(40, 30), CRYSTAL,
	], 11)
	_add_curved_lane([
		Vector2(-1200, 1200), Vector2(-900, 960), Vector2(-620, 700),
		Vector2(-400, 420), Vector2(-220, 220), Vector2(-80, 100),
		CRYSTAL,
	], 11)
	_add_curved_lane([
		Vector2(1100, 1000), Vector2(820, 760), Vector2(560, 500),
		Vector2(360, 280), Vector2(180, 140), Vector2(60, 70), CRYSTAL,
	], 11)
	_add_curved_lane([
		Vector2(-1100, -1000), Vector2(-800, -740), Vector2(-520, -460),
		Vector2(-300, -220), Vector2(-120, -40), CRYSTAL,
	], 11)


func _add_diagonal() -> void:
	_add_curved_lane([
		Vector2(1350, -1350), Vector2(1000, -1100), Vector2(700, -780),
		Vector2(520, -480), Vector2(280, -220), Vector2(100, 10), CRYSTAL,
	], 12)
	_add_curved_lane([
		Vector2(-1350, -1350), Vector2(-980, -1050), Vector2(-700, -720),
		Vector2(-420, -400), Vector2(-220, -140), Vector2(-70, 30), CRYSTAL,
	], 12)
	_add_curved_lane([
		Vector2(1350, 1350), Vector2(1000, 1080), Vector2(680, 760),
		Vector2(420, 440), Vector2(220, 220), Vector2(70, 90), CRYSTAL,
	], 12)
	_add_curved_lane([
		Vector2(-1350, 1350), Vector2(-1000, 1080), Vector2(-680, 760),
		Vector2(-420, 440), Vector2(-200, 220), Vector2(-70, 100), CRYSTAL,
	], 12)
	# Zigzag mid approaches
	_add_curved_lane([
		Vector2(80, -1450), Vector2(-260, -1100), Vector2(200, -820),
		Vector2(-180, -520), Vector2(120, -280), Vector2(-20, -100), CRYSTAL,
	], 12)
	_add_curved_lane([
		Vector2(1450, 60), Vector2(1100, -160), Vector2(820, 120),
		Vector2(560, -40), Vector2(320, 100), Vector2(140, 30), CRYSTAL,
	], 12)
	_add_curved_lane([
		Vector2(-1450, -40), Vector2(-1080, 180), Vector2(-780, -100),
		Vector2(-500, 80), Vector2(-260, -20), Vector2(-100, 50), CRYSTAL,
	], 12)


func _add_winding() -> void:
	_add_curved_lane([
		Vector2(480, -1450), Vector2(920, -1150), Vector2(700, -880),
		Vector2(980, -620), Vector2(620, -420), Vector2(400, -200),
		Vector2(160, -60), CRYSTAL,
	], 12)
	_add_curved_lane([
		Vector2(-1480, 380), Vector2(-1100, 80), Vector2(-1200, -240),
		Vector2(-800, -320), Vector2(-560, -80), Vector2(-300, 40), CRYSTAL,
	], 12)
	_add_curved_lane([
		Vector2(1480, -400), Vector2(1100, 60), Vector2(960, 380),
		Vector2(620, 420), Vector2(380, 200), Vector2(160, 80), CRYSTAL,
	], 12)
	_add_curved_lane([
		Vector2(-580, 1480), Vector2(-120, 1180), Vector2(360, 1000),
		Vector2(280, 700), Vector2(40, 480), Vector2(30, 220), CRYSTAL,
	], 12)
	_add_curved_lane([
		Vector2(-80, 1450), Vector2(-320, 1050), Vector2(140, 820),
		Vector2(-100, 560), Vector2(80, 340), Vector2(10, 140), CRYSTAL,
	], 12)
	_add_curved_lane([
		Vector2(-1400, -220), Vector2(-1000, 40), Vector2(-720, -160),
		Vector2(-480, 60), Vector2(-240, 10), CRYSTAL,
	], 12)
	_add_curved_lane([
		Vector2(200, -1480), Vector2(-100, -1100), Vector2(280, -780),
		Vector2(-60, -480), Vector2(100, -220), CRYSTAL,
	], 12)


func _add_full() -> void:
	_add_meander()
	_add_diagonal()
	_add_winding()


## Control points → dense Catmull-Rom polyline so roads look smoothly curved.
func _add_curved_lane(control: Array, samples_per_span: int = 12) -> void:
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
