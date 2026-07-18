extends Node2D
class_name DefenseTower
## Starter towers: Garrison (path blockers), Aetherbow (dual DPS → phys/magic),
## Groundspike (slow ground → AOE).

const GarrisonUnitScript = preload("res://scripts/garrison_unit.gd")

var type_id: String = "dualshot"
var level: int = 1
var invested_essence: int = 0
var fire_range: float = 340.0
var fire_rate: float = 0.48
var damage: int = 11
var role: String = "dps"
var channel: String = "light"
## "ground" | "air" | "both"
var target_layer: String = "both"
var aura_slow: float = 0.0
var splash: float = 0.0
var special: String = ""
var root_duration: float = 0.0
var chain_count: int = 1
var chain_falloff: float = 0.7
## Aetherbow L2+ branch: "" | "physical" | "magical"
var dps_branch: String = ""
var soldier_count: int = 2
var soldier_hp: int = 48
var soldier_damage: int = 9
var soldier_range: float = 52.0
var respawn_time: float = 5.0
var rally_dist: float = 70.0

var _cd: float = 0.0
var _visual: Node2D
var _body: Polygon2D
var _accent: Polygon2D
var _range_ring: Polygon2D
var _level_label: Label
var _name_label: Label
var _bob: float = 0.0
var show_range: bool = false
var _def_color: Color = Color(0.4, 0.7, 0.4)
var _configured: bool = false
var _soldiers: Array[Node2D] = []
var _respawn_timers: Array[float] = []
var _rally: Vector2 = Vector2.ZERO
var _builder_index: int = 0


func _ready() -> void:
	add_to_group("towers")
	z_as_relative = false
	_refresh_z()
	for n in ["RangeHint", "Body", "CrystalTip"]:
		if has_node(n):
			get_node(n).visible = false
	if not _configured:
		_apply_def(TowerTypes.def_for(type_id))
		_build_visuals()
	_bob = randf() * TAU
	set_range_visible(false)
	if role == "garrison":
		call_deferred("_init_garrison")


func _refresh_z() -> void:
	if VisualStyle:
		z_index = VisualStyle.actor_z(global_position.y)
	else:
		z_index = clampi(50 + int(global_position.y) + 2000, 50, 4000)


func configure(id: String, invested: int = 0) -> void:
	type_id = id
	if invested > 0:
		invested_essence = invested
	_apply_def(TowerTypes.def_for(type_id))
	if is_inside_tree():
		_clear_visuals()
		_build_visuals()
		_configured = true
		if role == "garrison":
			call_deferred("_init_garrison")
	else:
		_configured = false


func set_builder_index(i: int) -> void:
	_builder_index = i


func _clear_visuals() -> void:
	_clear_soldiers()
	for c in get_children():
		remove_child(c)
		c.free()
	_visual = null
	_body = null
	_accent = null
	_range_ring = null
	_level_label = null
	_name_label = null


