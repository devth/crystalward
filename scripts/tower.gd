extends Node2D
class_name DefenseTower
## Unique towers with air / ground / both targeting + dedicated AOE roles.

var type_id: String = "thornspire"
var level: int = 1
var invested_essence: int = 0
var fire_range: float = 340.0
var fire_rate: float = 0.42
var damage: int = 18
var role: String = "dps"
var channel: String = "thorn"
## "ground" | "air" | "both"
var target_layer: String = "ground"
var aura_slow: float = 0.0
var splash: float = 0.0
var special: String = ""
var root_duration: float = 0.0
var chain_count: int = 1
var chain_falloff: float = 0.7

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
	else:
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
	target_layer = str(d.get("target", "both"))
	aura_slow = float(d.get("aura_slow", 0.0))
	splash = float(d.get("splash", 0.0))
	special = str(d.get("special", ""))
	root_duration = float(d.get("root_duration", 0.0))
	chain_count = int(d.get("chain_count", 1))
	chain_falloff = float(d.get("chain_falloff", 0.7))
	_def_color = d.get("color", Color(0.5, 0.7, 0.5)) as Color
	# level scaling
	damage = int(damage * (1.0 + (level - 1) * 0.45))
	fire_rate = maxf(0.22, fire_rate * (1.0 - (level - 1) * 0.12))
	fire_range = fire_range + (level - 1) * 22.0
	if root_duration > 0.0:
		root_duration += (level - 1) * 0.2
	if chain_count > 1:
		chain_count += level - 1
	if splash > 0.0:
		splash += (level - 1) * 12.0


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
	level += 1
	invested_essence += GameState.TOWER_UPGRADE_COST
	_apply_def(TowerTypes.def_for(type_id))
	var keep_range := show_range
	var keep_info := _name_label != null and _name_label.visible
	_clear_visuals()
	_build_visuals()
	set_range_visible(keep_range)
	set_info_visible(keep_info)
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
		"shardbow":
			_build_shardbow()
		"emberfall":
			_build_emberfall()
		"mistvent":
			_build_mistvent()
		"skyshard":
			_build_skyshard()
		"rootgate":
			_build_rootgate()
		_:
			_build_thornspire()

	# Target layer badge (GND / AIR / ALL)
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
	var fleck_n := 2 if level == 2 else 4
	for i in fleck_n:
		var ang := TAU * float(i) / float(fleck_n) - PI * 0.5
		var fleck := Polygon2D.new()
		fleck.polygon = PackedVector2Array([
			Vector2(0, -10), Vector2(5, -2), Vector2(0, 4), Vector2(-5, -2)
		])
		fleck.color = _def_color.lightened(0.25)
		fleck.position = Vector2(cos(ang), sin(ang) * 0.7) * (28.0 + level * 6.0) + Vector2(0, -28)
		_visual.add_child(fleck)
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


## GND DPS — briar spire with thorns.
func _build_thornspire() -> void:
	_add_plinth(20.0 + level * 2, 11.0)
	var h := 54.0 + (level - 1) * 12.0
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(0, -h), Vector2(14, -h * 0.65), Vector2(10, 8), Vector2(-10, 8), Vector2(-14, -h * 0.65)
	])
	_body.color = _def_color
	_visual.add_child(_body)
	for i in (5 + level):
		var ang := TAU * float(i) / float(5 + level)
		var thorn := Polygon2D.new()
		thorn.polygon = PackedVector2Array([Vector2(0, 0), Vector2(3, -10), Vector2(0, -16), Vector2(-3, -10)])
		thorn.color = _def_color.lightened(0.15)
		thorn.position = Vector2(cos(ang), sin(ang) * 0.7) * 14.0 + Vector2(0, -h * 0.4)
		thorn.rotation = ang + PI * 0.5
		_visual.add_child(thorn)
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([Vector2(0, -h - 4), Vector2(5, -h * 0.85), Vector2(0, -h * 0.75), Vector2(-5, -h * 0.85)])
	_accent.color = Color(0.95, 0.85, 0.4)
	_visual.add_child(_accent)


