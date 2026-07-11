extends Node2D
class_name DefenseTower
## Multi-type polished towers (KR roles × Crystalward fantasy).

var type_id: String = "thornspire"
var level: int = 1
var invested_essence: int = 0
var fire_range: float = 340.0
var fire_rate: float = 0.42
var damage: int = 18
var role: String = "dps"
var channel: String = "thorn"
var aura_slow: float = 0.0
var aura_haste: float = 0.0
var mark_mult: float = 1.0
var splash: float = 0.0

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
var _haste: float = 0.0
var _haste_t: float = 0.0
var _configured: bool = false


func _ready() -> void:
	add_to_group("towers")
	z_as_relative = false
	_refresh_z()
	# Hide scene placeholders (RangeHint / Body / CrystalTip); code builds type-specific art.
	for n in ["RangeHint", "Body", "CrystalTip"]:
		if has_node(n):
			get_node(n).visible = false
	# type_id must already be set by tower_site before add_child, or configure() after.
	if not _configured:
		_apply_def(TowerTypes.def_for(type_id))
		_build_visuals()
	_bob = randf() * TAU
	set_range_visible(false)


func _refresh_z() -> void:
	if VisualStyle:
		z_index = VisualStyle.actor_z(global_position.y)
	else:
		z_index = clampi(50 + int(global_position.y) + 2000, 50, 4000)


func configure(id: String, invested: int = 0) -> void:
	## Apply type after instantiate. Prefer set type_id before add_child so _ready uses it;
	## calling configure after add_child rebuilds stats + visuals for the real type.
	type_id = id
	if invested > 0:
		invested_essence = invested
	_apply_def(TowerTypes.def_for(type_id))
	if is_inside_tree():
		_clear_visuals()
		_build_visuals()
		_configured = true
	else:
		# Will finish in _ready with this type_id already applied.
		_configured = false


func _clear_visuals() -> void:
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
	aura_slow = float(d.get("aura_slow", 0.0))
	aura_haste = float(d.get("aura_haste", 0.0))
	mark_mult = float(d.get("mark_mult", 1.0))
	splash = float(d.get("splash", 0.0))
	_def_color = d.get("color", Color(0.5, 0.7, 0.5)) as Color
	# level scaling
	damage = int(damage * (1.0 + (level - 1) * 0.45))
	fire_rate = maxf(0.22, fire_rate * (1.0 - (level - 1) * 0.12))
	fire_range = fire_range + (level - 1) * 22.0


func set_invested(amount: int) -> void:
	invested_essence = amount


func sell_value() -> int:
	return int(float(invested_essence) * GameState.TOWER_SELL_REFUND)


func set_range_visible(v: bool) -> void:
	show_range = v
	if _range_ring:
		_range_ring.visible = v


func set_info_visible(v: bool) -> void:
	## Name/level labels only when a player is nearby.
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
	level += 1
	invested_essence += GameState.TOWER_UPGRADE_COST
	_apply_def(TowerTypes.def_for(type_id))
	_apply_level_look()
	GameState.message.emit("%s → Lv%d" % [TowerTypes.def_for(type_id).get("name"), level])
	if Sfx:
		Sfx.build()
	if FX:
		FX.burst_particles(self, global_position + Vector2(0, -30), _def_color, 16, "star", 0.5)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -40), "Lv%d" % level, _def_color)
	return true


func _apply_level_look() -> void:
	if _level_label:
		_level_label.text = "Lv%d" % level
	if _body:
		_body.scale = Vector2.ONE * (1.0 + (level - 1) * 0.12)
	_rebuild_range_ring()


func _rebuild_range_ring() -> void:
	## Ring radius matches combat fire_range (circle check uses full fire_range).
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

	match role:
		"snipe":
			_build_shardbow()
		"slow":
			_build_mistvent()
		"mark":
			_build_hex()
		"buff":
			_build_hearth()
		"pulse":
			_build_bonehowl()
		_:
			_build_thornspire()

	_name_label = Label.new()
	_name_label.text = str(TowerTypes.def_for(type_id).get("short", "?"))
	_name_label.position = Vector2(-20, -70)
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.add_theme_color_override("font_color", _def_color.lightened(0.3))
	_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_name_label.add_theme_constant_override("outline_size", 3)
	_name_label.visible = false
	_visual.add_child(_name_label)

	_level_label = Label.new()
	_level_label.text = "Lv%d" % level
	_level_label.position = Vector2(-12, 14)
	_level_label.add_theme_font_size_override("font_size", 11)
	_level_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	_level_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_level_label.add_theme_constant_override("outline_size", 3)
	_level_label.visible = false
	_visual.add_child(_level_label)

	# Quiet towers — no constant particle spam; bursts only on fire/upgrade