func _apply_def(d: Dictionary) -> void:
	damage = int(d.get("damage", 15))
	fire_rate = float(d.get("fire_rate", 0.5))
	fire_range = float(d.get("range", 170.0))
	role = str(d.get("role", "dps"))
	channel = str(d.get("channel", "thorn"))
	target_layer = str(d.get("target", "both"))
	aura_slow = float(d.get("aura_slow", 0.0))
	splash = float(d.get("splash", 0.0))
	special = str(d.get("special", ""))
	root_duration = float(d.get("root_duration", 0.0))
	chain_count = int(d.get("chain_count", 1))
	chain_falloff = float(d.get("chain_falloff", 0.7))
	soldier_count = int(d.get("soldier_count", 2))
	soldier_hp = int(d.get("soldier_hp", 48))
	soldier_damage = int(d.get("soldier_damage", 9))
	soldier_range = float(d.get("soldier_range", 52.0))
	respawn_time = float(d.get("respawn", 5.0))
	rally_dist = float(d.get("rally_dist", 70.0))
	_def_color = d.get("color", Color(0.5, 0.7, 0.5)) as Color

	# Level scaling
	damage = int(damage * (1.0 + (level - 1) * 0.45))
	fire_rate = maxf(0.22, fire_rate * (1.0 - (level - 1) * 0.12))
	fire_range = fire_range + (level - 1) * 22.0
	soldier_count = soldier_count + (level - 1)
	soldier_hp = int(soldier_hp * (1.0 + (level - 1) * 0.4))
	soldier_damage = int(soldier_damage * (1.0 + (level - 1) * 0.35))
	respawn_time = maxf(2.5, respawn_time - (level - 1) * 0.6)

	# Aetherbow branch specialization (L2+)
	if type_id == "dualshot" and dps_branch != "":
		if dps_branch == TowerTypes.BRANCH_PHYSICAL:
			channel = "thorn"
			special = "multishot"
			damage = int(float(damage) * 1.2)
			_def_color = Color(0.45, 0.82, 0.42)
		elif dps_branch == TowerTypes.BRANCH_MAGICAL:
			channel = "light"
			special = "magic_bolt"
			splash = 55.0 + (level - 1) * 15.0
			damage = int(float(damage) * 1.05)
			_def_color = Color(0.72, 0.48, 0.95)

	# Groundspike: upgrade → AOE
	if type_id == "groundspike" and level >= 2:
		special = "splash"
		splash = 85.0 + (level - 2) * 30.0
		role = "aoe"


func set_invested(amount: int) -> void:
	invested_essence = amount


func sell_value() -> int:
	return int(float(invested_essence) * GameState.TOWER_SELL_REFUND)


func set_range_visible(v: bool) -> void:
	show_range = v
	if _range_ring:
		_range_ring.visible = v


func set_info_visible(v: bool) -> void:
	if _name_label:
		_name_label.visible = v
	if _level_label:
		_level_label.visible = v


func try_upgrade() -> bool:
	if level >= GameState.TOWER_MAX_LEVEL:
		GameState.message.emit("Max level")
		return false
	if not GameState.try_spend_essence(GameState.TOWER_UPGRADE_COST):
		return false
	# Aetherbow L1 → L2 locks branch from player preference
	if type_id == "dualshot" and level == 1 and dps_branch == "":
		if TowerTypes:
			dps_branch = TowerTypes.selected_branch_for(_builder_index)
		else:
			dps_branch = "physical"
	level += 1
	invested_essence += GameState.TOWER_UPGRADE_COST
	_apply_def(TowerTypes.def_for(type_id))
	var keep_range := show_range
	var keep_info := _name_label != null and _name_label.visible
	_clear_visuals()
	_build_visuals()
	set_range_visible(keep_range)
	set_info_visible(keep_info)
	if role == "garrison":
		call_deferred("_init_garrison")
	var name_s := str(TowerTypes.def_for(type_id).get("name"))
	if type_id == "dualshot" and dps_branch != "":
		name_s += " (%s)" % TowerTypes.branch_label(dps_branch)
	GameState.message.emit("%s → Lv%d" % [name_s, level])
	if Sfx:
		Sfx.build()
	if FX:
		FX.burst_particles(self, global_position + Vector2(0, -30), _def_color, 16 + level * 6, "star", 0.5)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -40), "Lv%d" % level, _def_color)
	return true


func preview_branch_label() -> String:
	if type_id != "dualshot":
		return ""
	if dps_branch != "":
		return TowerTypes.branch_label(dps_branch) if TowerTypes else dps_branch
	if TowerTypes:
		return TowerTypes.branch_label(TowerTypes.selected_branch_for(_builder_index))
	return "PHYS"


func _level_scale() -> float:
	match level:
		1:
			return 1.0
		2:
			return 1.28
		_:
			return 1.58


func _rebuild_range_ring() -> void:
	if _visual == null:
		return
	if _range_ring and is_instance_valid(_range_ring):
		_range_ring.queue_free()
		_range_ring = null
	var col := Color(_def_color.r, _def_color.g, _def_color.b, 0.16)
	_range_ring = FX.make_ellipse_poly(fire_range, fire_range * 0.72, 56, col)
	_range_ring.z_index = -2
	_range_ring.visible = show_range
	_visual.add_child(_range_ring)


