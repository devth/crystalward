extends Node
## Authored path lanes per campaign map. Autoloaded as PathNetwork.
## Kingdom Rush–style: edge spawns → winding dirt → crystal exit.
## Difficulty: 1 path → merge dual → split dual → cross → multi-entrance.

signal paths_rebuilt

const CRYSTAL := Vector2(0, 40)
const PATH_CLEAR_RADIUS := 100.0
## Keep dirt road outside this radius until the final approach segment.
const CRYSTAL_KEEP_OUT := 190.0

var lanes: Array = []
var spawn_anchors: Array[Vector2] = []
var active_lane_set: String = "single"
## { id, pos, kind, radius, elev }
## kind: canopy | hill | lake | pond
var features: Array[Dictionary] = []
## Swimmable water ellipses: { pos, rx, ry, kind } — rebuilt with features.
var water_bodies: Array[Dictionary] = []


func _ready() -> void:
	call_deferred("_init_from_campaign")


func _init_from_campaign() -> void:
	if Campaign:
		var m: Dictionary = Campaign.get_map(Campaign.selected_map_id) if Campaign.has_method("get_map") else {}
		if m.is_empty() and Campaign.has_method("current_map"):
			m = Campaign.current_map()
		rebuild(str(m.get("lane_set", "single")))
	else:
		rebuild("single")


func rebuild(lane_set: String = "single") -> void:
	active_lane_set = lane_set
	lanes.clear()
	spawn_anchors.clear()
	features.clear()
	water_bodies.clear()
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
	_apply_crystal_clearance()
	_rebuild_water_bodies()
	paths_rebuilt.emit()


