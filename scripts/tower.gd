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

	match special:
		"multishot":
			_fire_multishot(host)
		"chain":
			_fire_chain(target, host)
		"execute":
			_hit_one(target, _execute_damage(target), host)
			_muzzle_flash(target.global_position)
		"root":
			_fire_root_pulse(target, host)
		"splash":
			_fire_splash(target, host)
		"slow_aura":
			# Light tick damage on nearest + aura handles slow
			_hit_one(target, damage, host)
			_muzzle_flash(target.global_position)
		_:
			if splash > 0.0:
				_fire_splash(target, host)
			else:
				_hit_one(target, damage, host)
				_muzzle_flash(target.global_position)


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
	var tree := get_tree()
	if tree == null:
		return
	var r := maxf(splash, 80.0)
	for e in tree.get_nodes_in_group("enemies"):
		if not (e is Node2D) or not is_instance_valid(e) or not _can_target(e):
			continue
		if target.global_position.distance_to(e.global_position) <= r:
			var mult := 1.0 if e == target else 0.55
			_hit_one(e, int(float(damage) * mult), host)
	_muzzle_flash(target.global_position)
	_splash_fx(target.global_position, r)


func _splash_fx(at: Vector2, radius: float) -> void:
	var ring := FX.make_ellipse_poly(radius * 0.35, radius * 0.22, 24, Color(_def_color.r, _def_color.g, _def_color.b, 0.45))
	ring.position = at - global_position
	ring.z_index = 15
	add_child(ring)
	var tw := create_tween()
	tw.tween_property(ring, "scale", Vector2(2.2, 2.2), 0.22)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.22)
	tw.tween_callback(ring.queue_free)
	if FX:
		FX.burst_particles(self, at, _def_color, 10, "glow", 0.35)


func _fire_multishot(host: Node) -> void:
	var targets := _enemies_in_range_sorted(2)
	for t in targets:
		_hit_one(t, damage, host)
		_muzzle_flash(t.global_position)


func _fire_chain(primary: Node2D, host: Node) -> void:
	var hit_list: Array[Node2D] = []
	var cur: Node2D = primary
	var dmg_f := float(damage)
	var hops := maxi(1, chain_count)
	for _i in hops:
		if cur == null or not is_instance_valid(cur) or not _can_target(cur):
			break
		if cur in hit_list:
			break
		hit_list.append(cur)
		_hit_one(cur, int(dmg_f), host)
		_muzzle_flash(cur.global_position)
		dmg_f *= chain_falloff
		cur = _nearest_enemy_from(cur.global_position, hit_list, 180.0)
	for i in range(hit_list.size() - 1):
		_chain_arc(hit_list[i].global_position, hit_list[i + 1].global_position)


func _fire_root_pulse(target: Node2D, host: Node) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var r := maxf(splash, 80.0)
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
	_muzzle_flash(target.global_position)
	_splash_fx(target.global_position, r * 0.8)


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


func _chain_arc(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.width = 2.5
	line.default_color = Color(_def_color.r, _def_color.g, _def_color.b, 0.85)
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.points = PackedVector2Array([from - global_position, to - global_position])
	line.z_index = 20
	add_child(line)
	var tw := create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.18)
	tw.tween_callback(line.queue_free)