func _build_thornspire() -> void:
	# Stone plinth
	var base := FX.make_ellipse_poly(18, 10, 20, Color(0.28, 0.26, 0.24, 0.95))
	base.position = Vector2(0, 8)
	_visual.add_child(base)
	var trunk := Polygon2D.new()
	trunk.polygon = PackedVector2Array([Vector2(-9, 10), Vector2(9, 10), Vector2(7, -22), Vector2(-7, -22)])
	trunk.color = Color(0.38, 0.26, 0.16)
	_visual.add_child(trunk)
	# Bark ridges
	var ridge := Polygon2D.new()
	ridge.polygon = PackedVector2Array([Vector2(-5, 4), Vector2(-2, -18), Vector2(1, 6)])
	ridge.color = Color(0.28, 0.18, 0.1, 0.8)
	_visual.add_child(ridge)
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(0, -56), Vector2(18, -38), Vector2(14, -16), Vector2(0, -12), Vector2(-14, -16), Vector2(-18, -38)
	])
	_body.color = _def_color
	_visual.add_child(_body)
	# Highlight facet
	var hi := Polygon2D.new()
	hi.polygon = PackedVector2Array([Vector2(-6, -48), Vector2(2, -42), Vector2(-2, -28), Vector2(-10, -36)])
	hi.color = _def_color.lightened(0.25)
	_visual.add_child(hi)
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([Vector2(0, -52), Vector2(7, -38), Vector2(0, -30), Vector2(-7, -38)])
	_accent.color = Color(0.95, 0.85, 0.45)
	_visual.add_child(_accent)


func _build_shardbow() -> void:
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-14, 12), Vector2(14, 12), Vector2(10, 0), Vector2(-10, 0)])
	base.color = Color(0.35, 0.3, 0.28)
	_visual.add_child(base)
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([Vector2(-4, 0), Vector2(4, 0), Vector2(2, -50), Vector2(-2, -50)])
	_body.color = Color(0.55, 0.5, 0.45)
	_visual.add_child(_body)
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([Vector2(0, -56), Vector2(18, -36), Vector2(0, -30), Vector2(-18, -36)])
	_accent.color = _def_color
	_visual.add_child(_accent)


func _build_mistvent() -> void:
	_body = FX.make_ellipse_poly(28, 16, 24, Color(0.25, 0.18, 0.3, 0.85))
	_body.position = Vector2(0, 4)
	_visual.add_child(_body)
	_accent = FX.make_ellipse_poly(22, 28, 20, Color(_def_color.r, _def_color.g, _def_color.b, 0.35))
	_accent.position = Vector2(0, -18)
	_visual.add_child(_accent)
	var mist := FX.make_ellipse_poly(fire_range * 0.35, fire_range * 0.22, 32, Color(0.6, 0.4, 0.9, 0.1))
	mist.z_index = -1
	mist.name = "MistAura"
	_visual.add_child(mist)


func _build_hex() -> void:
	var pole := Polygon2D.new()
	pole.polygon = PackedVector2Array([Vector2(-3, 12), Vector2(3, 12), Vector2(2, -40), Vector2(-2, -40)])
	pole.color = Color(0.3, 0.25, 0.35)
	_visual.add_child(pole)
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(0, -55), Vector2(14, -42), Vector2(10, -28), Vector2(0, -22), Vector2(-10, -28), Vector2(-14, -42)
	])
	_body.color = _def_color
	_visual.add_child(_body)
	_accent = FX.make_ellipse_poly(6, 6, 12, Color(1, 0.9, 0.5, 0.9))
	_accent.position = Vector2(0, -40)
	_visual.add_child(_accent)


func _build_hearth() -> void:
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-18, 10), Vector2(18, 10), Vector2(16, -8), Vector2(8, -28), Vector2(-8, -28), Vector2(-16, -8)
	])
	_body.color = Color(0.4, 0.28, 0.22)
	_visual.add_child(_body)
	_accent = FX.make_ellipse_poly(14, 12, 16, _def_color)
	_accent.position = Vector2(0, -18)
	_visual.add_child(_accent)
	var glow := FX.make_ellipse_poly(fire_range * 0.32, fire_range * 0.2, 28, Color(1, 0.5, 0.25, 0.08))
	glow.z_index = -1
	_visual.add_child(glow)