func _place_shared_features() -> void:
	## Natural landforms: ridges, irregular hills, multi-lobe lakes (not random circles).
	if active_lane_set in ["single", "simple"]:
		# Soft rolling highland only — continuous landscape, no peak stickers
		_feature("south_rise", Vector2(40, 1480), "hill", 220.0, 0.72, {"stretch": Vector2(1.8, 0.75), "angle": 0.35})
		_feature("east_rise", Vector2(820, 180), "hill", 200.0, 0.68, {"stretch": Vector2(1.3, 1.35), "angle": -0.4})
		_feature("north_rise", Vector2(-40, -640), "hill", 210.0, 0.7, {"stretch": Vector2(1.9, 0.7), "angle": 0.1})
		_feature("west_rise", Vector2(-860, 160), "hill", 195.0, 0.65, {"stretch": Vector2(1.2, 1.4), "angle": 0.5})
		_feature("se_hills", Vector2(580, 1050), "hill", 170.0, 0.55, {"stretch": Vector2(1.5, 0.85), "angle": 0.6})
		_feature("ne_knoll", Vector2(480, -460), "hill", 155.0, 0.48, {"stretch": Vector2(1.3, 0.9), "angle": -0.3})
		_feature("nw_knoll", Vector2(-600, -340), "hill", 160.0, 0.5, {"stretch": Vector2(1.4, 0.8), "angle": 0.2})
		_feature("sw_rise", Vector2(-540, 880), "hill", 165.0, 0.52, {"stretch": Vector2(1.35, 0.95), "angle": -0.5})
		_feature("mid_knoll", Vector2(140, 220), "hill", 120.0, 0.38, {"stretch": Vector2(1.2, 1.0), "angle": 0.15})
		# Natural water systems — elongated basins, multi-lobe (seed drives shore shape)
		_water("lake_amber", Vector2(440, 400), "lake", 200.0, -0.7, 11, [
			{"o": Vector2(0, 0), "rx": 1.0, "ry": 0.55},
			{"o": Vector2(90, -40), "rx": 0.55, "ry": 0.45},
			{"o": Vector2(-70, 50), "rx": 0.5, "ry": 0.4},
		])
		_water("lake_west", Vector2(-520, 320), "lake", 190.0, -0.65, 22, [
			{"o": Vector2(0, 0), "rx": 0.85, "ry": 0.7},
			{"o": Vector2(-80, 60), "rx": 0.55, "ry": 0.5},
			{"o": Vector2(50, -70), "rx": 0.45, "ry": 0.35},
		])
		_water("lake_south", Vector2(-40, 1020), "lake", 175.0, -0.55, 33, [
			{"o": Vector2(0, 0), "rx": 1.15, "ry": 0.45},
			{"o": Vector2(100, 20), "rx": 0.5, "ry": 0.4},
			{"o": Vector2(-90, -10), "rx": 0.48, "ry": 0.38},
		])
		_water("lake_north", Vector2(180, -440), "lake", 155.0, -0.5, 44, [
			{"o": Vector2(0, 0), "rx": 0.95, "ry": 0.6},
			{"o": Vector2(70, 40), "rx": 0.5, "ry": 0.42},
		])
		# Oxbow / wetland pond systems
		_water("pond_glade", Vector2(-200, 160), "pond", 85.0, -0.32, 55, [
			{"o": Vector2(0, 0), "rx": 0.9, "ry": 0.65},
			{"o": Vector2(35, -20), "rx": 0.45, "ry": 0.4},
		])
		_water("pond_se", Vector2(540, 800), "pond", 95.0, -0.3, 66, [
			{"o": Vector2(0, 0), "rx": 1.1, "ry": 0.5},
			{"o": Vector2(-40, 25), "rx": 0.5, "ry": 0.45},
		])
		_water("pond_sw", Vector2(-400, 700), "pond", 80.0, -0.28, 77, [
			{"o": Vector2(0, 0), "rx": 0.85, "ry": 0.7},
		])
		_water("pond_stream", Vector2(60, 560), "pond", 90.0, -0.3, 88, [
			{"o": Vector2(0, 0), "rx": 1.2, "ry": 0.4},
			{"o": Vector2(55, 15), "rx": 0.55, "ry": 0.35},
			{"o": Vector2(-50, -10), "rx": 0.45, "ry": 0.38},
		])
		# Soft canopy mass (painted washes, not tree stickers)
		_feature("inner_grove", Vector2(-240, -100), "canopy", 160.0, 0.2)
		_feature("east_wood", Vector2(540, -60), "canopy", 150.0, 0.2)
		_feature("south_wood", Vector2(-260, 1300), "canopy", 160.0, 0.18)
		_feature("far_canopy", Vector2(200, 1920), "canopy", 170.0, 0.16)
		return
	# Multi-path maps — rolling highlands only
	_feature("north_rise", Vector2(-80, -820), "hill", 210.0, 0.72, {"stretch": Vector2(1.6, 0.8), "angle": 0.2})
	_feature("south_rise", Vector2(100, 980), "hill", 200.0, 0.68, {"stretch": Vector2(1.7, 0.75), "angle": -0.25})
	_feature("west_rise", Vector2(-880, 120), "hill", 190.0, 0.65, {"stretch": Vector2(1.15, 1.35), "angle": 0.4})
	_feature("east_rise", Vector2(900, -80), "hill", 185.0, 0.62, {"stretch": Vector2(1.3, 1.15), "angle": -0.35})
	_feature("west_hill", Vector2(-720, 40), "hill", 170.0, 0.55, {"stretch": Vector2(1.4, 0.9), "angle": 0.3})
	_feature("east_hill", Vector2(760, -40), "hill", 160.0, 0.52, {"stretch": Vector2(1.35, 0.95), "angle": -0.2})
	_feature("sw_hill", Vector2(-480, 720), "hill", 155.0, 0.48, {"stretch": Vector2(1.3, 1.0), "angle": 0.5})
	_feature("ne_hill", Vector2(500, -520), "hill", 145.0, 0.46, {"stretch": Vector2(1.25, 0.9), "angle": -0.4})
	_water("lake_west", Vector2(-540, 400), "lake", 185.0, -0.7, 101, [
		{"o": Vector2(0, 0), "rx": 0.9, "ry": 0.65},
		{"o": Vector2(-70, 50), "rx": 0.55, "ry": 0.5},
	])
	_water("lake_east", Vector2(560, -340), "lake", 175.0, -0.65, 112, [
		{"o": Vector2(0, 0), "rx": 1.05, "ry": 0.55},
		{"o": Vector2(60, -30), "rx": 0.5, "ry": 0.45},
	])
	_water("lake_south", Vector2(40, 620), "lake", 160.0, -0.55, 123, [
		{"o": Vector2(0, 0), "rx": 1.2, "ry": 0.48},
		{"o": Vector2(80, 20), "rx": 0.5, "ry": 0.4},
	])
	_water("pond_mid", Vector2(20, 200), "pond", 90.0, -0.32, 134, [
		{"o": Vector2(0, 0), "rx": 0.95, "ry": 0.7},
		{"o": Vector2(30, -25), "rx": 0.45, "ry": 0.4},
	])
	_feature("nw_wood", Vector2(-540, -440), "canopy", 170.0, 0.2)
	_feature("ne_wood", Vector2(580, -420), "canopy", 160.0, 0.2)
	_feature("sw_wood", Vector2(-500, 640), "canopy", 170.0, 0.2)
	_feature("se_wood", Vector2(540, 620), "canopy", 160.0, 0.2)