func _build_visuals() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	if VisualStyle:
		VisualStyle.make_blob_shadow(_visual, 24, 10, 14)
	else:
		FX.add_soft_shadow(_visual, 24, 10, 14)

	_rebuild_range_ring()

	match type_id:
		"garrison":
			_build_garrison()
		"groundspike":
			_build_groundspike()
		_:
			_build_dualshot()

	var tag := Label.new()
	tag.text = str(TowerTypes.def_for(type_id).get("target_label", "ALL"))
	tag.position = Vector2(-14, -82)
	tag.add_theme_font_size_override("font_size", 9)
	tag.add_theme_color_override("font_color", _layer_tag_color())
	tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	tag.add_theme_constant_override("outline_size", 2)
	tag.visible = false
	tag.name = "LayerTag"
	_visual.add_child(tag)

	_name_label = Label.new()
	var short_n := str(TowerTypes.def_for(type_id).get("short", "?"))
	if type_id == "dualshot" and dps_branch != "" and TowerTypes:
		short_n = TowerTypes.branch_label(dps_branch)
	_name_label.text = short_n
	_name_label.position = Vector2(-20, -70)
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.add_theme_color_override("font_color", _def_color.lightened(0.3))
	_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_name_label.add_theme_constant_override("outline_size", 3)
	_name_label.visible = false
	_visual.add_child(_name_label)

	_level_label = Label.new()
	_level_label.text = "Lv%d" % level
	_level_label.position = Vector2(-14, 16)
	_level_label.add_theme_font_size_override("font_size", 11 + mini(level - 1, 2) * 2)
	_level_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	_level_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_level_label.add_theme_constant_override("outline_size", 3)
	_level_label.visible = false
	_visual.add_child(_level_label)

	_visual.scale = Vector2.ONE * _level_scale()
	_add_level_ornaments()


func _layer_tag_color() -> Color:
	match target_layer:
		"air":
			return Color(0.65, 0.9, 1.0)
		"ground":
			return Color(0.55, 0.9, 0.5)
		_:
			return Color(0.95, 0.9, 0.55)


func _add_level_ornaments() -> void:
	if _visual == null or level < 2:
		return
	var plinth := FX.make_ellipse_poly(22.0 + level * 4.0, 12.0 + level * 2.0, 24, Color(0.2, 0.18, 0.22, 0.55))
	plinth.position = Vector2(0, 10)
	plinth.z_index = -1
	_visual.add_child(plinth)
	if level >= 3:
		var crown := Polygon2D.new()
		crown.polygon = PackedVector2Array([
			Vector2(0, -78), Vector2(10, -58), Vector2(4, -52), Vector2(0, -62),
			Vector2(-4, -52), Vector2(-10, -58)
		])
		crown.color = Color(0.95, 0.85, 0.5, 0.95)
		_visual.add_child(crown)


func _add_plinth(rx: float = 20.0, ry: float = 11.0) -> void:
	var outer := FX.make_ellipse_poly(rx + 4, ry + 2, 24, Color(0.12, 0.1, 0.14, 0.9))
	outer.position = Vector2(0, 10)
	_visual.add_child(outer)
	var base := FX.make_ellipse_poly(rx, ry, 22, Color(0.26, 0.22, 0.28, 0.95))
	base.position = Vector2(0, 8)
	_visual.add_child(base)
	var glow := FX.make_ellipse_poly(rx * 0.55, ry * 0.5, 16, Color(_def_color.r, _def_color.g, _def_color.b, 0.25))
	glow.position = Vector2(0, 6)
	_visual.add_child(glow)


