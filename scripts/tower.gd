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
	# Full visual rebuild so each level looks larger & more ornate
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
	## Noticeable growth each upgrade.
	match level:
		1:
			return 1.0
		2:
			return 1.28
		_:
			return 1.58


func _apply_level_look() -> void:
	if _level_label:
		_level_label.text = "Lv%d" % level
	if _visual:
		_visual.scale = Vector2.ONE * _level_scale()
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
		"root":
			_build_rootgate()
		"chain":
			_build_skyshard()
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
	_level_label.position = Vector2(-14, 16)
	_level_label.add_theme_font_size_override("font_size", 11 + mini(level - 1, 2) * 2)
	_level_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	_level_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_level_label.add_theme_constant_override("outline_size", 3)
	_level_label.visible = false
	_visual.add_child(_level_label)

	_visual.scale = Vector2.ONE * _level_scale()
	_add_level_ornaments()


func _add_level_ornaments() -> void:
	## Extra geometry/glow so upgrades read as bigger & more complex.
	if _visual == null or level < 2:
		return
	# Wider plinth ring
	var plinth := FX.make_ellipse_poly(22.0 + level * 4.0, 12.0 + level * 2.0, 24, Color(0.2, 0.18, 0.22, 0.55))
	plinth.position = Vector2(0, 10)
	plinth.z_index = -1
	_visual.add_child(plinth)
	# Orbiting crystal flecks
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
		# Apex crown / spire cluster
		var crown := Polygon2D.new()
		crown.polygon = PackedVector2Array([
			Vector2(0, -78), Vector2(10, -58), Vector2(4, -52), Vector2(0, -62),
			Vector2(-4, -52), Vector2(-10, -58)
		])
		crown.color = Color(0.95, 0.85, 0.5, 0.95)
		_visual.add_child(crown)
		var halo := FX.make_ellipse_poly(26, 14, 20, Color(_def_color.r, _def_color.g, _def_color.b, 0.2))
		halo.position = Vector2(0, -48)
		halo.z_index = -1
		_visual.add_child(halo)
		# Side buttresses
		for sx in [-1.0, 1.0]:
			var butt := Polygon2D.new()
			butt.polygon = PackedVector2Array([
				Vector2(0, 8), Vector2(sx * 16, 6), Vector2(sx * 10, -30), Vector2(sx * 2, -18)
			])
			butt.color = _def_color.darkened(0.15)
			_visual.add_child(butt)


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


## DPS — briar spire bristling with thorns (reads as rapid fire).
func _build_thornspire() -> void:
	_add_plinth(20.0 + level * 2, 11.0)
	var trunk := Polygon2D.new()
	trunk.polygon = PackedVector2Array([
		Vector2(-10, 10), Vector2(10, 10), Vector2(7, -28), Vector2(-7, -28)
	])
	trunk.color = Color(0.32, 0.2, 0.12)
	_visual.add_child(trunk)
	var h := 58.0 + (level - 1) * 14.0
	var w := 16.0 + (level - 1) * 4.0
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(0, -h), Vector2(w, -h * 0.7), Vector2(w * 0.7, -h * 0.25),
		Vector2(0, -h * 0.15), Vector2(-w * 0.7, -h * 0.25), Vector2(-w, -h * 0.7)
	])
	_body.color = _def_color
	_visual.add_child(_body)
	# Dense thorn ring — visual "swarm DPS"
	for i in (6 + level * 2):
		var ang := TAU * float(i) / float(6 + level * 2)
		var thorn := Polygon2D.new()
		var len := 12.0 + level * 3.0
		thorn.polygon = PackedVector2Array([
			Vector2(0, 0), Vector2(3, -len * 0.4), Vector2(0, -len), Vector2(-3, -len * 0.4)
		])
		thorn.color = _def_color.lightened(0.15) if i % 2 == 0 else _def_color.darkened(0.1)
		thorn.position = Vector2(cos(ang), sin(ang) * 0.7) * (14.0 + level * 2.0) + Vector2(0, -h * 0.45)
		thorn.rotation = ang + PI * 0.5
		_visual.add_child(thorn)
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([
		Vector2(0, -h - 4), Vector2(6, -h * 0.85), Vector2(0, -h * 0.75), Vector2(-6, -h * 0.85)
	])
	_accent.color = Color(0.95, 0.85, 0.4)
	_visual.add_child(_accent)