func _feature(id: String, pos: Vector2, kind: String, radius: float, elev: float = 0.0, extra: Dictionary = {}) -> void:
	var f := {"id": id, "pos": pos, "kind": kind, "radius": radius, "elev": elev}
	for k in extra:
		f[k] = extra[k]
	features.append(f)


func _water(id: String, pos: Vector2, kind: String, radius: float, elev: float, seed: int, lobes: Array) -> void:
	## Multi-lobe water body for natural irregular shape + swim collision.
	_feature(id, pos, kind, radius, elev, {"seed": seed, "lobes": lobes})


func _rebuild_water_bodies() -> void:
	## Multi-lobe ellipses matching organic lake visuals (for swimming).
	water_bodies.clear()
	for f in features:
		var kind: String = str(f.get("kind", ""))
		if kind not in ["lake", "pond"]:
			continue
		var center: Vector2 = f.get("pos", Vector2.ZERO)
		var r: float = float(f.get("radius", 100.0))
		var lobes: Array = f.get("lobes", [])
		var lobe_data: Array = []
		if lobes.is_empty():
			lobe_data.append({"pos": center, "rx": r * 0.9, "ry": r * 0.55})
		else:
			for lobe in lobes:
				var o: Vector2 = lobe.get("o", Vector2.ZERO) if lobe is Dictionary else Vector2.ZERO
				var lrx: float = float(lobe.get("rx", 1.0)) * r * 0.88
				var lry: float = float(lobe.get("ry", 0.6)) * r * 0.88
				lobe_data.append({"pos": center + o, "rx": lrx, "ry": lry})
		water_bodies.append({
			"pos": center,
			"kind": kind,
			"radius": r,
			"lobes": lobe_data,
			"seed": int(f.get("seed", 0)),
		})


func in_water(world_pos: Vector2) -> bool:
	return water_depth_at(world_pos) > 0.05


func water_depth_at(world_pos: Vector2) -> float:
	## 0 = dry, 1 = deep — max over multi-lobe falloff.
	var best := 0.0
	for w in water_bodies:
		var lobes: Array = w.get("lobes", [])
		if lobes.is_empty():
			continue
		for lobe in lobes:
			var c: Vector2 = lobe.get("pos", Vector2.ZERO)
			var rx: float = maxf(8.0, float(lobe.get("rx", 40.0)))
			var ry: float = maxf(8.0, float(lobe.get("ry", 28.0)))
			var local := world_pos - c
			var nx := local.x / rx
			var ny := local.y / ry
			var d2 := nx * nx + ny * ny
			if d2 >= 1.0:
				continue
			var depth := 1.0 - d2
			depth = depth * depth * (3.0 - 2.0 * depth)
			best = maxf(best, depth)
	return best


func nearest_water(world_pos: Vector2) -> Dictionary:
	var best := {}
	var best_d := INF
	for w in water_bodies:
		var c: Vector2 = w.get("pos", Vector2.ZERO)
		var d := world_pos.distance_to(c)
		if d < best_d:
			best_d = d
			best = {
				"pos": c,
				"dist": d,
				"depth": water_depth_at(world_pos),
				"kind": str(w.get("kind", "lake")),
				"radius": float(w.get("radius", 100.0)),
			}
	return best


