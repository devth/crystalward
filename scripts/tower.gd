extends Node2D
class_name DefenseTower
## Towers: Arrow (both), Briar (ground), Arcane (magic/armor), later garrison/ballista/mortar.

const GarrisonUnitScript = preload("res://scripts/garrison_unit.gd")

var type_id: String = "arrow"
var level: int = 1
var invested_essence: int = 0
var fire_range: float = 340.0
var fire_rate: float = 0.58
var damage: int = 6
var role: String = "dps"
var channel: String = "thorn"
## "ground" | "air" | "both"
var target_layer: String = "both"
var splash: float = 0.0
var special: String = "arrow"
var soldier_count: int = 2
var soldier_hp: int = 42
var soldier_damage: int = 5
var soldier_range: float = 52.0
var respawn_time: float = 5.5
var rally_dist: float = 70.0

var _cd: float = 0.0
var _visual: Node2D
var _body: Polygon2D
var _accent: Polygon2D
var _aim_root: Node2D  ## rotates to face target (bow / barrel)
var _range_ring: Polygon2D
var _level_label: Label
var _name_label: Label
var _bob: float = 0.0
var show_range: bool = false
var _def_color: Color = Color(0.62, 0.48, 0.32)
var _configured: bool = false
var _soldiers: Array[Node2D] = []
var _respawn_timers: Array[float] = []
var _rally: Vector2 = Vector2.ZERO
var _builder_index: int = 0
var _aim_angle: float = PI * 0.5  ## rest: point down-ish (not straight up)
var _rest_angle: float = PI * 0.55


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
	_aim_root = null
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
	splash = float(d.get("splash", 0.0))
	special = str(d.get("special", ""))
	soldier_count = int(d.get("soldier_count", 2))
	soldier_hp = int(d.get("soldier_hp", 42))
	soldier_damage = int(d.get("soldier_damage", 5))
	soldier_range = float(d.get("soldier_range", 52.0))
	respawn_time = float(d.get("respawn", 5.5))
	rally_dist = float(d.get("rally_dist", 70.0))
	_def_color = d.get("color", Color(0.5, 0.7, 0.5)) as Color

	damage = int(damage * (1.0 + (level - 1) * 0.28))
	fire_rate = maxf(0.28, fire_rate * (1.0 - (level - 1) * 0.08))
	fire_range = fire_range + (level - 1) * 18.0
	if splash > 0.0:
		splash += (level - 1) * 18.0
	soldier_count = soldier_count + (level - 1)
	soldier_hp = int(soldier_hp * (1.0 + (level - 1) * 0.28))
	soldier_damage = int(soldier_damage * (1.0 + (level - 1) * 0.22))
	respawn_time = maxf(3.0, respawn_time - (level - 1) * 0.45)


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
	var cap := GameState.TOWER_MAX_LEVEL
	if TowerTypes and TowerTypes.has_method("max_level_for"):
		cap = TowerTypes.max_level_for(type_id)
	if level >= cap:
		if cap <= 1:
			GameState.message.emit("Upgrades locked until later phases")
		else:
			GameState.message.emit("Max level for this tower (Lv%d)" % cap)
		return false
	if not GameState.try_spend_essence(GameState.TOWER_UPGRADE_COST):
		return false
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
	GameState.message.emit("%s → Lv%d" % [TowerTypes.def_for(type_id).get("name"), level])
	if Sfx:
		Sfx.build()
	if FX:
		FX.burst_particles(self, global_position + Vector2(0, -30), _def_color, 16 + level * 6, "star", 0.5)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -40), "Lv%d" % level, _def_color)
	return true


func _level_scale() -> float:
	match level:
		1:
			return 1.0
		2:
			return 1.22
		_:
			return 1.45


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
		"arrow":
			_build_arrow_tower()
		"briar":
			_build_briar()
		"arcane":
			_build_arcane()
		"garrison":
			_build_garrison()
		"ballista":
			_build_ballista()
		"mortar":
			_build_mortar()
		_:
			_build_arrow_tower()

	var tag := Label.new()
	tag.text = str(TowerTypes.def_for(type_id).get("target_label", "ALL"))
	tag.position = Vector2(-14, -78)
	tag.add_theme_font_size_override("font_size", 9)
	tag.add_theme_color_override("font_color", _layer_tag_color())
	tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	tag.add_theme_constant_override("outline_size", 2)
	tag.visible = false
	tag.name = "LayerTag"
	_visual.add_child(tag)

	_name_label = Label.new()
	_name_label.text = str(TowerTypes.def_for(type_id).get("short", "?"))
	_name_label.position = Vector2(-22, -66)
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.add_theme_color_override("font_color", _def_color.lightened(0.3))
	_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_name_label.add_theme_constant_override("outline_size", 3)
	_name_label.visible = false
	_visual.add_child(_name_label)

	_level_label = Label.new()
	_level_label.text = "Lv%d" % level
	_level_label.position = Vector2(-14, 16)
	_level_label.add_theme_font_size_override("font_size", 11)
	_level_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	_level_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_level_label.add_theme_constant_override("outline_size", 3)
	_level_label.visible = false
	_visual.add_child(_level_label)

	_visual.scale = Vector2.ONE * _level_scale()
	if _aim_root:
		_aim_root.rotation = _rest_angle
		_aim_angle = _rest_angle