## SNIPE — tall crystal bow with nocked bolt (reads as long-range).
func _build_shardbow() -> void:
	_add_plinth(16.0, 9.0)
	var h := 62.0 + (level - 1) * 14.0
	# Tall post
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-5, 8), Vector2(5, 8), Vector2(3, -h * 0.85), Vector2(-3, -h * 0.85)
	])
	_body.color = Color(0.45, 0.4, 0.38)
	_visual.add_child(_body)
	# Bow limbs (wide C silhouette = range)
	var bow_w := 26.0 + level * 6.0
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([
		Vector2(-bow_w, -h * 0.55), Vector2(-bow_w * 0.4, -h * 0.95), Vector2(0, -h - 6),
		Vector2(bow_w * 0.4, -h * 0.95), Vector2(bow_w, -h * 0.55),
		Vector2(bow_w * 0.55, -h * 0.5), Vector2(0, -h * 0.72), Vector2(-bow_w * 0.55, -h * 0.5)
	])
	_accent.color = _def_color
	_visual.add_child(_accent)
	# String
	var string_line := Line2D.new()
	string_line.width = 1.8
	string_line.default_color = Color(0.98, 0.92, 0.7, 0.85)
	string_line.points = PackedVector2Array([Vector2(-bow_w * 0.9, -h * 0.55), Vector2(bow_w * 0.9, -h * 0.55)])
	_visual.add_child(string_line)
	# Drawn bolt (long = snipe)
	var bolt := Polygon2D.new()
	bolt.polygon = PackedVector2Array([
		Vector2(0, -h - 20 - level * 4), Vector2(3, -h * 0.55), Vector2(0, -h * 0.5), Vector2(-3, -h * 0.55)
	])
	bolt.color = Color(0.95, 0.9, 0.55)
	_visual.add_child(bolt)
	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([
		Vector2(0, -h - 28 - level * 4), Vector2(5, -h - 16 - level * 2), Vector2(-5, -h - 16 - level * 2)
	])
	tip.color = Color(1.0, 0.95, 0.7)
	_visual.add_child(tip)


## SLOW — cauldron vent with heavy mist plume.
func _build_mistvent() -> void:
	_add_plinth(24.0 + level * 2, 13.0)
	# Bowl / cauldron
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-20 - level * 2, 6), Vector2(20 + level * 2, 6),
		Vector2(16, -8), Vector2(10, -18), Vector2(-10, -18), Vector2(-16, -8)
	])
	_body.color = Color(0.28, 0.18, 0.35)
	_visual.add_child(_body)
	var rim := FX.make_ellipse_poly(18 + level * 2, 7, 20, Color(0.45, 0.3, 0.55, 0.9))
	rim.position = Vector2(0, -16)
	_visual.add_child(rim)
	# Rising mist column (reads as aura slow)
	_accent = FX.make_ellipse_poly(16 + level * 3, 28 + level * 8, 22, Color(_def_color.r, _def_color.g, _def_color.b, 0.4))
	_accent.position = Vector2(0, -36 - level * 4)
	_visual.add_child(_accent)
	for i in (3 + level):
		var puff := FX.make_ellipse_poly(12 + i * 2, 10 + i, 14, Color(0.65, 0.45, 0.95, 0.18 - i * 0.02))
		puff.position = Vector2((i - 1.5) * 8.0, -48 - i * 10)
		_visual.add_child(puff)
	var mist_pool := FX.make_ellipse_poly(minf(70.0, fire_range * 0.22), minf(42.0, fire_range * 0.14), 28, Color(0.55, 0.35, 0.9, 0.12))
	mist_pool.z_index = -1
	mist_pool.name = "MistAura"
	_visual.add_child(mist_pool)