func elevation_at(world_pos: Vector2) -> float:
	## Continuous heightfield (roughly -1.2..1.4): multi-scale terrain + landform peaks/basins.
	var h := 0.0
	# Large-scale ranges / valleys
	h += 0.38 * sin(world_pos.x * 0.0018) * cos(world_pos.y * 0.0015)
	h += 0.28 * sin(world_pos.x * 0.0011 + world_pos.y * 0.0014)
	# Medium rolling hills
	h += 0.22 * sin(world_pos.x * 0.0036) * cos(world_pos.y * 0.0031)
	h += 0.16 * cos(world_pos.x * 0.0048 - world_pos.y * 0.0038)
	# Fine knolls / dimples
	h += 0.10 * sin(world_pos.x * 0.0085 + world_pos.y * 0.0062)
	h += 0.07 * cos(world_pos.x * 0.011 - world_pos.y * 0.009)
	# Authored landforms (mountains, hills, lakes)
	for f in features:
		var c: Vector2 = f.get("pos", Vector2.ZERO)
		var r: float = float(f.get("radius", 100.0))
		var peak: float = float(f.get("elev", 0.0))
		if peak == 0.0:
			continue
		var stretch: Vector2 = f.get("stretch", Vector2.ONE) as Vector2
		var ang: float = float(f.get("angle", 0.0))
		var local := world_pos - c
		var ca := cos(ang)
		var sa := sin(ang)
		var lx := local.x * ca + local.y * sa
		var ly := -local.x * sa + local.y * ca
		var sx := maxf(0.5, stretch.x)
		var sy := maxf(0.5, stretch.y)
		var d := Vector2(lx / sx, ly / sy).length()
		var fall := r * 2.4
		if d < fall:
			var t := 1.0 - d / fall
			# Mountains peak sharp; lakes are broad bowls
			if peak > 0.0:
				h += peak * t * t * t * (1.0 + 0.35 * t)
			else:
				h += peak * t * t * (3.0 - 2.0 * t)
	# Multi-lobe water slightly deepens bowls further
	var wd := water_depth_at(world_pos)
	if wd > 0.0:
		h -= wd * 0.35
	return clampf(h, -1.35, 1.55)


func elevation_gradient(world_pos: Vector2, eps: float = 28.0) -> Vector2:
	## Approximate slope direction (points uphill).
	var e0 := elevation_at(world_pos)
	var ex := elevation_at(world_pos + Vector2(eps, 0))
	var ey := elevation_at(world_pos + Vector2(0, eps))
	return Vector2(ex - e0, ey - e0) / eps


func _clear_features_from_paths() -> void:
	for i in features.size():
		var f: Dictionary = features[i]
		var pos: Vector2 = f.get("pos", Vector2.ZERO)
		var kind: String = str(f.get("kind", ""))
		var need := PATH_CLEAR_RADIUS + (70.0 if kind == "hill" else 55.0)
		if kind == "lake":
			need = PATH_CLEAR_RADIUS + 45.0
		elif kind == "pond":
			need = PATH_CLEAR_RADIUS + 25.0
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
	## KR tutorial map: ONE path from south edge, gentle S-curve, clear chokes, long dwell.
	## Enemies spend lots of time in tower range — learn build order without split attention.
	_add_curved_lane([
		Vector2(20, 980),          # south portal
		Vector2(-160, 880),
		Vector2(-280, 740),        # swing west
		Vector2(-220, 580),
		Vector2(-40, 500),         # mid choke (tower pads both sides)
		Vector2(160, 460),
		Vector2(280, 360),         # east lobe
		Vector2(240, 240),
		Vector2(80, 280),          # curve back (second choke)
		Vector2(-100, 300),
		Vector2(-40, 220),
		Vector2(20, 200),          # final approach — stay south of well
		CRYSTAL,
	], 16)


func _add_dual() -> void:
	## KR dual-merge: two spawns (S + E) that JOIN before the crystal.
	## Teach split early defense, then a shared kill-zone near the well.
	_add_curved_lane([
		Vector2(-40, 1020),        # south portal
		Vector2(-200, 900),
		Vector2(-280, 720),
		Vector2(-180, 560),
		Vector2(-40, 480),
		Vector2(80, 420),          # → merge corridor
		Vector2(40, 300),
		Vector2(20, 210),
		CRYSTAL,
	], 15)
	_add_curved_lane([
		Vector2(1080, 60),         # east portal
		Vector2(920, -40),
		Vector2(760, 80),
		Vector2(600, 200),
		Vector2(420, 300),
		Vector2(220, 360),         # → merge corridor
		Vector2(100, 320),
		Vector2(40, 240),
		Vector2(15, 200),
		CRYSTAL,
	], 15)


func _add_meander() -> void:
	## KR split defense: two independent paths (S + N), no early merge.
	## Must hold both lanes — classic mid-campaign pressure.
	_add_curved_lane([
		Vector2(80, 1000),
		Vector2(260, 880),
		Vector2(320, 700),
		Vector2(200, 560),
		Vector2(40, 480),
		Vector2(-120, 400),
		Vector2(-80, 300),
		Vector2(40, 260),
		Vector2(20, 200),
		CRYSTAL,
	], 15)
	_add_curved_lane([
		Vector2(-60, -920),        # north portal
		Vector2(-220, -780),
		Vector2(-280, -580),
		Vector2(-160, -420),
		Vector2(40, -360),
		Vector2(180, -240),
		Vector2(120, -80),
		Vector2(-40, 40),
		Vector2(-80, 160),
		Vector2(20, 200),
		CRYSTAL,
	], 15)


