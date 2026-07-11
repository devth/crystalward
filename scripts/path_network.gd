extends Node
## Authored path lanes per campaign map. Autoloaded as PathNetwork.
## Few winding roads; ethereal landmarks sit beside the path, never on it.

signal paths_rebuilt

const CRYSTAL := Vector2(0, 40)
## Keep decor / pads outside this distance from road center.
const PATH_CLEAR_RADIUS := 100.0

var lanes: Array = []
var spawn_anchors: Array[Vector2] = []
var active_lane_set: String = "single"
## Landmarks for ground art: forest | fairy_ring | crystal_grove
var features: Array[Dictionary] = []  # { "id", "pos", "kind", "radius" }


func _ready() -> void:
	call_deferred("_init_from_campaign")


func _init_from_campaign() -> void:
	if Campaign:
		var m: Dictionary = Campaign.get_map(Campaign.selected_map_id)
		rebuild(str(m.get("lane_set", "single")))
	else:
		rebuild("single")


func rebuild(lane_set: String = "single") -> void:
	active_lane_set = lane_set
	lanes.clear()
	spawn_anchors.clear()
	features.clear()
	_place_shared_features()
	match lane_set:
		"single", "simple":
			_add_single()
		"dual":
			_add_dual()
		"meander":
			_add_meander()
		"cross":
			_add_cross()
		"winding":
			_add_winding()
		"full", "diagonal":
			_add_full()
		_:
			_add_single()
	# Nudge any feature that landed on a road off the path.
	_clear_features_from_paths()
	paths_rebuilt.emit()


func _place_shared_features() -> void:
	# Ethereal landmarks — forests, fairy rings, crystal groves (no rock mountains).
	if active_lane_set in ["single", "simple"]:
		_feature("flank_wood_e", Vector2(380, 260), "forest", 130.0)
		_feature("flank_wood_w", Vector2(-400, 440), "forest", 120.0)
		_feature("mid_ring", Vector2(220, 680), "fairy_ring", 90.0)
		_feature("far_crystals", Vector2(-120, 1000), "crystal_grove", 100.0)
		_feature("well_grove", Vector2(-300, -140), "forest", 95.0)
		_feature("side_ring", Vector2(-280, 720), "fairy_ring", 70.0)
		return
	_feature("north_ring", Vector2(-100, -720), "fairy_ring", 120.0)
	_feature("south_crystals", Vector2(120, 760), "crystal_grove", 110.0)
	_feature("west_wood", Vector2(-700, -60), "forest", 160.0)
	_feature("east_wood", Vector2(720, 60), "forest", 150.0)
	_feature("nw_grove", Vector2(-500, -400), "forest", 120.0)
	_feature("ne_ring", Vector2(540, -360), "fairy_ring", 100.0)
	_feature("sw_crystals", Vector2(-460, 500), "crystal_grove", 110.0)
	_feature("se_grove", Vector2(520, 540), "forest", 120.0)
	_feature("mid_south_ring", Vector2(-200, 400), "fairy_ring", 80.0)


func _feature(id: String, pos: Vector2, kind: String, radius: float) -> void:
	features.append({"id": id, "pos": pos, "kind": kind, "radius": radius})


func _clear_features_from_paths() -> void:
	for i in features.size():
		var f: Dictionary = features[i]
		var pos: Vector2 = f.get("pos", Vector2.ZERO)
		var need := PATH_CLEAR_RADIUS + 50.0
		var d := dist_to_path(pos)
		if d >= need:
			continue
		# Push outward along path normal so clusters never sit on the road.
		var near := nearest_on_network(pos)
		var away := pos - near
		if away.length_squared() < 1.0:
			away = Vector2.RIGHT
		var pushed: Vector2 = near + away.normalized() * need
		f["pos"] = pushed
		features[i] = f


func _add_single() -> void:
	## One long winding approach — clear chokepoints, deep curves.
	_add_curved_lane([
		Vector2(60, 1380),
		Vector2(-220, 1180),
		Vector2(160, 980),
		Vector2(320, 780),
		Vector2(40, 620),
		Vector2(-280, 480),
		Vector2(-160, 340),
		Vector2(140, 240),
		Vector2(-40, 150),
		Vector2(30, 90),
		CRYSTAL,
	], 14)


