extends Node
## Contiguous procedural terrain — heightfield + hydrology + biomes.
## Autoloaded as TerrainWorld. Rebuilds with PathNetwork.

signal terrain_rebuilt

## World coverage (must exceed path circuit).
const ORIGIN := Vector2(-1680.0, -1480.0)
const CELL := 52.0
const COLS := 66
const ROWS := 62

## water cell codes
const W_NONE := 0
const W_STREAM := 1
const W_POND := 2
const W_LAKE := 3
const W_FALL := 4

var ready_map: bool = false
var _h: PackedFloat32Array = PackedFloat32Array()
var _m: PackedFloat32Array = PackedFloat32Array()  # moisture 0..1
var _w: PackedByteArray = PackedByteArray()
var _flow: PackedInt32Array = PackedInt32Array()  # index of downhill neighbor, or -1
var _accum: PackedFloat32Array = PackedFloat32Array()
## Stream polylines in world space (for rendering)
var stream_paths: Array = []  # Array of PackedVector2Array
## Waterfall segments: { from: Vector2, to: Vector2, strength: float }
var waterfalls: Array = []
## Rock outcrop sites: { pos, elev, slope }
var rock_sites: Array = []
## Tree sites: { pos, elev, scale }
var tree_sites: Array = []


func _ready() -> void:
	call_deferred("_try_bind")


func _try_bind() -> void:
	if PathNetwork and not PathNetwork.paths_rebuilt.is_connected(_on_paths_rebuilt):
		PathNetwork.paths_rebuilt.connect(_on_paths_rebuilt)
	if PathNetwork and PathNetwork.lane_count() > 0:
		rebuild()


func _on_paths_rebuilt() -> void:
	rebuild()


func rebuild() -> void:
	ready_map = false
	var n := COLS * ROWS
	_h.resize(n)
	_m.resize(n)
	_w.resize(n)
	_flow.resize(n)
	_accum.resize(n)
	_h.fill(0.0)
	_m.fill(0.0)
	_w.fill(0)
	_flow.fill(-1)
	_accum.fill(0.0)
	stream_paths.clear()
	waterfalls.clear()
	rock_sites.clear()
	tree_sites.clear()

	_generate_base_height()
	_apply_path_features()
	_smooth_height(2)
	_carve_road_benches()
	_compute_moisture()
	_classify_basins()
	_compute_flow()
	_accumulate_flow()
	_trace_streams()
	_mark_waterfalls()
	_scatter_sites()
	ready_map = true
	terrain_rebuilt.emit()


func world_size() -> Vector2:
	return Vector2(float(COLS) * CELL, float(ROWS) * CELL)


func elev_at(world_pos: Vector2) -> float:
	if not ready_map or _h.is_empty():
		return PathNetwork.elevation_at(world_pos) if PathNetwork else 0.0
	return _sample_bilinear(_h, world_pos)


func moisture_at(world_pos: Vector2) -> float:
	if not ready_map or _m.is_empty():
		return 0.3
	return clampf(_sample_bilinear(_m, world_pos), 0.0, 1.0)


func water_depth_at(world_pos: Vector2) -> float:
	## Continuous depth for swimming (0..1).
	if not ready_map:
		return 0.0
	var c := _world_to_cell(world_pos)
	if not _in_bounds(c.x, c.y):
		return 0.0
	var code := int(_w[_idx(c.x, c.y)])
	if code == W_NONE:
		# Soft falloff near water cells
		var best := 0.0
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var nx := c.x + dx
				var ny := c.y + dy
				if not _in_bounds(nx, ny):
					continue
				var wc := int(_w[_idx(nx, ny)])
				if wc == W_NONE:
					continue
				var d := Vector2(float(dx), float(dy)).length()
				var strength := 1.0 if wc >= W_POND else 0.55
				best = maxf(best, strength * (1.0 - d / 2.8))
		return best * 0.35
	if code == W_STREAM:
		return 0.35
	if code == W_FALL:
		return 0.25
	if code == W_POND:
		return 0.55
	# lake — deeper toward basin
	var e := elev_at(world_pos)
	return clampf(0.55 + (-e) * 0.35, 0.4, 1.0)


func in_water(world_pos: Vector2) -> bool:
	return water_depth_at(world_pos) > 0.08