func _layer_tag_color() -> Color:
	match target_layer:
		"air":
			return Color(0.65, 0.9, 1.0)
		"ground":
			return Color(0.55, 0.9, 0.5)
		_:
			return Color(0.95, 0.9, 0.55)


func _add_plinth(rx: float = 18.0, ry: float = 10.0) -> void:
	var outer := FX.make_ellipse_poly(rx + 4, ry + 2, 22, Color(0.14, 0.12, 0.1, 0.9))
	outer.position = Vector2(0, 10)
	_visual.add_child(outer)
	var base := FX.make_ellipse_poly(rx, ry, 20, Color(0.32, 0.26, 0.2, 0.95))
	base.position = Vector2(0, 8)
	_visual.add_child(base)


## Rustic wooden arrow tower — aim_root holds the bow, points at targets.
func _build_arrow_tower() -> void:
	_add_plinth(18.0, 10.0)
	# Timber post
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-8, 8), Vector2(8, 8), Vector2(7, -18), Vector2(4, -36),
		Vector2(-4, -36), Vector2(-7, -18)
	])
	_body.color = Color(0.42, 0.32, 0.22)
	_visual.add_child(_body)
	# Platform
	var deck := Polygon2D.new()
	deck.polygon = PackedVector2Array([
		Vector2(-14, -34), Vector2(14, -34), Vector2(12, -40), Vector2(-12, -40)
	])
	deck.color = Color(0.36, 0.28, 0.18)
	_visual.add_child(deck)
	# Aim assembly at platform height
	_aim_root = Node2D.new()
	_aim_root.name = "Aim"
	_aim_root.position = Vector2(0, -38)
	_visual.add_child(_aim_root)
	# Bow curve (points along +X local; rotation aims)
	var bow := Polygon2D.new()
	bow.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(4, -6), Vector2(6, 0), Vector2(4, 6), Vector2(0, 12),
		Vector2(2, 6), Vector2(3, 0), Vector2(2, -6)
	])
	bow.color = Color(0.55, 0.4, 0.25)
	_aim_root.add_child(bow)
	# Arrow shaft resting on bow (along +X)
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([
		Vector2(-4, -2), Vector2(18, -1.5), Vector2(22, 0), Vector2(18, 1.5), Vector2(-4, 2)
	])
	_accent.color = Color(0.75, 0.7, 0.55)
	_aim_root.add_child(_accent)
	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(22, 0), Vector2(28, -4), Vector2(28, 4)
	])
	head.color = Color(0.55, 0.55, 0.58)
	_aim_root.add_child(head)
	# Fletching
	var fletch := Polygon2D.new()
	fletch.polygon = PackedVector2Array([
		Vector2(-4, 0), Vector2(-10, -5), Vector2(-7, 0), Vector2(-10, 5)
	])
	fletch.color = Color(0.45, 0.55, 0.35)
	_aim_root.add_child(fletch)
	_rest_angle = PI * 0.65  # down-right rest pose
	_aim_angle = _rest_angle


func _build_briar() -> void:
	_add_plinth(20.0, 11.0)
	var h := 48.0 + (level - 1) * 10.0
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(0, -h), Vector2(12, -h * 0.6), Vector2(9, 8), Vector2(-9, 8), Vector2(-12, -h * 0.6)
	])
	_body.color = _def_color
	_visual.add_child(_body)
	for i in (4 + level):
		var ang := TAU * float(i) / float(4 + level)
		var thorn := Polygon2D.new()
		thorn.polygon = PackedVector2Array([Vector2(0, 0), Vector2(3, -9), Vector2(0, -14), Vector2(-3, -9)])
		thorn.color = _def_color.lightened(0.12)
		thorn.position = Vector2(cos(ang), sin(ang) * 0.7) * 12.0 + Vector2(0, -h * 0.4)
		thorn.rotation = ang + PI * 0.5
		_visual.add_child(thorn)
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([Vector2(0, -h - 2), Vector2(4, -h * 0.85), Vector2(0, -h * 0.75), Vector2(-4, -h * 0.85)])
	_accent.color = Color(0.9, 0.8, 0.4)
	_visual.add_child(_accent)