## Garrison — wooden barracks / banner pole.
func _build_garrison() -> void:
	_add_plinth(24.0 + level * 2, 13.0)
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-18, 6), Vector2(18, 6), Vector2(16, -8), Vector2(12, -28),
		Vector2(-12, -28), Vector2(-16, -8)
	])
	_body.color = Color(0.48, 0.36, 0.26)
	_visual.add_child(_body)
	# Roof
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([
		Vector2(-16, -28), Vector2(0, -48 - level * 4), Vector2(16, -28)
	])
	roof.color = Color(0.65, 0.42, 0.28)
	_visual.add_child(roof)
	# Banner
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([
		Vector2(10, -40), Vector2(28, -36), Vector2(26, -22), Vector2(10, -26)
	])
	_accent.color = Color(0.85, 0.55, 0.3)
	_visual.add_child(_accent)
	var pole := Polygon2D.new()
	pole.polygon = PackedVector2Array([
		Vector2(8, 4), Vector2(12, 4), Vector2(11, -44), Vector2(9, -44)
	])
	pole.color = Color(0.35, 0.28, 0.2)
	_visual.add_child(pole)
	# Door
	var door := Polygon2D.new()
	door.polygon = PackedVector2Array([
		Vector2(-5, 6), Vector2(5, 6), Vector2(5, -10), Vector2(-5, -10)
	])
	door.color = Color(0.28, 0.2, 0.14)
	_visual.add_child(door)


## Dualshot / Aetherbow — crystal bow that hits all layers.
func _build_dualshot() -> void:
	_add_plinth(16.0, 9.0)
	var h := 58.0 + (level - 1) * 12.0
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-5, 8), Vector2(5, 8), Vector2(3, -h * 0.85), Vector2(-3, -h * 0.85)
	])
	_body.color = Color(0.4, 0.45, 0.55)
	_visual.add_child(_body)
	var bow_w := 24.0 + level * 5.0
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([
		Vector2(-bow_w, -h * 0.55), Vector2(-bow_w * 0.4, -h * 0.95), Vector2(0, -h - 6),
		Vector2(bow_w * 0.4, -h * 0.95), Vector2(bow_w, -h * 0.55),
		Vector2(bow_w * 0.55, -h * 0.5), Vector2(0, -h * 0.72), Vector2(-bow_w * 0.55, -h * 0.5)
	])
	_accent.color = _def_color
	_visual.add_child(_accent)
	var bolt := Polygon2D.new()
	bolt.polygon = PackedVector2Array([
		Vector2(0, -h - 16 - level * 2), Vector2(3, -h * 0.55), Vector2(0, -h * 0.5), Vector2(-3, -h * 0.55)
	])
	bolt.color = Color(0.9, 0.85, 1.0) if dps_branch == "magical" else Color(0.75, 0.95, 0.7) if dps_branch == "physical" else Color(0.85, 0.92, 1.0)
	_visual.add_child(bolt)
	# Wing marks for dual (air+ground)
	for sx in [-1.0, 1.0]:
		var wing := Polygon2D.new()
		wing.polygon = PackedVector2Array([
			Vector2(0, -h * 0.35), Vector2(sx * 18, -h * 0.5), Vector2(sx * 6, -h * 0.28)
		])
		wing.color = Color(_def_color.r, _def_color.g, _def_color.b, 0.4)
		_visual.add_child(wing)


## Groundspike — heavy thorn mortar; L2+ shows splash rings.
func _build_groundspike() -> void:
	_add_plinth(22.0 + level * 2, 12.0)
	var h := 50.0 + (level - 1) * 10.0
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(0, -h), Vector2(16, -h * 0.55), Vector2(12, 8), Vector2(-12, 8), Vector2(-16, -h * 0.55)
	])
	_body.color = _def_color
	_visual.add_child(_body)
	# Heavy tip
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([
		Vector2(0, -h - 8), Vector2(8, -h * 0.85), Vector2(0, -h * 0.72), Vector2(-8, -h * 0.85)
	])
	_accent.color = Color(0.95, 0.85, 0.4)
	_visual.add_child(_accent)
	if level >= 2 or splash > 0.0:
		for i in (1 + mini(level, 2)):
			var ring := FX.make_ellipse_poly(24 + i * 14, 14 + i * 7, 22, Color(0.4, 0.75, 0.35, 0.14 - i * 0.03))
			ring.position = Vector2(0, 2)
			ring.z_index = -1
			_visual.add_child(ring)
	# Side thorns
	for sx in [-1.0, 1.0]:
		var thorn := Polygon2D.new()
		thorn.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(sx * 14, -6), Vector2(sx * 4, -2)
		])
		thorn.position = Vector2(sx * 10, -h * 0.4)
		thorn.color = _def_color.darkened(0.15)
		_visual.add_child(thorn)