func slope_at(world_pos: Vector2) -> float:
	var eps := CELL * 0.6
	var e0 := elev_at(world_pos)
	var ex := elev_at(world_pos + Vector2(eps, 0))
	var ey := elev_at(world_pos + Vector2(0, eps))
	return Vector2(ex - e0, ey - e0).length() / eps


func cell_world_center(ix: int, iy: int) -> Vector2:
	return ORIGIN + Vector2((float(ix) + 0.5) * CELL, (float(iy) + 0.5) * CELL)


func for_each_cell(cb: Callable) -> void:
	## cb(ix, iy, world_center, elev, moisture, water_code, slope)
	if not ready_map:
		return
	for iy in ROWS:
		for ix in COLS:
			var i := _idx(ix, iy)
			var p := cell_world_center(ix, iy)
			var e := _h[i]
			var sl := 0.0
			if ix > 0 and ix < COLS - 1 and iy > 0 and iy < ROWS - 1:
				sl = Vector2(_h[_idx(ix + 1, iy)] - _h[_idx(ix - 1, iy)], _h[_idx(ix, iy + 1)] - _h[_idx(ix, iy - 1)]).length() / (2.0 * CELL)
			cb.call(ix, iy, p, e, _m[i], int(_w[i]), sl)


# ── generation ───────────────────────────────────────────────────────────────

func _generate_base_height() -> void:
	for iy in ROWS:
		for ix in COLS:
			var p := cell_world_center(ix, iy)
			var h := 0.0
			# Continental-scale
			h += 0.42 * _n2(p * 0.00115 + Vector2(2.1, 0.4))
			h += 0.30 * _n2(p * 0.0024 + Vector2(-1.3, 3.2))
			# Ranges
			h += 0.28 * _n2(p * 0.0042 + Vector2(0.7, -2.0))
			h += 0.18 * _n2(p * 0.0075 + Vector2(4.0, 1.1))
			# Fine detail
			h += 0.10 * _n2(p * 0.014 + Vector2(-3.0, 2.5))
			# Soft basin around crystal (play glade)
			var d_c := p.distance_to(PathNetwork.CRYSTAL if PathNetwork else Vector2(0, 40))
			h += 0.12 * smoothstep(900.0, 220.0, d_c)  # gentle plateau near well
			h -= 0.08 * smoothstep(400.0, 80.0, d_c)   # slight dip of glade floor
			_h[_idx(ix, iy)] = h


func _apply_path_features() -> void:
	if PathNetwork == null:
		return
	for f in PathNetwork.features:
		var kind: String = str(f.get("kind", ""))
		var c: Vector2 = f.get("pos", Vector2.ZERO)
		var r: float = float(f.get("radius", 100.0))
		var peak: float = float(f.get("elev", 0.0))
		var stretch: Vector2 = f.get("stretch", Vector2.ONE) as Vector2
		var ang: float = float(f.get("angle", 0.0))
		var ca := cos(ang)
		var sa := sin(ang)
		var r_cells := int(ceili(r * 2.6 / CELL))
		var cc := _world_to_cell(c)
		for dy in range(-r_cells, r_cells + 1):
			for dx in range(-r_cells, r_cells + 1):
				var ix := cc.x + dx
				var iy := cc.y + dy
				if not _in_bounds(ix, iy):
					continue
				var p := cell_world_center(ix, iy)
				var local := p - c
				var lx := local.x * ca + local.y * sa
				var ly := -local.x * sa + local.y * ca
				var d := Vector2(lx / maxf(0.5, stretch.x), ly / maxf(0.5, stretch.y)).length()
				var fall := r * 2.35
				if d >= fall:
					continue
				var t := 1.0 - d / fall
				t = t * t * (3.0 - 2.0 * t)
				var i := _idx(ix, iy)
				if kind in ["mountain", "hill"] or peak > 0.0:
					var amp := peak if peak != 0.0 else (1.0 if kind == "mountain" else 0.5)
					# Ridges: sharper peaks for mountains
					if kind == "mountain":
						_h[i] += amp * t * t * (0.85 + 0.4 * t)
					else:
						_h[i] += amp * t * 0.85
				elif kind in ["lake", "pond"] or peak < 0.0:
					var amp2 := peak if peak != 0.0 else (-0.65 if kind == "lake" else -0.35)
					_h[i] += amp2 * t
					# Multi-lobe deepen
					var lobes: Array = f.get("lobes", [])
					for lobe in lobes:
						var o: Vector2 = lobe.get("o", Vector2.ZERO)
						var lrx: float = float(lobe.get("rx", 1.0)) * r
						var lry: float = float(lobe.get("ry", 0.6)) * r
						var ld := p - (c + o)
						var ln := Vector2(ld.x / maxf(8.0, lrx), ld.y / maxf(8.0, lry)).length()
						if ln < 1.0:
							var lt := 1.0 - ln
							_h[i] -= 0.25 * lt * lt
							_m[i] = maxf(_m[i], 0.7 + 0.3 * lt)