## GND AOE — ember brazier with splash rings.
func _build_emberfall() -> void:
	_add_plinth(22.0 + level * 2, 12.0)
	# Bowl
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-18, 6), Vector2(18, 6), Vector2(14, -10), Vector2(8, -22), Vector2(-8, -22), Vector2(-14, -10)
	])
	_body.color = Color(0.35, 0.18, 0.12)
	_visual.add_child(_body)
	# Concentric blast rings (AOE read)
	for i in (2 + mini(level, 2)):
		var ring := FX.make_ellipse_poly(22 + i * 12, 12 + i * 6, 22, Color(1.0, 0.45, 0.15, 0.14 - i * 0.03))
		ring.position = Vector2(0, 2)
		ring.z_index = -1
		_visual.add_child(ring)
	# Flame stack
	for i in (2 + level):
		var flame := Polygon2D.new()
		var fh := 20.0 + i * 8.0
		flame.polygon = PackedVector2Array([
			Vector2(-5 + i, -8), Vector2(0, -fh - 10), Vector2(5 - i, -8), Vector2(0, -14)
		])
		flame.color = Color(1.0, 0.5 + i * 0.08, 0.15, 0.9 - i * 0.1)
		flame.position = Vector2((i - 1) * 4.0, -16)
		_visual.add_child(flame)
	_accent = FX.make_ellipse_poly(10 + level, 8 + level, 14, Color(1.0, 0.85, 0.4, 0.9))
	_accent.position = Vector2(0, -22)
	_visual.add_child(_accent)


## ALL SNIPE — tall bow with long bolt.
func _build_shardbow() -> void:
	_add_plinth(16.0, 9.0)
	var h := 60.0 + (level - 1) * 12.0
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-5, 8), Vector2(5, 8), Vector2(3, -h * 0.85), Vector2(-3, -h * 0.85)
	])
	_body.color = Color(0.45, 0.4, 0.38)
	_visual.add_child(_body)
	var bow_w := 26.0 + level * 5.0
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
		Vector2(0, -h - 18 - level * 3), Vector2(3, -h * 0.55), Vector2(0, -h * 0.5), Vector2(-3, -h * 0.55)
	])
	bolt.color = Color(0.95, 0.9, 0.55)
	_visual.add_child(bolt)


## ALL SLOW — mist cauldron.
func _build_mistvent() -> void:
	_add_plinth(24.0 + level * 2, 13.0)
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-20 - level * 2, 6), Vector2(20 + level * 2, 6),
		Vector2(16, -8), Vector2(10, -18), Vector2(-10, -18), Vector2(-16, -8)
	])
	_body.color = Color(0.28, 0.18, 0.35)
	_visual.add_child(_body)
	_accent = FX.make_ellipse_poly(16 + level * 3, 28 + level * 6, 22, Color(_def_color.r, _def_color.g, _def_color.b, 0.4))
	_accent.position = Vector2(0, -36 - level * 3)
	_visual.add_child(_accent)
	for i in (3 + level):
		var puff := FX.make_ellipse_poly(12 + i * 2, 10 + i, 14, Color(0.65, 0.45, 0.95, 0.16))
		puff.position = Vector2((i - 1.5) * 8.0, -48 - i * 8)
		_visual.add_child(puff)
	var mist_pool := FX.make_ellipse_poly(minf(70.0, fire_range * 0.22), minf(42.0, fire_range * 0.14), 28, Color(0.55, 0.35, 0.9, 0.12))
	mist_pool.z_index = -1
	_visual.add_child(mist_pool)