# ── Garrison soldiers ─────────────────────────────────────────────────────────

func _init_garrison() -> void:
	if role != "garrison":
		return
	_compute_rally()
	_clear_soldiers()
	_soldiers.clear()
	_respawn_timers.clear()
	for i in soldier_count:
		_spawn_soldier(i)
		_respawn_timers.append(0.0)


func _compute_rally() -> void:
	_rally = global_position + Vector2(0, rally_dist)
	if PathNetwork:
		var best := global_position
		var best_d := INF
		for lane in PathNetwork.lanes:
			if lane is PackedVector2Array and (lane as PackedVector2Array).size() >= 2:
				var pts: PackedVector2Array = lane
				var length := PathNetwork.lane_length(pts)
				var d := 0.0
				while d < length:
					var sample: Dictionary = PathNetwork.sample_lane(pts, d)
					var p: Vector2 = sample.get("pos", Vector2.ZERO)
					var dist := p.distance_squared_to(global_position)
					if dist < best_d:
						best_d = dist
						best = p
					d += 40.0
		_rally = best


func _spawn_soldier(slot: int) -> void:
	var unit: Node2D = GarrisonUnitScript.new() as Node2D
	# Parent under World so soldiers live on the road, not under the pad slot
	var host: Node = _world_host()
	var offset := Vector2(float(slot - 1) * 18.0, float(slot % 2) * 8.0)
	host.add_child(unit)
	unit.global_position = global_position + Vector2(0, -8)
	if unit.has_method("configure"):
		unit.call("configure", soldier_hp, soldier_damage, soldier_range, self, _rally + offset)
	while _soldiers.size() <= slot:
		_soldiers.append(null)
	_soldiers[slot] = unit


func _world_host() -> Node:
	var n: Node = self
	while n:
		if str(n.name) == "World":
			return n
		n = n.get_parent()
	var p := get_parent()
	return p if p else self


func on_soldier_died(unit: Node) -> void:
	for i in _soldiers.size():
		if _soldiers[i] == unit:
			_soldiers[i] = null
			while _respawn_timers.size() <= i:
				_respawn_timers.append(0.0)
			_respawn_timers[i] = respawn_time
			break


func _clear_soldiers() -> void:
	for s in _soldiers:
		if s and is_instance_valid(s):
			s.queue_free()
	_soldiers.clear()
	_respawn_timers.clear()


func _exit_tree() -> void:
	_clear_soldiers()


func _process(delta: float) -> void:
	if GameState != null and GameState.is_game_over:
		return
	_bob += delta
	if _visual:
		_visual.position.y = sin(_bob * 1.8) * 1.4
	if _accent and role != "garrison":
		_accent.modulate.a = 0.7 + 0.3 * sin(_bob * 3.0)
	var tag := _visual.get_node_or_null("LayerTag") if _visual else null
	if tag is CanvasItem and _name_label:
		(tag as CanvasItem).visible = _name_label.visible

	# Garrison: respawn soldiers, no projectile fire
	if role == "garrison":
		_tick_garrison(delta)
		return

	_cd = maxf(0.0, _cd - delta)
	if _cd > 0.0:
		return

	var target := _find_target()
	if target == null or not is_instance_valid(target):
		return

	_cd = maxf(0.12, fire_rate)
	_fire_at(target)


func _tick_garrison(delta: float) -> void:
	for i in _respawn_timers.size():
		if _respawn_timers[i] > 0.0:
			_respawn_timers[i] = maxf(0.0, _respawn_timers[i] - delta)
			if _respawn_timers[i] <= 0.0:
				if i >= _soldiers.size() or _soldiers[i] == null or not is_instance_valid(_soldiers[i]):
					_spawn_soldier(i)


func _enemy_is_flying(e: Node) -> bool:
	if e == null or not is_instance_valid(e):
		return false
	if e.get("is_flying") != null:
		return bool(e.get("is_flying"))
	if e.has_method("is_air"):
		return bool(e.call("is_air"))
	return false