func _smooth_height(passes: int) -> void:
	for _p in passes:
		var next := _h.duplicate()
		for iy in range(1, ROWS - 1):
			for ix in range(1, COLS - 1):
				var s := 0.0
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						s += _h[_idx(ix + ox, iy + oy)]
				next[_idx(ix, iy)] = lerpf(_h[_idx(ix, iy)], s / 9.0, 0.45)
		_h = next


func _carve_road_benches() -> void:
	## Slightly flatten / terrace near roads so dirt path sits in the land naturally.
	if PathNetwork == null or PathNetwork.lanes.is_empty():
		return
	for iy in ROWS:
		for ix in COLS:
			var p := cell_world_center(ix, iy)
			var d := PathNetwork.dist_to_path(p)
			if d > 140.0:
				continue
			var i := _idx(ix, iy)
			var near := PathNetwork.nearest_on_network(p)
			var e_path := elev_at(near)  # uses current field
			var blend := 1.0 - clampf(d / 140.0, 0.0, 1.0)
			blend *= blend
			_h[i] = lerpf(_h[i], e_path * 0.85 + _h[i] * 0.15, blend * 0.55)
			# Soft moisture dip on road
			_m[i] *= 1.0 - blend * 0.25


func _compute_moisture() -> void:
	for iy in ROWS:
		for ix in COLS:
			var i := _idx(ix, iy)
			var e := _h[i]
			# Low = wetter, high = drier
			var m := clampf(0.55 - e * 0.35, 0.05, 0.95)
			m += 0.12 * _n2(cell_world_center(ix, iy) * 0.006 + Vector2(9.0, 2.0))
			_m[i] = clampf(maxf(_m[i], m), 0.0, 1.0)


func _classify_basins() -> void:
	## Lakes where features demand or natural deep local minima.
	if PathNetwork:
		for f in PathNetwork.features:
			var kind: String = str(f.get("kind", ""))
			if kind not in ["lake", "pond"]:
				continue
			var c: Vector2 = f.get("pos", Vector2.ZERO)
			var r: float = float(f.get("radius", 100.0))
			var code := W_LAKE if kind == "lake" else W_POND
			var lobes: Array = f.get("lobes", [])
			var cc := _world_to_cell(c)
			var rc := int(ceili(r * 1.4 / CELL))
			for dy in range(-rc, rc + 1):
				for dx in range(-rc, rc + 1):
					var ix := cc.x + dx
					var iy := cc.y + dy
					if not _in_bounds(ix, iy):
						continue
					var p := cell_world_center(ix, iy)
					var inside := false
					if lobes.is_empty():
						var ell := Vector2((p.x - c.x) / (r * 0.95), (p.y - c.y) / (r * 0.62))
						inside = ell.length_squared() < 1.0
					else:
						for lobe in lobes:
							var o: Vector2 = lobe.get("o", Vector2.ZERO)
							var lrx: float = float(lobe.get("rx", 1.0)) * r * 0.9
							var lry: float = float(lobe.get("ry", 0.6)) * r * 0.9
							var ld := p - (c + o)
							if Vector2(ld.x / maxf(8.0, lrx), ld.y / maxf(8.0, lry)).length_squared() < 1.0:
								inside = true
								break
					if inside:
						_w[_idx(ix, iy)] = code
						_h[_idx(ix, iy)] = minf(_h[_idx(ix, iy)], -0.35 if code == W_LAKE else -0.2)
						_m[_idx(ix, iy)] = maxf(_m[_idx(ix, iy)], 0.85)

	# Natural pondlets: deep local minima away from path
	for iy in range(2, ROWS - 2):
		for ix in range(2, COLS - 2):
			var i := _idx(ix, iy)
			if _w[i] != W_NONE:
				continue
			var e := _h[i]
			if e > -0.15:
				continue
			var is_min := true
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					if ox == 0 and oy == 0:
						continue
					if _h[_idx(ix + ox, iy + oy)] < e - 0.01:
						is_min = false
						break
				if not is_min:
					break
			if not is_min:
				continue
			var p := cell_world_center(ix, iy)
			if PathNetwork and PathNetwork.dist_to_path(p) < 130.0:
				continue
			if p.distance_to(PathNetwork.CRYSTAL if PathNetwork else Vector2.ZERO) < 280.0:
				continue
			# Fill small basin
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var j := _idx(ix + ox, iy + oy)
					if _h[j] < e + 0.12:
						_w[j] = W_POND
						_m[j] = maxf(_m[j], 0.8)


