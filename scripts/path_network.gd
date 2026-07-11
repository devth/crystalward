extends Node
## Authored path lanes per campaign map. Autoloaded as PathNetwork.
## Long winding roads weave past hills, mountains, lakes, and forests.

signal paths_rebuilt

const CRYSTAL := Vector2(0, 40)
const PATH_CLEAR_RADIUS := 100.0

var lanes: Array = []
var spawn_anchors: Array[Vector2] = []
var active_lane_set: String = "single"
## { id, pos, kind, radius, elev }
## kind: forest | fairy_ring | crystal_grove | mountain | hill | lake
var features: Array[Dictionary] = []


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
	_clear_features_from_paths()
	paths_rebuilt.emit()


func _place_shared_features() -> void:
	## Landmarks the road bends around — placed first so control points can aim past them.
	if active_lane_set in ["single", "simple"]:
		# Massifs along the long southern approach (path snakes between these).
		_feature("far_south_peak", Vector2(-200, 1680), "mountain", 180.0, 1.15)
		_feature("south_peak", Vector2(260, 1380), "mountain", 165.0, 1.05)
		_feature("ridge_spur", Vector2(-380, 1220), "hill", 130.0, 0.6)
		_feature("mid_hill_e", Vector2(460, 980), "hill", 155.0, 0.65)
		_feature("mid_hill_w", Vector2(-520, 860), "hill", 145.0, 0.6)
		_feature("lake_amber", Vector2(320, 640), "lake", 170.0, -0.65)
		_feature("lake_mist", Vector2(-520, 520), "lake", 130.0, -0.5)
		_feature("lake_south", Vector2(80, 1100), "lake", 100.0, -0.4)
		_feature("ridge_n", Vector2(-280, 360), "hill", 125.0, 0.55)
		_feature("east_knoll", Vector2(480, 240), "hill", 110.0, 0.45)
		_feature("west_knoll", Vector2(-480, 160), "hill", 100.0, 0.4)
		_feature("well_grove", Vector2(-360, -160), "forest", 140.0, 0.2)
		_feature("east_wood", Vector2(460, 360), "forest", 150.0, 0.22)
		_feature("south_wood", Vector2(-100, 1480), "forest", 120.0, 0.18)
		_feature("far_crystals", Vector2(40, 1900), "crystal_grove", 95.0, 0.25)
		_feature("fairy_mid", Vector2(-420, 1040), "fairy_ring", 85.0, 0.12)
		_feature("fairy_lake", Vector2(180, 720), "fairy_ring", 70.0, 0.08)
		_feature("crystal_pass", Vector2(-140, 200), "crystal_grove", 85.0, 0.28)
		return
	# Multi-path maps — richer basin
	_feature("north_peak", Vector2(-80, -820), "mountain", 180.0, 1.1)
	_feature("south_ridge", Vector2(100, 980), "mountain", 160.0, 1.0)
	_feature("west_mountain", Vector2(-880, 120), "mountain", 150.0, 0.95)
	_feature("east_peak", Vector2(900, -80), "mountain", 145.0, 0.9)
	_feature("west_hill", Vector2(-720, 40), "hill", 165.0, 0.6)
	_feature("east_hill", Vector2(760, -40), "hill", 155.0, 0.55)
	_feature("sw_hill", Vector2(-480, 720), "hill", 130.0, 0.5)
	_feature("ne_hill", Vector2(500, -520), "hill", 120.0, 0.48)
	_feature("lake_west", Vector2(-540, 400), "lake", 155.0, -0.6)
	_feature("lake_east", Vector2(560, -340), "lake", 145.0, -0.55)
	_feature("lake_south", Vector2(40, 620), "lake", 120.0, -0.45)
	_feature("nw_wood", Vector2(-540, -440), "forest", 150.0, 0.22)
	_feature("ne_wood", Vector2(580, -420), "forest", 140.0, 0.22)
	_feature("sw_wood", Vector2(-500, 640), "forest", 150.0, 0.22)
	_feature("se_wood", Vector2(540, 620), "forest", 140.0, 0.22)
	_feature("mid_hill", Vector2(220, 220), "hill", 110.0, 0.45)
	_feature("crystal_spur", Vector2(-200, -220), "crystal_grove", 95.0, 0.28)
	_feature("fairy_glade", Vector2(280, 380), "fairy_ring", 80.0, 0.1)