func _build_bonehowl() -> void:
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(0, -52), Vector2(12, -20), Vector2(8, 12), Vector2(-8, 12), Vector2(-12, -20)
	])
	_body.color = Color(0.85, 0.82, 0.78)
	_visual.add_child(_body)
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([Vector2(-16, -36), Vector2(-4, -48), Vector2(-6, -28)])
	_accent.color = _def_color
	_visual.add_child(_accent)
	var horn2 := _accent.duplicate() as Polygon2D
	horn2.scale.x = -1
	_visual.add_child(horn2)


func _process(delta: float) -> void:
	if GameState != null and GameState.is_game_over:
		return
	_bob += delta
	if _visual:
		_visual.position.y = sin(_bob * 1.8) * 1.4
	if _accent and role != "slow":
		_accent.modulate.a = 0.7 + 0.3 * sin(_bob * 3.0)

	# Haste timer (keep in _process so combat always sees it)
	if _haste_t > 0.0:
		_haste_t -= delta
		if _haste_t <= 0.0:
			_haste = 0.0

	# Auras every frame while active
	if aura_slow > 0.0:
		_apply_slow_aura()
	if aura_haste > 0.0:
		_apply_haste_aura()

	_cd = maxf(0.0, _cd - delta)
	if _cd > 0.0:
		return

	var target := _find_target()
	if target == null or not is_instance_valid(target):
		# Buff-only towers still pulse aura on cooldown so they feel "alive"
		if role == "buff" and aura_haste > 0.0:
			_cd = fire_rate
		return

	_cd = maxf(0.12, fire_rate * (1.0 - clampf(_haste, 0.0, 0.5)))
	_fire_at(target)


func _apply_slow_aura() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var r2 := fire_range * fire_range
	for e in tree.get_nodes_in_group("enemies"):
		if e is Node2D and global_position.distance_squared_to(e.global_position) <= r2:
			if e.has_method("apply_slow"):
				e.call("apply_slow", aura_slow, 0.4)


func _apply_haste_aura() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var r2 := (fire_range * 0.9) * (fire_range * 0.9)
	for t in tree.get_nodes_in_group("towers"):
		if t == self or not (t is Node2D):
			continue
		if global_position.distance_squared_to(t.global_position) <= r2:
			if t.has_method("apply_haste"):
				t.call("apply_haste", aura_haste, 0.45)


func apply_haste(amount: float, duration: float) -> void:
	_haste = maxf(_haste, amount)
	_haste_t = maxf(_haste_t, duration)


func _fire_at(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	var dmg := damage
	if target.has_method("is_marked") and bool(target.call("is_marked")):
		dmg = int(float(dmg) * 1.35)
	var host: Node = get_parent()
	if host == null:
		host = self

	if target.has_method("take_damage"):
		if splash > 0.0:
			var tree := get_tree()
			if tree:
				for e in tree.get_nodes_in_group("enemies"):
					if not (e is Node2D) or not is_instance_valid(e):
						continue
					if target.global_position.distance_to(e.global_position) <= splash:
						var mult := 1.0 if e == target else 0.55
						var hit := maxi(1, int(float(dmg) * mult))
						e.call("take_damage", hit)
						FloatingText.spawn(host, e.global_position + Vector2(0, -12), str(hit), _def_color)
		else:
			target.call("take_damage", dmg)
			FloatingText.spawn(host, target.global_position + Vector2(0, -16), str(dmg), _def_color)

	if role == "mark" and target.has_method("apply_mark") and is_instance_valid(target):
		target.call("apply_mark", mark_mult, 3.0)
	if is_instance_valid(target):
		_muzzle_flash(target.global_position)


func _find_target() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var crystal_pos := PathNetwork.CRYSTAL if PathNetwork else Vector2.ZERO
	var best: Node2D = null
	var best_score := -1.0
	var r2 := fire_range * fire_range
	for e in tree.get_nodes_in_group("enemies"):
		if not (e is Node2D) or not is_instance_valid(e):
			continue
		var d2: float = global_position.distance_squared_to(e.global_position)
		if d2 > r2:
			continue
		# Prefer enemies closest to the Lightwell (about to leak), then nearer to tower.
		var to_crystal: float = e.global_position.distance_to(crystal_pos)
		var score := 10000.0 / maxf(40.0, to_crystal) + 200.0 / maxf(20.0, sqrt(d2))
		if role == "snipe" and e.has_method("is_elite") and bool(e.call("is_elite")):
			score *= 3.0
		if score > best_score:
			best_score = score
			best = e
	return best


func _muzzle_flash(to: Vector2) -> void:
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = Color(_def_color.r, _def_color.g, _def_color.b, 0.95)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var origin := Vector2(0, -36)
	line.points = PackedVector2Array([origin, to - global_position])
	line.z_index = 20
	add_child(line)
	var tw := create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.14)
	tw.tween_callback(line.queue_free)