## AIR — floating skyshard constellation.
func _build_skyshard() -> void:
	_add_plinth(16.0, 9.0)
	var h := 56.0 + level * 10.0
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(0, -h), Vector2(11, -h * 0.55), Vector2(5, 6), Vector2(-5, 6), Vector2(-11, -h * 0.55)
	])
	_body.color = Color(0.5, 0.9, 0.98)
	_visual.add_child(_body)
	_accent = FX.make_ellipse_poly(9 + level * 2, 9 + level * 2, 14, Color(0.95, 0.98, 1.0, 0.8))
	_accent.position = Vector2(0, -h * 0.72)
	_visual.add_child(_accent)
	# Orbiting air shards
	var n := 3 + level
	for i in n:
		var ang := TAU * float(i) / float(n) - PI * 0.5
		var p := Vector2(cos(ang), sin(ang) * 0.7) * (24.0 + level * 4.0) + Vector2(0, -h * 0.45)
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([Vector2(0, -9), Vector2(5, 0), Vector2(0, 5), Vector2(-5, 0)])
		shard.color = Color(0.65, 0.95, 1.0, 0.9)
		shard.position = p
		_visual.add_child(shard)
	# Small wing marks for air identity
	for sx in [-1.0, 1.0]:
		var wing := Polygon2D.new()
		wing.polygon = PackedVector2Array([
			Vector2(0, -h * 0.4), Vector2(sx * 22, -h * 0.55), Vector2(sx * 8, -h * 0.3)
		])
		wing.color = Color(0.55, 0.85, 0.95, 0.45)
		_visual.add_child(wing)


## GND CONTROL — root arch with grasping vines.
func _build_rootgate() -> void:
	_add_plinth(24.0 + level * 2, 12.0)
	var h := 48.0 + level * 10.0
	for sx in [-1.0, 1.0]:
		var pillar := Polygon2D.new()
		pillar.polygon = PackedVector2Array([
			Vector2(sx * 8, 8), Vector2(sx * 18, 6), Vector2(sx * 16, -h * 0.55),
			Vector2(sx * 6, -h * 0.85), Vector2(sx * 4, -h * 0.4)
		])
		pillar.color = Color(0.32, 0.42, 0.24)
		_visual.add_child(pillar)
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-14, -h * 0.75), Vector2(0, -h - 8), Vector2(14, -h * 0.75),
		Vector2(8, -h * 0.55), Vector2(0, -h * 0.65), Vector2(-8, -h * 0.55)
	])
	_body.color = Color(0.38, 0.52, 0.28)
	_visual.add_child(_body)
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([
		Vector2(-6, 4), Vector2(-28 - level * 4, 2), Vector2(-20, -8), Vector2(-4, -2)
	])
	_accent.color = _def_color
	_visual.add_child(_accent)
	var root2 := _accent.duplicate() as Polygon2D
	root2.scale.x = -1
	_visual.add_child(root2)
	var bind := FX.make_ellipse_poly(32 + level * 4, 18 + level * 2, 24, Color(0.35, 0.6, 0.3, 0.14))
	bind.position = Vector2(0, 2)
	bind.z_index = -1
	_visual.add_child(bind)


func _process(delta: float) -> void:
	if GameState != null and GameState.is_game_over:
		return
	_bob += delta
	if _visual:
		_visual.position.y = sin(_bob * 1.8) * 1.4
	if _accent and role != "slow":
		_accent.modulate.a = 0.7 + 0.3 * sin(_bob * 3.0)
	# Show layer tag with name labels
	var tag := _visual.get_node_or_null("LayerTag") if _visual else null
	if tag is CanvasItem and _name_label:
		(tag as CanvasItem).visible = _name_label.visible

	if aura_slow > 0.0:
		_apply_slow_aura()

	_cd = maxf(0.0, _cd - delta)
	if _cd > 0.0:
		return

	var target := _find_target()
	if target == null or not is_instance_valid(target):
		# Slow aura towers still tick on cooldown so they feel alive
		if role == "slow" and aura_slow > 0.0:
			_cd = fire_rate
		return

	_cd = maxf(0.12, fire_rate)
	_fire_at(target)


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


func _apply_slow_aura() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var r2 := fire_range * fire_range
	for e in tree.get_nodes_in_group("enemies"):
		if not (e is Node2D) or not _can_target(e):
			continue
		if global_position.distance_squared_to(e.global_position) <= r2:
			if e.has_method("apply_slow"):
				e.call("apply_slow", aura_slow, 0.4)