func _compute_flow() -> void:
	var dirs := [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
	]
	for iy in ROWS:
		for ix in COLS:
			var i := _idx(ix, iy)
			if _w[i] >= W_POND:
				_flow[i] = -1
				continue
			var best := -1
			var best_e := _h[i]
			for d in dirs:
				var nx: int = ix + d.x
				var ny: int = iy + d.y
				if not _in_bounds(nx, ny):
					continue
				var j := _idx(nx, ny)
				var e := _h[j]
				# Prefer cardinal slightly
				if abs(d.x) + abs(d.y) == 2:
					e += 0.008
				if e < best_e:
					best_e = e
					best = j
			_flow[i] = best


func _accumulate_flow() -> void:
	_accum.fill(1.0)
	# Multiple passes to propagate uphill→downhill accumulation
	for _pass in 8:
		for iy in ROWS:
			for ix in COLS:
				var i := _idx(ix, iy)
				var f := _flow[i]
				if f < 0:
					continue
				_accum[f] += _accum[i] * 0.35
	# Normalize-ish
	var mx := 1.0
	for v in _accum:
		mx = maxf(mx, v)
	for i in _accum.size():
		_accum[i] /= mx


func _trace_streams() -> void:
	## Follow high-accumulation cells downhill into lakes; skip roads.
	var threshold := 0.12
	var visited := PackedByteArray()
	visited.resize(COLS * ROWS)
	visited.fill(0)
	var starts: Array = []
	for iy in range(1, ROWS - 1):
		for ix in range(1, COLS - 1):
			var i := _idx(ix, iy)
			if _w[i] != W_NONE:
				continue
			if _accum[i] < threshold:
				continue
			if _h[i] < -0.05:
				continue
			starts.append(i)
	starts.sort_custom(func(a, b): return _accum[a] > _accum[b])
	var stream_budget := 28
	for si in mini(starts.size(), 80):
		if stream_paths.size() >= stream_budget:
			break
		var i: int = starts[si]
		if visited[i]:
			continue
		var path: PackedVector2Array = PackedVector2Array()
		var guard := 0
		var hit_water := false
		while i >= 0 and guard < 80:
			guard += 1
			if visited[i]:
				break
			visited[i] = 1
			var ix := i % COLS
			var iy := i / COLS
			var p := cell_world_center(ix, iy)
			if PathNetwork and PathNetwork.dist_to_path(p) < 95.0:
				break  # don't cut through road
			if p.distance_to(PathNetwork.CRYSTAL if PathNetwork else Vector2.ZERO) < 200.0:
				break
			path.append(p)
			if _w[i] >= W_POND:
				hit_water = true
				break
			if _w[i] == W_NONE and _accum[i] > threshold * 0.6:
				_w[i] = W_STREAM
				_m[i] = maxf(_m[i], 0.75)
			var nxt := _flow[i]
			if nxt < 0 or nxt == i:
				break
			# Steep drop → mark waterfall later
			i = nxt
		if path.size() >= 4 and (hit_water or path.size() >= 8):
			stream_paths.append(path)