func _feature(id: String, pos: Vector2, kind: String, radius: float, elev: float = 0.0) -> void:
	features.append({"id": id, "pos": pos, "kind": kind, "radius": radius, "elev": elev})


func elevation_at(world_pos: Vector2) -> float:
	## Pseudo-height -1..1+ from landmarks (lakes negative, peaks positive).
	var h := 0.0
	for f in features:
		var c: Vector2 = f.get("pos", Vector2.ZERO)
		var r: float = float(f.get("radius", 100.0))
		var peak: float = float(f.get("elev", 0.0))
		var d := world_pos.distance_to(c)
		var fall := r * 2.2
		if d < fall and peak != 0.0:
			var t := 1.0 - d / fall
			# Smooth cubic falloff for soft hills
			h += peak * t * t * (3.0 - 2.0 * t)
	# Regional undulation — rolling highland feel
	h += 0.12 * sin(world_pos.x * 0.0038) * cos(world_pos.y * 0.0032)
	h += 0.06 * sin(world_pos.x * 0.007 + world_pos.y * 0.005)
	return h


func _clear_features_from_paths() -> void:
	for i in features.size():
		var f: Dictionary = features[i]
		var pos: Vector2 = f.get("pos", Vector2.ZERO)
		var kind: String = str(f.get("kind", ""))
		# Lakes sit beside roads (shore); keep centers off the dirt
		var need := PATH_CLEAR_RADIUS + (90.0 if kind == "mountain" else 55.0)
		if kind == "lake":
			need = PATH_CLEAR_RADIUS + 40.0
		var d := dist_to_path(pos)
		if d >= need:
			continue
		var near := nearest_on_network(pos)
		var away := pos - near
		if away.length_squared() < 1.0:
			away = Vector2.RIGHT
		f["pos"] = near + away.normalized() * need
		features[i] = f


func _add_single() -> void:
	## Very long southern approach — snakes past peaks, around hills, along lake shores.
	_add_curved_lane([
		Vector2(60, 2050),         # far portal in the southern wilds
		Vector2(-220, 1920),
		Vector2(180, 1800),        # east of far_south_peak
		Vector2(360, 1680),
		Vector2(200, 1560),
		Vector2(-160, 1500),       # west swing past south wood
		Vector2(-340, 1400),
		Vector2(-100, 1320),
		Vector2(280, 1280),        # east face of south peak
		Vector2(420, 1180),
		Vector2(300, 1080),
		Vector2(40, 1020),         # north of lake_south
		Vector2(-280, 980),
		Vector2(-500, 920),        # west of mid_hill_w
		Vector2(-560, 800),
		Vector2(-320, 740),
		Vector2(40, 700),
		Vector2(360, 720),         # between hills toward amber lake
		Vector2(520, 640),         # east shore of amber lake
		Vector2(480, 520),
		Vector2(240, 480),
		Vector2(-40, 500),
		Vector2(-360, 480),        # near lake_mist shore
		Vector2(-520, 400),
		Vector2(-380, 300),
		Vector2(-120, 280),
		Vector2(200, 260),         # past east_knoll
		Vector2(360, 180),
		Vector2(160, 140),
		Vector2(-80, 120),
		Vector2(-40, 80),
		CRYSTAL,
	], 18)


func _add_dual() -> void:
	_add_curved_lane([
		Vector2(40, 1950),
		Vector2(-320, 1780),
		Vector2(160, 1580),
		Vector2(400, 1380),
		Vector2(200, 1180),
		Vector2(-220, 1020),
		Vector2(-480, 880),
		Vector2(-200, 720),
		Vector2(220, 620),
		Vector2(400, 480),
		Vector2(80, 360),
		Vector2(-160, 260),
		Vector2(80, 160),
		Vector2(10, 90),
		CRYSTAL,
	], 16)
	_add_curved_lane([
		Vector2(1680, 60),
		Vector2(1480, -220),
		Vector2(1280, 140),
		Vector2(1080, -100),
		Vector2(880, 180),
		Vector2(680, -60),
		Vector2(500, 160),
		Vector2(340, 20),
		Vector2(180, 90),
		Vector2(60, 55),
		CRYSTAL,
	], 16)