## MARK — hanging lantern with witch-glow runes.
func _build_hex() -> void:
	_add_plinth(14.0, 8.0)
	var pole_h := 48.0 + level * 10.0
	var pole := Polygon2D.new()
	pole.polygon = PackedVector2Array([
		Vector2(-3, 10), Vector2(3, 10), Vector2(2.5, -pole_h), Vector2(-2.5, -pole_h)
	])
	pole.color = Color(0.25, 0.2, 0.3)
	_visual.add_child(pole)
	# Lantern body (hex silhouette)
	var h := 28.0 + level * 4.0
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(0, -pole_h - h), Vector2(12 + level, -pole_h - h * 0.65),
		Vector2(10, -pole_h - h * 0.2), Vector2(0, -pole_h),
		Vector2(-10, -pole_h - h * 0.2), Vector2(-(12 + level), -pole_h - h * 0.65)
	])
	_body.color = _def_color
	_visual.add_child(_body)
	# Bright core flame
	_accent = FX.make_ellipse_poly(5 + level, 7 + level, 12, Color(1.0, 0.92, 0.55, 0.95))
	_accent.position = Vector2(0, -pole_h - h * 0.55)
	_visual.add_child(_accent)
	# Orbiting mark runes
	for i in (3 + level):
		var ang := TAU * float(i) / float(3 + level)
		var rune := Polygon2D.new()
		rune.polygon = PackedVector2Array([
			Vector2(0, -5), Vector2(4, 0), Vector2(0, 5), Vector2(-4, 0)
		])
		rune.color = Color(1.0, 0.85, 0.5, 0.85)
		rune.position = Vector2(cos(ang), sin(ang)) * (18.0 + level * 3.0) + Vector2(0, -pole_h - h * 0.45)
		_visual.add_child(rune)
	# Chain to lantern
	var chain := Line2D.new()
	chain.width = 1.5
	chain.default_color = Color(0.6, 0.55, 0.7, 0.8)
	chain.points = PackedVector2Array([Vector2(0, -pole_h + 4), Vector2(0, -pole_h - 4)])
	_visual.add_child(chain)


## BUFF — hearth with warm flames radiating outward.
func _build_hearth() -> void:
	_add_plinth(22.0 + level * 2, 12.0)
	# Stone hearth
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-22 - level * 2, 10), Vector2(22 + level * 2, 10),
		Vector2(18, -6), Vector2(12, -22 - level * 4), Vector2(-12, -22 - level * 4), Vector2(-18, -6)
	])
	_body.color = Color(0.38, 0.26, 0.2)
	_visual.add_child(_body)
	# Warmth aura disc
	var warmth := FX.make_ellipse_poly(minf(72.0, fire_range * 0.22), minf(44.0, fire_range * 0.14), 28, Color(1.0, 0.55, 0.25, 0.12))
	warmth.z_index = -1
	_visual.add_child(warmth)
	# Layered flames (reads as buff/heat)
	for i in (2 + level):
		var flame := Polygon2D.new()
		var fh := 22.0 + i * 8.0 + level * 4.0
		flame.polygon = PackedVector2Array([
			Vector2(-6 + i, -8), Vector2(0, -fh - 12), Vector2(6 - i, -8), Vector2(0, -16)
		])
		flame.color = Color(1.0, 0.55 + i * 0.1, 0.2, 0.85 - i * 0.1)
		flame.position = Vector2((i - 1) * 5.0, -18)
		_visual.add_child(flame)
	_accent = FX.make_ellipse_poly(10 + level * 2, 8 + level, 14, Color(1.0, 0.85, 0.4, 0.9))
	_accent.position = Vector2(0, -20 - level * 2)
	_visual.add_child(_accent)
	# Ember sparks
	for i in 4:
		var e := FX.make_ellipse_poly(2, 2, 6, Color(1.0, 0.7, 0.3, 0.7))
		e.position = Vector2(randf_range(-14, 14), randf_range(-40, -18))
		_visual.add_child(e)


## PULSE — bone horn howler (radial shockwave read).
func _build_bonehowl() -> void:
	_add_plinth(18.0, 10.0)
	var h := 54.0 + (level - 1) * 12.0
	# Skull body
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(0, -h), Vector2(14, -h * 0.55), Vector2(12, -h * 0.2),
		Vector2(8, 8), Vector2(-8, 8), Vector2(-12, -h * 0.2), Vector2(-14, -h * 0.55)
	])
	_body.color = Color(0.9, 0.86, 0.82)
	_visual.add_child(_body)
	# Eye sockets
	for sx in [-1.0, 1.0]:
		var eye := FX.make_ellipse_poly(3.5, 4.0, 10, Color(0.55, 0.7, 0.95, 0.9))
		eye.position = Vector2(sx * 6, -h * 0.55)
		_visual.add_child(eye)
	# Huge horns (howl / pulse)
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([
		Vector2(-8, -h * 0.7), Vector2(-22 - level * 4, -h - 8), Vector2(-4, -h * 0.5)
	])
	_accent.color = _def_color
	_visual.add_child(_accent)
	var horn2 := _accent.duplicate() as Polygon2D
	horn2.scale.x = -1
	_visual.add_child(horn2)
	# Concentric pulse rings at base
	for i in (2 + mini(level, 2)):
		var ring := FX.make_ellipse_poly(20 + i * 10, 12 + i * 5, 20, Color(_def_color.r, _def_color.g, _def_color.b, 0.12 - i * 0.02))
		ring.position = Vector2(0, 4)
		ring.z_index = -1
		_visual.add_child(ring)
	if level >= 2:
		var jaw := Polygon2D.new()
		jaw.polygon = PackedVector2Array([
			Vector2(-10, -h * 0.25), Vector2(10, -h * 0.25), Vector2(8, 2), Vector2(-8, 2)
		])
		jaw.color = Color(0.78, 0.74, 0.72)
		_visual.add_child(jaw)


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
		_:
			if splash > 0.0:
				_fire_splash(target, host)
			else:
				_hit_one(target, damage, host)
				_muzzle_flash(target.global_position)

	if role == "mark" and is_instance_valid(target) and target.has_method("apply_mark"):
		target.call("apply_mark", mark_mult, 3.0)


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
	return dmg