func _build_arcane() -> void:
	_add_plinth(16.0, 9.0)
	var h := 50.0 + (level - 1) * 10.0
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-6, 8), Vector2(6, 8), Vector2(5, -h * 0.7), Vector2(0, -h), Vector2(-5, -h * 0.7)
	])
	_body.color = Color(0.28, 0.22, 0.4)
	_visual.add_child(_body)
	_aim_root = Node2D.new()
	_aim_root.position = Vector2(0, -h * 0.55)
	_visual.add_child(_aim_root)
	_accent = FX.make_ellipse_poly(10 + level * 2, 10 + level * 2, 14, Color(0.7, 0.55, 0.95, 0.85))
	_aim_root.add_child(_accent)
	var shard := Polygon2D.new()
	shard.polygon = PackedVector2Array([Vector2(0, -14), Vector2(6, 0), Vector2(0, 6), Vector2(-6, 0)])
	shard.color = Color(0.85, 0.75, 1.0, 0.9)
	_aim_root.add_child(shard)
	_rest_angle = 0.0
	_aim_angle = 0.0


func _build_garrison() -> void:
	_add_plinth(22.0, 12.0)
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-16, 6), Vector2(16, 6), Vector2(14, -8), Vector2(10, -26),
		Vector2(-10, -26), Vector2(-14, -8)
	])
	_body.color = Color(0.48, 0.36, 0.26)
	_visual.add_child(_body)
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([Vector2(-14, -26), Vector2(0, -44 - level * 3), Vector2(14, -26)])
	roof.color = Color(0.62, 0.4, 0.28)
	_visual.add_child(roof)
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([Vector2(8, -36), Vector2(24, -32), Vector2(22, -20), Vector2(8, -24)])
	_accent.color = Color(0.8, 0.5, 0.3)
	_visual.add_child(_accent)


func _build_ballista() -> void:
	_add_plinth(16.0, 9.0)
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([Vector2(-5, 8), Vector2(5, 8), Vector2(4, -40), Vector2(-4, -40)])
	_body.color = Color(0.4, 0.35, 0.3)
	_visual.add_child(_body)
	_aim_root = Node2D.new()
	_aim_root.position = Vector2(0, -36)
	_visual.add_child(_aim_root)
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([
		Vector2(-18, -4), Vector2(-8, -14), Vector2(0, -18), Vector2(8, -14), Vector2(18, -4),
		Vector2(10, -2), Vector2(0, -10), Vector2(-10, -2)
	])
	_accent.color = _def_color
	_aim_root.add_child(_accent)
	_rest_angle = PI * 0.55
	_aim_angle = _rest_angle


func _build_mortar() -> void:
	_add_plinth(20.0, 11.0)
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-16, 6), Vector2(16, 6), Vector2(12, -8), Vector2(6, -20), Vector2(-6, -20), Vector2(-12, -8)
	])
	_body.color = Color(0.32, 0.18, 0.14)
	_visual.add_child(_body)
	_accent = FX.make_ellipse_poly(8 + level, 7 + level, 12, Color(1.0, 0.55, 0.2, 0.9))
	_accent.position = Vector2(0, -22)
	_visual.add_child(_accent)
	if level >= 2:
		var ring := FX.make_ellipse_poly(28, 14, 20, Color(1.0, 0.4, 0.15, 0.12))
		ring.position = Vector2(0, 2)
		ring.z_index = -1
		_visual.add_child(ring)


# ── Combat ────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if GameState != null and GameState.is_game_over:
		return
	_bob += delta
	if _visual and role != "garrison":
		_visual.position.y = sin(_bob * 1.6) * 0.8
	var tag := _visual.get_node_or_null("LayerTag") if _visual else null
	if tag is CanvasItem and _name_label:
		(tag as CanvasItem).visible = _name_label.visible

	if role == "garrison":
		_tick_garrison(delta)
		return

	var target := _find_target()
	_update_aim(delta, target)

	_cd = maxf(0.0, _cd - delta)
	if _cd > 0.0:
		return
	if target == null or not is_instance_valid(target):
		return
	_cd = maxf(0.12, fire_rate)
	_fire_at(target)


func _update_aim(delta: float, target: Node2D) -> void:
	if _aim_root == null:
		return
	var desired := _rest_angle
	if target and is_instance_valid(target):
		var to := target.global_position - (_aim_root.global_position if _aim_root.is_inside_tree() else global_position)
		# Local aim: angle of vector; bow art points +X
		desired = to.angle()
	# Smooth turn toward target
	var diff := wrapf(desired - _aim_angle, -PI, PI)
	_aim_angle += clampf(diff, -4.0 * delta, 4.0 * delta)
	_aim_root.rotation = _aim_angle


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
		"arrow", "snipe":
			_fire_aimed_bolt(target, host, false)
		"briar":
			_fire_briar(target, host)
		"arcane":
			_fire_aimed_bolt(target, host, true)
		"splash":
			_fire_splash(target, host)
		_:
			_hit_one(target, damage, host)