func _can_target(e: Node) -> bool:
	if e == null or not is_instance_valid(e):
		return false
	var flying := _enemy_is_flying(e)
	match target_layer:
		"ground":
			return not flying
		"air":
			return flying
		_:
			return true


func _fire_at(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	var host: Node = get_parent()
	if host == null:
		host = self

	match special:
		"multishot":
			_fire_multishot(host)
		"magic_bolt":
			_fire_magic(target, host)
		"splash":
			_fire_splash(target, host)
		_:
			# dual_bolt / single
			_fx_bolt(target.global_position, channel == "light")
			_hit_one(target, damage, host)


func _hit_one(target: Node2D, dmg: int, host: Node) -> void:
	if target == null or not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	if not _can_target(target):
		return
	var txt_col := _def_color
	var shown := dmg
	if target.has_method("damage_mult_from_tower"):
		var m: float = float(target.call("damage_mult_from_tower", channel, special, role))
		shown = maxi(1, int(float(dmg) * m))
		if target.has_method("is_marked") and bool(target.call("is_marked")):
			var mm = target.get("_mark_mult")
			if mm != null:
				shown = int(float(shown) * float(mm))
		if m >= 1.35:
			txt_col = Color(1.0, 0.95, 0.35)
		elif m <= 0.65:
			txt_col = Color(0.55, 0.65, 0.95)
		target.call("take_damage", dmg, channel, special, role)
	else:
		target.call("take_damage", shown)
	FloatingText.spawn(host, target.global_position + Vector2(0, -16), str(maxi(1, shown)), txt_col)


func _fire_splash(target: Node2D, host: Node) -> void:
	var impact := target.global_position
	_fx_heavy_lob(impact, func():
		if not is_inside_tree():
			return
		var tree := get_tree()
		if tree == null:
			return
		var r := maxf(splash, 70.0)
		for e in tree.get_nodes_in_group("enemies"):
			if not (e is Node2D) or not is_instance_valid(e) or not _can_target(e):
				continue
			if impact.distance_to(e.global_position) <= r:
				var mult := 1.0 if (is_instance_valid(target) and e == target) else 0.55
				_hit_one(e, int(float(damage) * mult), host)
		_fx_ground_nova(impact, r)
	)


func _fire_multishot(host: Node) -> void:
	var targets := _enemies_in_range_sorted(2 + level)
	if targets.is_empty():
		return
	var i := 0
	for t in targets:
		var delay := float(i) * 0.04
		var tgt: Node2D = t
		var dmg := damage
		get_tree().create_timer(delay).timeout.connect(func():
			if not is_instance_valid(tgt) or not is_inside_tree():
				return
			_fx_bolt(tgt.global_position, false)
			_hit_one(tgt, dmg, host)
		)
		i += 1


func _fire_magic(target: Node2D, host: Node) -> void:
	var impact := target.global_position
	_fx_bolt(impact, true)
	_hit_one(target, damage, host)
	if splash > 0.0:
		var tree := get_tree()
		if tree:
			var r := splash
			for e in tree.get_nodes_in_group("enemies"):
				if not (e is Node2D) or not is_instance_valid(e) or e == target or not _can_target(e):
					continue
				if impact.distance_to(e.global_position) <= r:
					_hit_one(e, int(float(damage) * 0.45), host)
		if FX:
			FX.burst_particles(self, impact, Color(0.72, 0.48, 0.95), 10, "magic", 0.3)


func _enemies_in_range_sorted(limit: int) -> Array[Node2D]:
	var out: Array[Node2D] = []
	var tree := get_tree()
	if tree == null:
		return out
	var scored: Array = []
	var r2 := fire_range * fire_range
	for e in tree.get_nodes_in_group("enemies"):
		if not (e is Node2D) or not is_instance_valid(e) or not _can_target(e):
			continue
		var d2: float = global_position.distance_squared_to(e.global_position)
		if d2 <= r2:
			scored.append({"e": e, "d": d2})
	scored.sort_custom(func(a, b): return a.d < b.d)
	for i in mini(limit, scored.size()):
		out.append(scored[i].e)
	return out


func _find_target() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var crystal_pos := PathNetwork.CRYSTAL if PathNetwork else Vector2.ZERO
	var best: Node2D = null
	var best_score := -1.0
	var r2 := fire_range * fire_range
	for e in tree.get_nodes_in_group("enemies"):
		if not (e is Node2D) or not is_instance_valid(e) or not _can_target(e):
			continue
		var d2: float = global_position.distance_squared_to(e.global_position)
		if d2 > r2:
			continue
		var to_crystal: float = e.global_position.distance_to(crystal_pos)
		var score := 10000.0 / maxf(40.0, to_crystal) + 200.0 / maxf(20.0, sqrt(d2))
		if role == "aoe" and splash > 0.0:
			var near := 0
			for o in tree.get_nodes_in_group("enemies"):
				if o is Node2D and o != e and _can_target(o):
					if e.global_position.distance_to(o.global_position) <= splash:
						near += 1
			score += float(near) * 80.0
		if score > best_score:
			best_score = score
			best = e
	return best


# ── Attack VFX ────────────────────────────────────────────────────────────────

func _muzzle_origin() -> Vector2:
	return Vector2(0, -36)


func _fx_bolt(world_to: Vector2, magical: bool) -> void:
	var origin := _muzzle_origin()
	var dest := world_to - global_position + Vector2(0, -8)
	var bolt := Polygon2D.new()
	bolt.polygon = PackedVector2Array([
		Vector2(0, -8), Vector2(3, 2), Vector2(0, 5), Vector2(-3, 2)
	])
	bolt.color = Color(0.75, 0.5, 1.0, 0.95) if magical else Color(0.5, 0.9, 0.55, 0.95)
	bolt.position = origin
	bolt.z_index = 25
	bolt.rotation = (dest - origin).angle() + PI * 0.5
	add_child(bolt)
	var dist := origin.distance_to(dest)
	var dur := clampf(dist / 1100.0, 0.06, 0.18)
	var tw := create_tween()
	tw.tween_property(bolt, "position", dest, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		if FX:
			var col := Color(0.75, 0.5, 1.0) if magical else Color(0.5, 0.9, 0.55)
			FX.burst_particles(self, world_to, col, 5, "spark", 0.2)
		if is_instance_valid(bolt):
			bolt.queue_free()
	)


func _fx_heavy_lob(world_to: Vector2, on_land: Callable) -> void:
	var origin := _muzzle_origin()
	var dest := world_to - global_position
	var ball := Node2D.new()
	ball.position = origin
	ball.z_index = 25
	add_child(ball)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(0, -8), Vector2(6, 0), Vector2(0, 5)])
	core.color = Color(0.45, 0.75, 0.35)
	ball.add_child(core)
	var mid := origin.lerp(dest, 0.5) + Vector2(0, -60.0 - origin.distance_to(dest) * 0.06)
	var dur := clampf(origin.distance_to(dest) / 480.0, 0.2, 0.4)
	var tw := create_tween()
	tw.tween_property(ball, "position", mid, dur * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(ball, "position", dest, dur * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		if is_instance_valid(ball):
			ball.queue_free()
		if on_land.is_valid():
			on_land.call()
	)


func _fx_ground_nova(world_at: Vector2, radius: float) -> void:
	var local := world_at - global_position
	for i in 3:
		var ring := FX.make_ellipse_poly(14 + i * 6, 9 + i * 4, 22, Color(0.4, 0.75, 0.35, 0.45 - i * 0.1)) if FX else null
		if ring == null:
			continue
		ring.position = local
		ring.z_index = 18
		ring.scale = Vector2(0.3, 0.3)
		add_child(ring)
		var tw := create_tween()
		var sc := (radius / 50.0) * (0.7 + i * 0.25)
		tw.tween_property(ring, "scale", Vector2(sc, sc * 0.65), 0.28 + i * 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.28 + i * 0.05)
		tw.tween_callback(ring.queue_free)
	if FX:
		FX.burst_particles(self, world_at, Color(0.45, 0.8, 0.4), 14, "spark", 0.35)