func _fire_at(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	var host: Node = get_parent()
	if host == null:
		host = self

	match type_id:
		"thornspire":
			_fire_multishot(host)
		"emberfall":
			_fire_splash(target, host)
		"skyshard":
			_fire_chain(target, host)
		"shardbow":
			_fire_snipe_bolt(target, host)
		"mistvent":
			_fire_mist_pulse(target, host)
		"rootgate":
			_fire_root_pulse(target, host)
		_:
			# Fallback by special
			match special:
				"multishot":
					_fire_multishot(host)
				"chain":
					_fire_chain(target, host)
				"root":
					_fire_root_pulse(target, host)
				"splash":
					_fire_splash(target, host)
				_:
					_hit_one(target, damage, host)
					_fx_generic_spark(target.global_position)


func _execute_damage(target: Node2D) -> int:
	var dmg := damage
	if target.has_method("is_elite") and bool(target.call("is_elite")):
		dmg = int(float(dmg) * 1.35)
	var hp_v = target.get("hp")
	var max_v = target.get("max_hp")
	if hp_v != null and max_v != null:
		var mx := maxi(1, int(max_v))
		if float(hp_v) / float(mx) <= 0.28:
			dmg = int(float(dmg) * 1.6)
	# Bonus vs flyers for all-target snipe
	if _enemy_is_flying(target):
		dmg = int(float(dmg) * 1.15)
	return dmg


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
	## Emberfall: lob a molten ember, then detonate a fire nova on impact.
	var impact := target.global_position
	_fx_ember_lob(impact, func():
		if not is_inside_tree():
			return
		var tree := get_tree()
		if tree == null:
			return
		var r := maxf(splash, 80.0)
		for e in tree.get_nodes_in_group("enemies"):
			if not (e is Node2D) or not is_instance_valid(e) or not _can_target(e):
				continue
			if impact.distance_to(e.global_position) <= r:
				var mult := 1.0 if (is_instance_valid(target) and e == target) else 0.55
				_hit_one(e, int(float(damage) * mult), host)
		_fx_ember_nova(impact, r)
	)


func _fire_multishot(host: Node) -> void:
	## Thornspire: volley of flying thorns (no beam).
	var targets := _enemies_in_range_sorted(2)
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
			_fx_thorn_projectile(tgt.global_position)
			_hit_one(tgt, dmg, host)
		)
		i += 1


func _fire_snipe_bolt(target: Node2D, host: Node) -> void:
	## Shardbow: long crystal bolt flies to the target.
	var dmg := _execute_damage(target)
	var to := target.global_position
	_fx_shard_bolt(to, func():
		if is_instance_valid(target) and is_inside_tree():
			_hit_one(target, dmg, host)
			_fx_shard_impact(to)
	)


func _fire_mist_pulse(target: Node2D, host: Node) -> void:
	## Mistvent: vent coughs a mist cloud; damage is a soft tick (aura does the slow).
	_hit_one(target, damage, host)
	_fx_mist_vent(target.global_position)


func _fire_chain(primary: Node2D, host: Node) -> void:
	## Skyshard: lightning forks through the air (jagged arcs, no solid beam).
	var hit_list: Array[Node2D] = []
	var cur: Node2D = primary
	var dmg_f := float(damage)
	var hops := maxi(1, chain_count)
	var prev_pos := global_position + Vector2(0, -40)
	for _i in hops:
		if cur == null or not is_instance_valid(cur) or not _can_target(cur):
			break
		if cur in hit_list:
			break
		hit_list.append(cur)
		_hit_one(cur, int(dmg_f), host)
		_fx_lightning_arc(prev_pos, cur.global_position + Vector2(0, -12))
		_fx_lightning_impact(cur.global_position)
		prev_pos = cur.global_position + Vector2(0, -12)
		dmg_f *= chain_falloff
		cur = _nearest_enemy_from(cur.global_position, hit_list, 180.0)