func _muzzle_world() -> Vector2:
	if _aim_root and is_instance_valid(_aim_root):
		# Tip of arrow in local +X
		return _aim_root.to_global(Vector2(24, 0))
	return global_position + Vector2(0, -36)


func _fire_aimed_bolt(target: Node2D, host: Node, magical: bool) -> void:
	var from := _muzzle_world()
	var to := target.global_position + Vector2(0, -10)
	var dmg := damage
	# Snap aim fully when firing
	if _aim_root:
		_aim_angle = (to - from).angle()
		_aim_root.rotation = _aim_angle
	_fx_fly_bolt(from, to, magical, func():
		if is_instance_valid(target) and is_inside_tree():
			_hit_one(target, dmg, host)
	)


func _fire_briar(target: Node2D, host: Node) -> void:
	_fx_briar_spike(target.global_position)
	_hit_one(target, damage, host)


func _fire_splash(target: Node2D, host: Node) -> void:
	var impact := target.global_position
	_fx_fly_bolt(global_position + Vector2(0, -28), impact, false, func():
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
		if FX:
			FX.burst_particles(self, impact, _def_color, 14, "spark", 0.35)
	)


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
		if m >= 1.35:
			txt_col = Color(1.0, 0.95, 0.35)
		elif m <= 0.65:
			txt_col = Color(0.55, 0.65, 0.95)
		target.call("take_damage", dmg, channel, special, role)
	else:
		target.call("take_damage", shown)
	FloatingText.spawn(host, target.global_position + Vector2(0, -16), str(maxi(1, shown)), txt_col)


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


func _fx_fly_bolt(from_world: Vector2, to_world: Vector2, magical: bool, on_hit: Callable) -> void:
	var bolt := Node2D.new()
	bolt.z_index = 30
	var parent_n: Node = get_parent() if get_parent() else self
	parent_n.add_child(bolt)
	bolt.global_position = from_world
	bolt.rotation = (to_world - from_world).angle()
	var shaft := Polygon2D.new()
	if magical:
		shaft.polygon = PackedVector2Array([Vector2(-6, -3), Vector2(10, -2), Vector2(14, 0), Vector2(10, 2), Vector2(-6, 3)])
		shaft.color = Color(0.75, 0.55, 1.0, 0.95)
	else:
		shaft.polygon = PackedVector2Array([Vector2(-8, -2), Vector2(12, -1.5), Vector2(16, 0), Vector2(12, 1.5), Vector2(-8, 2)])
		shaft.color = Color(0.78, 0.7, 0.5, 0.95)
	bolt.add_child(shaft)
	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([Vector2(14, 0), Vector2(22, -4), Vector2(22, 4)])
	tip.color = Color(0.9, 0.85, 1.0) if magical else Color(0.6, 0.6, 0.62)
	bolt.add_child(tip)
	var dist := from_world.distance_to(to_world)
	var dur := clampf(dist / 900.0, 0.07, 0.22)
	var tw := bolt.create_tween()
	tw.tween_property(bolt, "global_position", to_world, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		if on_hit.is_valid():
			on_hit.call()
		if FX:
			FX.burst_particles(parent_n, to_world, Color(0.75, 0.55, 1.0) if magical else Color(0.7, 0.65, 0.45), 5, "spark", 0.18)
		if is_instance_valid(bolt):
			bolt.queue_free()
	)


func _fx_briar_spike(world_to: Vector2) -> void:
	var local := world_to - global_position
	var spike := Polygon2D.new()
	spike.polygon = PackedVector2Array([Vector2(0, 8), Vector2(4, -6), Vector2(0, -16), Vector2(-4, -6)])
	spike.color = Color(0.4, 0.7, 0.35, 0.9)
	spike.position = Vector2(0, -20)
	spike.z_index = 20
	add_child(spike)
	var tw := create_tween()
	tw.tween_property(spike, "position", local + Vector2(0, -8), 0.12)
	tw.tween_callback(func():
		if FX:
			FX.burst_particles(self, world_to, Color(0.4, 0.75, 0.35), 6, "spark", 0.2)
		if is_instance_valid(spike):
			spike.queue_free()
	)


# ── Garrison ──────────────────────────────────────────────────────────────────

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
	var host := _world_host()
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


func _tick_garrison(delta: float) -> void:
	for i in _respawn_timers.size():
		if _respawn_timers[i] > 0.0:
			_respawn_timers[i] = maxf(0.0, _respawn_timers[i] - delta)
			if _respawn_timers[i] <= 0.0:
				if i >= _soldiers.size() or _soldiers[i] == null or not is_instance_valid(_soldiers[i]):
					_spawn_soldier(i)