func _add_meander() -> void:
	_add_curved_lane([
		Vector2(-240, 1900),
		Vector2(-520, 1700),
		Vector2(-280, 1500),
		Vector2(200, 1380),
		Vector2(420, 1200),
		Vector2(160, 1040),
		Vector2(-280, 940),
		Vector2(-480, 780),
		Vector2(-120, 640),
		Vector2(280, 520),
		Vector2(80, 380),
		Vector2(-180, 280),
		Vector2(100, 160),
		Vector2(-10, 90),
		CRYSTAL,
	], 16)
	_add_curved_lane([
		Vector2(320, -1780),
		Vector2(560, -1560),
		Vector2(240, -1360),
		Vector2(-240, -1180),
		Vector2(100, -980),
		Vector2(400, -780),
		Vector2(80, -600),
		Vector2(-220, -420),
		Vector2(120, -260),
		Vector2(-60, -100),
		Vector2(20, -20),
		CRYSTAL,
	], 16)


func _add_cross() -> void:
	_add_curved_lane([
		Vector2(1520, -1380),
		Vector2(1240, -1100),
		Vector2(960, -840),
		Vector2(700, -560),
		Vector2(460, -300),
		Vector2(260, -80),
		Vector2(120, 50),
		Vector2(30, 55),
		CRYSTAL,
	], 15)
	_add_curved_lane([
		Vector2(-1520, 1380),
		Vector2(-1240, 1100),
		Vector2(-940, 820),
		Vector2(-640, 540),
		Vector2(-360, 300),
		Vector2(-160, 140),
		Vector2(10, 70),
		CRYSTAL,
	], 15)


func _add_winding() -> void:
	_add_curved_lane([
		Vector2(-1780, 200),
		Vector2(-1520, -160),
		Vector2(-1300, 220),
		Vector2(-1080, -80),
		Vector2(-860, 220),
		Vector2(-640, -60),
		Vector2(-440, 180),
		Vector2(-260, 20),
		Vector2(-100, 80),
		Vector2(-20, 50),
		CRYSTAL,
	], 16)
	_add_curved_lane([
		Vector2(60, 1920),
		Vector2(-340, 1720),
		Vector2(260, 1500),
		Vector2(-220, 1280),
		Vector2(320, 1060),
		Vector2(-160, 860),
		Vector2(260, 660),
		Vector2(-100, 480),
		Vector2(160, 320),
		Vector2(-40, 180),
		Vector2(40, 90),
		CRYSTAL,
	], 16)


func _add_full() -> void:
	_add_curved_lane([
		Vector2(40, 1920),
		Vector2(-340, 1700),
		Vector2(260, 1480),
		Vector2(-220, 1240),
		Vector2(300, 1000),
		Vector2(-140, 780),
		Vector2(220, 560),
		Vector2(-80, 360),
		Vector2(100, 200),
		Vector2(20, 100),
		CRYSTAL,
	], 16)
	_add_curved_lane([
		Vector2(1680, -80),
		Vector2(1400, 180),
		Vector2(1140, -140),
		Vector2(900, 180),
		Vector2(660, -60),
		Vector2(440, 140),
		Vector2(240, 20),
		Vector2(90, 55),
		CRYSTAL,
	], 16)
	_add_curved_lane([
		Vector2(-240, -1780),
		Vector2(240, -1540),
		Vector2(-300, -1280),
		Vector2(220, -1000),
		Vector2(-180, -720),
		Vector2(140, -460),
		Vector2(-80, -220),
		Vector2(20, -40),
		CRYSTAL,
	], 16)


func _add_curved_lane(control: Array, samples_per_span: int = 14) -> void:
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
		for s in range(samples_per_span):
			var t := float(s) / float(samples_per_span)
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
		"elev": 0.0,
	}
	if lane.is_empty():
		return empty
	if lane.size() == 1:
		empty.pos = lane[0]
		empty.elev = elevation_at(lane[0])
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
			var pos: Vector2 = a.lerp(b, t)
			return {
				"pos": pos,
				"tangent": tangent,
				"normal": normal,
				"dist": d,
				"length": length,
				"at_end": d >= length - 1.0,
				"elev": elevation_at(pos),
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
		"elev": elevation_at(last),
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