func _fire_root_pulse(target: Node2D, host: Node) -> void:
	## Rootgate: grasping roots erupt under foes — no shot from the tower.
	var tree := get_tree()
	if tree == null:
		return
	var r := maxf(splash, 80.0)
	_fx_root_gate_pulse()
	for e in tree.get_nodes_in_group("enemies"):
		if not (e is Node2D) or not is_instance_valid(e) or not _can_target(e):
			continue
		if target.global_position.distance_to(e.global_position) <= r:
			var mult := 1.0 if e == target else 0.6
			_hit_one(e, int(float(damage) * mult), host)
			if e.has_method("apply_root"):
				e.call("apply_root", root_duration)
			if e.has_method("apply_slow"):
				e.call("apply_slow", 0.35, root_duration + 0.3)
			_fx_roots_at(e.global_position)


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


func _nearest_enemy_from(from: Vector2, exclude: Array[Node2D], max_dist: float) -> Node2D:
	var best: Node2D = null
	var best_d := max_dist * max_dist
	var tree := get_tree()
	if tree == null:
		return null
	for e in tree.get_nodes_in_group("enemies"):
		if not (e is Node2D) or not is_instance_valid(e) or not _can_target(e):
			continue
		if e in exclude:
			continue
		var d2: float = from.distance_squared_to(e.global_position)
		if d2 < best_d:
			best_d = d2
			best = e
	return best


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
		if role == "snipe" and e.has_method("is_elite") and bool(e.call("is_elite")):
			score *= 3.0
		if role == "control" and e.has_method("is_rooted") and not bool(e.call("is_rooted")):
			score *= 1.4
		if role == "aoe":
			# Prefer denser packs for splash
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


# ── Unique attack VFX ─────────────────────────────────────────────────────────

func _muzzle_origin() -> Vector2:
	return Vector2(0, -36)


func _fx_generic_spark(at: Vector2) -> void:
	if FX:
		FX.burst_particles(self, at, _def_color, 8, "spark", 0.3)


func _fx_thorn_projectile(world_to: Vector2) -> void:
	## Flying thorn spike from spire to foe.
	var origin := _muzzle_origin()
	var dest := world_to - global_position + Vector2(0, -8)
	var thorn := Polygon2D.new()
	thorn.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(3.5, 2), Vector2(0, 6), Vector2(-3.5, 2)
	])
	thorn.color = Color(0.35, 0.75, 0.4, 0.95)
	thorn.position = origin
	thorn.z_index = 25
	var ang := (dest - origin).angle() + PI * 0.5
	thorn.rotation = ang
	add_child(thorn)
	# Tiny leaf fleck trailing
	var leaf := Polygon2D.new()
	leaf.polygon = PackedVector2Array([Vector2(-2, 0), Vector2(0, -5), Vector2(2, 0)])
	leaf.color = Color(0.55, 0.9, 0.45, 0.7)
	leaf.position = Vector2(0, 4)
	thorn.add_child(leaf)
	var dist := origin.distance_to(dest)
	var dur := clampf(dist / 900.0, 0.08, 0.2)
	var tw := create_tween()
	tw.tween_property(thorn, "position", dest, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		if FX:
			FX.burst_particles(self, world_to, Color(0.4, 0.85, 0.4), 6, "spark", 0.22)
		if is_instance_valid(thorn):
			thorn.queue_free()
	)