func _hit_one(target: Node2D, dmg: int, host: Node) -> void:
	if target == null or not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	# Preview matchup for floating text color (actual mult applied once in take_damage)
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
		if target.has_method("is_marked") and bool(target.call("is_marked")):
			shown = int(float(dmg) * 1.35)
		target.call("take_damage", shown)
	FloatingText.spawn(host, target.global_position + Vector2(0, -16), str(maxi(1, shown)), txt_col)


func _fire_splash(target: Node2D, host: Node) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for e in tree.get_nodes_in_group("enemies"):
		if not (e is Node2D) or not is_instance_valid(e):
			continue
		if target.global_position.distance_to(e.global_position) <= splash:
			var mult := 1.0 if e == target else 0.55
			_hit_one(e, int(float(damage) * mult), host)
	_muzzle_flash(target.global_position)


func _fire_multishot(host: Node) -> void:
	## Thornspire: hit up to 2 nearest enemies in range.
	var targets := _enemies_in_range_sorted(2)
	for t in targets:
		_hit_one(t, damage, host)
		_muzzle_flash(t.global_position)


func _fire_chain(primary: Node2D, host: Node) -> void:
	## Skyshard: bolt leaps to nearby foes.
	var hit_list: Array[Node2D] = []
	var cur: Node2D = primary
	var dmg_f := float(damage)
	var hops := maxi(1, chain_count)
	for _i in hops:
		if cur == null or not is_instance_valid(cur):
			break
		if cur in hit_list:
			break
		hit_list.append(cur)
		_hit_one(cur, int(dmg_f), host)
		_muzzle_flash(cur.global_position)
		dmg_f *= chain_falloff
		cur = _nearest_enemy_from(cur.global_position, hit_list, 160.0)
	# Draw chain arcs between hits
	for i in range(hit_list.size() - 1):
		_chain_arc(hit_list[i].global_position, hit_list[i + 1].global_position)


func _fire_root_pulse(target: Node2D, host: Node) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var r := maxf(splash, 70.0)
	for e in tree.get_nodes_in_group("enemies"):
		if not (e is Node2D) or not is_instance_valid(e):
			continue
		if target.global_position.distance_to(e.global_position) <= r:
			var mult := 1.0 if e == target else 0.6
			_hit_one(e, int(float(damage) * mult), host)
			if e.has_method("apply_root"):
				e.call("apply_root", root_duration)
			if e.has_method("apply_slow"):
				e.call("apply_slow", 0.35, root_duration + 0.3)
	_muzzle_flash(target.global_position)


func _enemies_in_range_sorted(limit: int) -> Array[Node2D]:
	var out: Array[Node2D] = []
	var tree := get_tree()
	if tree == null:
		return out
	var scored: Array = []
	var r2 := fire_range * fire_range
	for e in tree.get_nodes_in_group("enemies"):
		if not (e is Node2D) or not is_instance_valid(e):
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
		if not (e is Node2D) or not is_instance_valid(e):
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
		if not (e is Node2D) or not is_instance_valid(e):
			continue
		var d2: float = global_position.distance_squared_to(e.global_position)
		if d2 > r2:
			continue
		var to_crystal: float = e.global_position.distance_to(crystal_pos)
		var score := 10000.0 / maxf(40.0, to_crystal) + 200.0 / maxf(20.0, sqrt(d2))
		if role == "snipe" and e.has_method("is_elite") and bool(e.call("is_elite")):
			score *= 3.0
		if role == "root" and e.has_method("is_rooted") and not bool(e.call("is_rooted")):
			score *= 1.4  # prefer free-moving packs
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