func _add_dual() -> void:
	## Two long winding roads (south + east).
	_add_curved_lane([
		Vector2(40, 1380),
		Vector2(-200, 1140),
		Vector2(180, 920),
		Vector2(-80, 720),
		Vector2(200, 520),
		Vector2(-60, 340),
		Vector2(80, 200),
		Vector2(10, 100),
		CRYSTAL,
	], 13)
	_add_curved_lane([
		Vector2(1320, 60),
		Vector2(1080, -160),
		Vector2(900, 120),
		Vector2(700, -80),
		Vector2(520, 140),
		Vector2(360, -20),
		Vector2(220, 90),
		Vector2(100, 50),
		CRYSTAL,
	], 13)


func _add_meander() -> void:
	## Two very windy approaches from south-west and north-east.
	_add_curved_lane([
		Vector2(-200, 1400),
		Vector2(-420, 1180),
		Vector2(-120, 980),
		Vector2(260, 860),
		Vector2(180, 660),
		Vector2(-220, 540),
		Vector2(-80, 360),
		Vector2(160, 240),
		Vector2(-20, 130),
		CRYSTAL,
	], 13)
	_add_curved_lane([
		Vector2(280, -1380),
		Vector2(480, -1120),
		Vector2(200, -920),
		Vector2(-160, -780),
		Vector2(80, -600),
		Vector2(280, -420),
		Vector2(40, -260),
		Vector2(-80, -120),
		Vector2(20, -40),
		CRYSTAL,
	], 13)


func _add_cross() -> void:
	## Two long diagonals that cross the glade — still only two fronts.
	_add_curved_lane([
		Vector2(1200, -1100),
		Vector2(880, -820),
		Vector2(620, -520),
		Vector2(360, -220),
		Vector2(180, 40),
		Vector2(40, 50),
		CRYSTAL,
	], 12)
	_add_curved_lane([
		Vector2(-1200, 1100),
		Vector2(-880, 820),
		Vector2(-560, 540),
		Vector2(-300, 300),
		Vector2(-120, 140),
		Vector2(10, 70),
		CRYSTAL,
	], 12)


func _add_winding() -> void:
	## Two serpentine routes (west + south).
	_add_curved_lane([
		Vector2(-1400, 200),
		Vector2(-1100, -80),
		Vector2(-980, 200),
		Vector2(-720, -40),
		Vector2(-520, 180),
		Vector2(-320, -20),
		Vector2(-160, 100),
		Vector2(-40, 50),
		CRYSTAL,
	], 13)
	_add_curved_lane([
		Vector2(80, 1420),
		Vector2(-280, 1160),
		Vector2(200, 940),
		Vector2(-160, 720),
		Vector2(240, 500),
		Vector2(-80, 320),
		Vector2(100, 180),
		Vector2(10, 90),
		CRYSTAL,
	], 13)


func _add_full() -> void:
	## Endgame: three long winding roads max — not a path spaghetti.
	_add_curved_lane([
		Vector2(40, 1400),
		Vector2(-260, 1160),
		Vector2(200, 940),
		Vector2(-140, 700),
		Vector2(220, 480),
		Vector2(-40, 280),
		Vector2(60, 140),
		CRYSTAL,
	], 13)
	_add_curved_lane([
		Vector2(1300, -80),
		Vector2(1040, 160),
		Vector2(820, -100),
		Vector2(600, 140),
		Vector2(400, -40),
		Vector2(220, 80),
		Vector2(90, 50),
		CRYSTAL,
	], 13)
	_add_curved_lane([
		Vector2(-200, -1380),
		Vector2(180, -1120),
		Vector2(-220, -880),
		Vector2(160, -620),
		Vector2(-100, -380),
		Vector2(80, -180),
		Vector2(-10, -40),
		CRYSTAL,
	], 13)


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