func _fx_ember_lob(world_to: Vector2, on_land: Callable) -> void:
	## Arcing molten ball; detonates on landing.
	var origin := _muzzle_origin()
	var dest := world_to - global_position
	var ball := Node2D.new()
	ball.position = origin
	ball.z_index = 25
	add_child(ball)
	var core := FX.make_ellipse_poly(7, 7, 12, Color(1.0, 0.55, 0.15, 0.95)) if FX else Polygon2D.new()
	if core.get_parent() == null:
		core = Polygon2D.new()
		core.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(0, -6), Vector2(6, 0), Vector2(0, 6)])
		core.color = Color(1.0, 0.5, 0.15)
	ball.add_child(core)
	var glow := FX.make_ellipse_poly(12, 12, 14, Color(1.0, 0.4, 0.1, 0.35)) if FX else null
	if glow:
		ball.add_child(glow)
	var mid := origin.lerp(dest, 0.5) + Vector2(0, -70.0 - origin.distance_to(dest) * 0.08)
	var dur := clampf(origin.distance_to(dest) / 520.0, 0.22, 0.42)
	var tw := create_tween()
	tw.set_parallel(false)
	# Simple 2-segment arc
	tw.tween_property(ball, "position", mid, dur * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(ball, "position", dest, dur * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		if is_instance_valid(ball):
			ball.queue_free()
		if on_land.is_valid():
			on_land.call()
	)


func _fx_ember_nova(world_at: Vector2, radius: float) -> void:
	var local := world_at - global_position
	# Expanding fire rings
	for i in 3:
		var ring := FX.make_ellipse_poly(14 + i * 6, 9 + i * 4, 22, Color(1.0, 0.45 - i * 0.08, 0.1, 0.5 - i * 0.1)) if FX else null
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
	# Flame tongues
	for j in 6:
		var ang := TAU * float(j) / 6.0 + randf() * 0.2
		var flame := Polygon2D.new()
		flame.polygon = PackedVector2Array([
			Vector2(0, 4), Vector2(5, -8), Vector2(0, -18), Vector2(-5, -8)
		])
		flame.color = Color(1.0, 0.55, 0.15, 0.85)
		flame.position = local
		flame.rotation = ang
		flame.z_index = 19
		add_child(flame)
		var tip := local + Vector2(cos(ang), sin(ang)) * (radius * 0.35)
		var tw2 := create_tween()
		tw2.tween_property(flame, "position", tip, 0.2)
		tw2.parallel().tween_property(flame, "modulate:a", 0.0, 0.22)
		tw2.tween_callback(flame.queue_free)
	if FX:
		FX.burst_particles(self, world_at, Color(1.0, 0.5, 0.15), 16, "glow", 0.4)
		FX.burst_particles(self, world_at, Color(0.95, 0.3, 0.1), 10, "spark", 0.35)


func _fx_shard_bolt(world_to: Vector2, on_hit: Callable) -> void:
	## Long crystalline arrow.
	var origin := _muzzle_origin()
	var dest := world_to - global_position + Vector2(0, -10)
	var bolt := Node2D.new()
	bolt.position = origin
	bolt.z_index = 25
	bolt.rotation = (dest - origin).angle()
	add_child(bolt)
	var shaft := Polygon2D.new()
	shaft.polygon = PackedVector2Array([
		Vector2(-4, -3), Vector2(22, -2), Vector2(28, 0), Vector2(22, 2), Vector2(-4, 3)
	])
	shaft.color = Color(0.95, 0.88, 0.45, 0.95)
	bolt.add_child(shaft)
	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([Vector2(28, 0), Vector2(38, -5), Vector2(38, 5)])
	tip.color = Color(1.0, 0.98, 0.8, 1.0)
	bolt.add_child(tip)
	var fletch := Polygon2D.new()
	fletch.polygon = PackedVector2Array([
		Vector2(-4, 0), Vector2(-12, -7), Vector2(-8, 0), Vector2(-12, 7)
	])
	fletch.color = Color(0.85, 0.7, 0.35, 0.8)
	bolt.add_child(fletch)
	# Soft trail
	var trail := Line2D.new()
	trail.width = 3.0
	trail.default_color = Color(0.95, 0.85, 0.45, 0.35)
	trail.points = PackedVector2Array([Vector2(-8, 0), Vector2(10, 0)])
	trail.z_index = -1
	bolt.add_child(trail)
	var dist := origin.distance_to(dest)
	var dur := clampf(dist / 1400.0, 0.07, 0.16)
	var tw := create_tween()
	tw.tween_property(bolt, "position", dest, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		if is_instance_valid(bolt):
			bolt.queue_free()
		if on_hit.is_valid():
			on_hit.call()
	)


func _fx_shard_impact(world_at: Vector2) -> void:
	var local := world_at - global_position
	for i in 4:
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([Vector2(0, -6), Vector2(3, 0), Vector2(0, 4), Vector2(-3, 0)])
		shard.color = Color(0.95, 0.9, 0.5, 0.9)
		shard.position = local
		shard.rotation = randf() * TAU
		shard.z_index = 22
		add_child(shard)
		var out := local + Vector2(cos(shard.rotation), sin(shard.rotation)) * randf_range(18, 36)
		var tw := create_tween()
		tw.tween_property(shard, "position", out, 0.18)
		tw.parallel().tween_property(shard, "modulate:a", 0.0, 0.18)
		tw.tween_callback(shard.queue_free)
	if FX:
		FX.burst_particles(self, world_at, Color(0.95, 0.85, 0.4), 8, "star", 0.28)


func _fx_mist_vent(world_to: Vector2) -> void:
	## Clouds billow from the cauldron and wash toward the target.
	var origin := _muzzle_origin() + Vector2(0, 8)
	for i in 4:
		var puff := FX.make_ellipse_poly(10 + i * 3, 8 + i * 2, 16, Color(0.6, 0.4, 0.9, 0.35 - i * 0.04)) if FX else null
		if puff == null:
			continue
		puff.position = origin + Vector2(randf_range(-6, 6), randf_range(-4, 4))
		puff.z_index = 20
		puff.scale = Vector2(0.4, 0.4)
		add_child(puff)
		var dest := (world_to - global_position).lerp(origin, 0.15) + Vector2(randf_range(-20, 20), randf_range(-12, 12))
		var tw := create_tween()
		tw.tween_property(puff, "position", dest, 0.35 + i * 0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(puff, "scale", Vector2(1.6 + i * 0.2, 1.2 + i * 0.15), 0.4)
		tw.parallel().tween_property(puff, "modulate:a", 0.0, 0.45)
		tw.tween_callback(puff.queue_free)
	# Soft mist bloom on the target
	var bloom := FX.make_ellipse_poly(28, 18, 20, Color(0.65, 0.45, 0.95, 0.28)) if FX else null
	if bloom:
		bloom.position = world_to - global_position
		bloom.z_index = 18
		bloom.scale = Vector2(0.4, 0.4)
		add_child(bloom)
		var twb := create_tween()
		twb.tween_property(bloom, "scale", Vector2(1.5, 1.1), 0.35)
		twb.parallel().tween_property(bloom, "modulate:a", 0.0, 0.4)
		twb.tween_callback(bloom.queue_free)
	if FX:
		FX.burst_particles(self, global_position + origin, Color(0.65, 0.45, 0.95), 8, "glow", 0.4)


func _fx_lightning_arc(from_world: Vector2, to_world: Vector2) -> void:
	## Jagged forked lightning (not a straight beam).
	var a := from_world - global_position
	var b := to_world - global_position
	var pts := PackedVector2Array()
	pts.append(a)
	var segs := 5
	for i in range(1, segs):
		var t := float(i) / float(segs)
		var p := a.lerp(b, t)
		var perp := Vector2(-(b.y - a.y), b.x - a.x).normalized()
		if perp.length_squared() < 0.01:
			perp = Vector2.RIGHT
		p += perp * randf_range(-14.0, 14.0) * (1.0 - absf(t - 0.5) * 0.5)
		pts.append(p)
	pts.append(b)
	# Outer glow
	var glow := Line2D.new()
	glow.width = 7.0
	glow.default_color = Color(0.55, 0.9, 1.0, 0.35)
	glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	glow.joint_mode = Line2D.LINE_JOINT_ROUND
	glow.antialiased = true
	glow.points = pts
	glow.z_index = 21
	add_child(glow)
	# Core bolt
	var core := Line2D.new()
	core.width = 2.2
	core.default_color = Color(0.9, 0.98, 1.0, 0.95)
	core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	core.end_cap_mode = Line2D.LINE_CAP_ROUND
	core.joint_mode = Line2D.LINE_JOINT_ROUND
	core.antialiased = true
	core.points = pts
	core.z_index = 22
	add_child(core)
	# Brief fork branch
	if pts.size() > 3:
		var mid: Vector2 = pts[pts.size() / 2]
		var fork := Line2D.new()
		fork.width = 1.5
		fork.default_color = Color(0.7, 0.95, 1.0, 0.7)
		fork.points = PackedVector2Array([
			mid, mid + Vector2(randf_range(-20, 20), randf_range(-18, 8))
		])
		fork.z_index = 22
		add_child(fork)
		var twf := create_tween()
		twf.tween_property(fork, "modulate:a", 0.0, 0.12)
		twf.tween_callback(fork.queue_free)
	var tw := create_tween()
	tw.tween_property(glow, "modulate:a", 0.0, 0.16)
	tw.parallel().tween_property(core, "modulate:a", 0.0, 0.14)
	tw.tween_callback(func():
		if is_instance_valid(glow):
			glow.queue_free()
		if is_instance_valid(core):
			core.queue_free()
	)


func _fx_lightning_impact(world_at: Vector2) -> void:
	var local := world_at - global_position
	var flash := FX.make_ellipse_poly(10, 10, 12, Color(0.8, 0.95, 1.0, 0.7)) if FX else null
	if flash:
		flash.position = local + Vector2(0, -10)
		flash.z_index = 23
		add_child(flash)
		var tw := create_tween()
		tw.tween_property(flash, "scale", Vector2(2.2, 2.2), 0.12)
		tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.14)
		tw.tween_callback(flash.queue_free)
	if FX:
		FX.burst_particles(self, world_at, Color(0.7, 0.95, 1.0), 6, "star", 0.25)


func _fx_root_gate_pulse() -> void:
	## Gate shudders — roots at base twitch.
	if _visual:
		var tw := create_tween()
		tw.tween_property(_visual, "scale", Vector2.ONE * _level_scale() * 1.06, 0.06)
		tw.tween_property(_visual, "scale", Vector2.ONE * _level_scale(), 0.12)
	var base := Vector2(0, 6)
	for sx in [-1.0, 1.0]:
		var vine := Line2D.new()
		vine.width = 3.0
		vine.default_color = Color(0.35, 0.55, 0.28, 0.85)
		vine.points = PackedVector2Array([
			base, base + Vector2(sx * 18, -8), base + Vector2(sx * 28, 4)
		])
		vine.z_index = 15
		add_child(vine)
		var tw2 := create_tween()
		tw2.tween_property(vine, "modulate:a", 0.0, 0.35)
		tw2.tween_callback(vine.queue_free)


func _fx_roots_at(world_at: Vector2) -> void:
	## Grasping roots erupt under the enemy.
	var local := world_at - global_position
	var soil := FX.make_ellipse_poly(16, 9, 14, Color(0.2, 0.28, 0.14, 0.45)) if FX else null
	if soil:
		soil.position = local + Vector2(0, 6)
		soil.z_index = 16
		soil.scale = Vector2(0.3, 0.3)
		add_child(soil)
		var tws := create_tween()
		tws.tween_property(soil, "scale", Vector2(1.4, 1.0), 0.2)
		tws.parallel().tween_property(soil, "modulate:a", 0.0, 0.45)
		tws.tween_callback(soil.queue_free)
	for i in 5:
		var ang := -0.6 + float(i) * 0.3 + randf_range(-0.1, 0.1)
		var root := Line2D.new()
		root.width = 2.8
		root.default_color = Color(0.38, 0.55, 0.28, 0.95)
		root.begin_cap_mode = Line2D.LINE_CAP_ROUND
		root.end_cap_mode = Line2D.LINE_CAP_ROUND
		var tip := Vector2(sin(ang) * 22.0, -8.0 - float(i) * 5.0)
		root.points = PackedVector2Array([
			Vector2.ZERO,
			Vector2(sin(ang) * 8.0, -2.0),
			tip
		])
		root.position = local + Vector2(0, 8)
		root.z_index = 17
		root.scale = Vector2(0.2, 0.2)
		add_child(root)
		var tw := create_tween()
		tw.tween_property(root, "scale", Vector2.ONE, 0.14 + float(i) * 0.02).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.15)
		tw.tween_property(root, "modulate:a", 0.0, 0.25)
		tw.tween_callback(root.queue_free)
	if FX:
		FX.burst_particles(self, world_at, Color(0.4, 0.65, 0.3), 8, "spark", 0.3)