func _mark_waterfalls() -> void:
	waterfalls.clear()
	for path in stream_paths:
		var pts: PackedVector2Array = path
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			var ea := elev_at(a)
			var eb := elev_at(b)
			var drop := ea - eb
			if drop > 0.12:
				waterfalls.append({
					"from": a,
					"to": b,
					"strength": clampf(drop, 0.12, 0.8),
				})
				var c := _world_to_cell(a.lerp(b, 0.5))
				if _in_bounds(c.x, c.y):
					_w[_idx(c.x, c.y)] = W_FALL


func _scatter_sites() -> void:
	rock_sites.clear()
	tree_sites.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4096
	for iy in range(1, ROWS - 1, 1):
		for ix in range(1, COLS - 1, 1):
			var i := _idx(ix, iy)
			if _w[i] != W_NONE:
				continue
			var p := cell_world_center(ix, iy)
			if PathNetwork and PathNetwork.dist_to_path(p) < 115.0:
				continue
			if p.distance_to(PathNetwork.CRYSTAL if PathNetwork else Vector2.ZERO) < 240.0:
				continue
			var e := _h[i]
			var sl := slope_at(p)
			var m := _m[i]
			# Rocks on steep high ground — integrated with ridge
			if e > 0.25 and sl > 0.006 and rng.randf() < 0.14 + e * 0.12:
				rock_sites.append({"pos": p + Vector2(rng.randf_range(-12, 12), rng.randf_range(-10, 10)), "elev": e, "slope": sl})
			# Forest on mid elevation, low-mid slope, not too wet
			var forest := 0.0
			if e > -0.05 and e < 0.75 and sl < 0.014:
				forest = (1.0 - absf(e - 0.25) * 1.2) * (1.0 - sl * 40.0) * (0.6 + m * 0.4)
			if forest > 0.35 and rng.randf() < forest * 0.22:
				var sc := 1.9 + e * 0.9 + rng.randf() * 0.5
				tree_sites.append({"pos": p + Vector2(rng.randf_range(-16, 16), rng.randf_range(-14, 14)), "elev": e, "scale": sc})


# ── sampling helpers ─────────────────────────────────────────────────────────

func _world_to_cell(p: Vector2) -> Vector2i:
	var lx := (p.x - ORIGIN.x) / CELL
	var ly := (p.y - ORIGIN.y) / CELL
	return Vector2i(int(floor(lx)), int(floor(ly)))


func _in_bounds(ix: int, iy: int) -> bool:
	return ix >= 0 and iy >= 0 and ix < COLS and iy < ROWS


func _idx(ix: int, iy: int) -> int:
	return iy * COLS + ix


func _sample_bilinear(field: PackedFloat32Array, world_pos: Vector2) -> float:
	var lx := (world_pos.x - ORIGIN.x) / CELL - 0.5
	var ly := (world_pos.y - ORIGIN.y) / CELL - 0.5
	var x0 := int(floor(lx))
	var y0 := int(floor(ly))
	var tx := lx - float(x0)
	var ty := ly - float(y0)
	var x1 := x0 + 1
	var y1 := y0 + 1
	var v00 := _sample_cell(field, x0, y0)
	var v10 := _sample_cell(field, x1, y0)
	var v01 := _sample_cell(field, x0, y1)
	var v11 := _sample_cell(field, x1, y1)
	var a := lerpf(v00, v10, tx)
	var b := lerpf(v01, v11, tx)
	return lerpf(a, b, ty)


func _sample_cell(field: PackedFloat32Array, ix: int, iy: int) -> float:
	ix = clampi(ix, 0, COLS - 1)
	iy = clampi(iy, 0, ROWS - 1)
	return field[_idx(ix, iy)]


func _n2(p: Vector2) -> float:
	## Value noise-ish in -1..1
	var i := Vector2(floor(p.x), floor(p.y))
	var f := p - i
	f = f * f * (Vector2(3, 3) - 2.0 * f)
	var a := _hash2(i)
	var b := _hash2(i + Vector2(1, 0))
	var c := _hash2(i + Vector2(0, 1))
	var d := _hash2(i + Vector2(1, 1))
	var u := lerpf(a, b, f.x)
	var v := lerpf(c, d, f.x)
	return lerpf(u, v, f.y) * 2.0 - 1.0


func _hash2(p: Vector2) -> float:
	var n := sin(p.dot(Vector2(127.1, 311.7))) * 43758.5453
	return n - floor(n)