func _add_cross() -> void:
	## KR “twin pass”: NE + SW roads curve past a shared mid choke (cross-fire zone).
	## Paths stay separate but run close in the middle — overlapping tower coverage.
	_add_curved_lane([
		Vector2(920, -720),        # NE portal
		Vector2(760, -520),
		Vector2(560, -320),
		Vector2(360, -120),
		Vector2(280, 80),          # near mid choke
		Vector2(200, 220),
		Vector2(80, 280),
		Vector2(20, 200),
		CRYSTAL,
	], 15)
	_add_curved_lane([
		Vector2(-920, 820),        # SW portal
		Vector2(-760, 640),
		Vector2(-560, 480),
		Vector2(-320, 360),
		Vector2(-120, 280),        # near mid choke (other side)
		Vector2(40, 300),
		Vector2(80, 240),
		Vector2(20, 190),
		CRYSTAL,
	], 15)


func _add_winding() -> void:
	## Late KR: two long serpents from W + S, little shared coverage, more distance.
	_add_curved_lane([
		Vector2(-1100, 40),        # west portal
		Vector2(-960, -160),
		Vector2(-780, -80),
		Vector2(-640, 80),
		Vector2(-520, 240),
		Vector2(-360, 200),
		Vector2(-280, 80),
		Vector2(-160, 160),
		Vector2(-40, 280),
		Vector2(40, 260),
		Vector2(20, 190),
		CRYSTAL,
	], 15)
	_add_curved_lane([
		Vector2(60, 1100),         # south portal (longer)
		Vector2(-180, 980),
		Vector2(-280, 800),
		Vector2(-160, 640),
		Vector2(80, 580),
		Vector2(260, 480),
		Vector2(280, 320),
		Vector2(140, 280),
		Vector2(40, 300),
		Vector2(20, 200),
		CRYSTAL,
	], 15)


func _add_full() -> void:
	## Boss map: three entrances (S / E / N) — full split attention like KR finales.
	_add_curved_lane([
		Vector2(40, 1050),
		Vector2(-160, 920),
		Vector2(-240, 740),
		Vector2(-100, 560),
		Vector2(80, 460),
		Vector2(160, 320),
		Vector2(40, 280),
		Vector2(20, 200),
		CRYSTAL,
	], 15)
	_add_curved_lane([
		Vector2(1100, -40),
		Vector2(920, 80),
		Vector2(740, 40),
		Vector2(560, 160),
		Vector2(380, 280),
		Vector2(200, 300),
		Vector2(60, 260),
		Vector2(20, 190),
		CRYSTAL,
	], 15)
	_add_curved_lane([
		Vector2(-40, -980),
		Vector2(140, -840),
		Vector2(220, -640),
		Vector2(80, -460),
		Vector2(-120, -300),
		Vector2(-180, -80),
		Vector2(-80, 120),
		Vector2(30, 200),
		CRYSTAL,
	], 15)


func _apply_crystal_clearance() -> void:
	## Keep dirt outside the well plaza; only the last approach may enter.
	for li in lanes.size():
		var lane: PackedVector2Array = lanes[li]
		if lane.size() < 4:
			continue
		var total := lane_length(lane)
		if total < 1.0:
			continue
		var keep_out := CRYSTAL_KEEP_OUT
		var approach_start := total * 0.86
		var walked := 0.0
		var out := PackedVector2Array()
		out.append(lane[0])
		for i in range(1, lane.size()):
			var a: Vector2 = lane[i - 1]
			var b: Vector2 = lane[i]
			var seg := a.distance_to(b)
			var mid_dist := walked + seg * 0.5
			var p: Vector2 = b
			if mid_dist < approach_start:
				var d := p.distance_to(CRYSTAL)
				if d < keep_out and d > 0.5:
					p = CRYSTAL + (p - CRYSTAL).normalized() * keep_out
			out.append(p)
			walked += seg
		out[out.size() - 1] = CRYSTAL
		lanes[li] = out
		if spawn_anchors.size() > li:
			spawn_anchors[li] = out[0]


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