## ROOT — arched root gate binding the path (reads as snare).
func _build_rootgate() -> void:
	_add_plinth(24.0 + level * 2, 12.0)
	var h := 50.0 + level * 10.0
	# Arch of roots
	for sx in [-1.0, 1.0]:
		var pillar := Polygon2D.new()
		pillar.polygon = PackedVector2Array([
			Vector2(sx * 8, 8), Vector2(sx * 18, 6), Vector2(sx * 16, -h * 0.55),
			Vector2(sx * 6, -h * 0.85), Vector2(sx * 4, -h * 0.4)
		])
		pillar.color = Color(0.32, 0.42, 0.24)
		_visual.add_child(pillar)
	# Keystone / crown root
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(-14, -h * 0.75), Vector2(0, -h - 8), Vector2(14, -h * 0.75),
		Vector2(8, -h * 0.55), Vector2(0, -h * 0.65), Vector2(-8, -h * 0.55)
	])
	_body.color = Color(0.38, 0.52, 0.28)
	_visual.add_child(_body)
	# Grasping roots spreading outward (snare read)
	_accent = Polygon2D.new()
	_accent.polygon = PackedVector2Array([
		Vector2(-6, 4), Vector2(-28 - level * 4, 2), Vector2(-20, -8), Vector2(-4, -2)
	])
	_accent.color = _def_color
	_visual.add_child(_accent)
	var root2 := _accent.duplicate() as Polygon2D
	root2.scale.x = -1
	_visual.add_child(root2)
	for i in (3 + level):
		var vine := Line2D.new()
		vine.width = 2.2
		vine.default_color = Color(0.3, 0.55, 0.28, 0.8)
		var a := -0.4 + float(i) * 0.35
		vine.points = PackedVector2Array([
			Vector2(sin(a) * 4, 2), Vector2(sin(a) * 22, -16 - i * 6)
		])
		_visual.add_child(vine)
	# Binding circle
	var bind := FX.make_ellipse_poly(32 + level * 4, 18 + level * 2, 24, Color(0.35, 0.6, 0.3, 0.14))
	bind.position = Vector2(0, 2)
	bind.z_index = -1
	_visual.add_child(bind)


## CHAIN — floating skyshard constellation (reads as leaping lightning).
func _build_skyshard() -> void:
	_add_plinth(16.0, 9.0)
	var h := 56.0 + level * 10.0
	# Central crystal column
	_body = Polygon2D.new()
	_body.polygon = PackedVector2Array([
		Vector2(0, -h), Vector2(11, -h * 0.55), Vector2(5, 6), Vector2(-5, 6), Vector2(-11, -h * 0.55)
	])
	_body.color = Color(0.5, 0.9, 0.98)
	_visual.add_child(_body)
	var facet := Polygon2D.new()
	facet.polygon = PackedVector2Array([
		Vector2(-3, -h * 0.9), Vector2(4, -h * 0.7), Vector2(0, -h * 0.4)
	])
	facet.color = Color(0.85, 0.98, 1.0, 0.85)
	_visual.add_child(facet)
	_accent = FX.make_ellipse_poly(9 + level * 2, 9 + level * 2, 14, Color(0.95, 0.98, 1.0, 0.8))
	_accent.position = Vector2(0, -h * 0.72)
	_visual.add_child(_accent)
	# Orbiting shards linked by faint arcs (chain read)
	var n := 3 + level
	var pts: Array[Vector2] = []
	for i in n:
		var ang := TAU * float(i) / float(n) - PI * 0.5
		var p := Vector2(cos(ang), sin(ang) * 0.7) * (24.0 + level * 5.0) + Vector2(0, -h * 0.45)
		pts.append(p)
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([
			Vector2(0, -9), Vector2(5, 0), Vector2(0, 5), Vector2(-5, 0)
		])
		shard.color = Color(0.65, 0.95, 1.0, 0.9)
		shard.position = p
		_visual.add_child(shard)
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var arc := Line2D.new()
		arc.width = 1.5
		arc.default_color = Color(0.6, 0.9, 1.0, 0.45)
		arc.points = PackedVector2Array([a, b])
		_visual.add_child(arc)
