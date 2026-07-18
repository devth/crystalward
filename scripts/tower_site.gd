extends Area2D
## Build pad: cycle tower type, build, upgrade, sell (KR + multi-type).
## Labels / type swatches only when a player is near — keeps the map readable.

enum State { EMPTY, QUEUED, BUILT }

@export var tower_scene: PackedScene

var state: State = State.EMPTY
var _queue_left: float = 0.0
var _tower: Node2D = null
var _queued_type: String = "arrow"
var _preview_type: String = "arrow"
var _last_builder: int = 0
var _platform: Node2D
var _range_preview: Polygon2D
var _type_swatch: Polygon2D
var _crystal_ornament: Node2D
var _players_near: int = 0

@onready var _bar: ProgressBar = $Progress
@onready var _label: Label = $Label
@onready var _tower_slot: Node2D = $TowerSlot


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 8
	collision_mask = 2
	if has_node("Pad"):
		$Pad.visible = false
	if tower_scene == null:
		tower_scene = load("res://scenes/tower.tscn") as PackedScene
	_build_visuals()
	FX.style_progress_bar(_bar, Color(0.55, 0.85, 0.45), Color(0.1, 0.08, 0.06, 0.85))
	_bar.visible = false
	_bar.position = Vector2(-30, -56)
	_bar.size = Vector2(60, 9)
	if VisualStyle:
		VisualStyle.style_game_label(_label, 11, true)
	_label.position = Vector2(-70, 28)
	_label.visible = false
	_refresh_label()
	_update_presence_visuals()
	z_as_relative = false
	if VisualStyle:
		z_index = maxi(0, VisualStyle.actor_z(global_position.y) - 5)
	else:
		z_index = clampi(45 + int(global_position.y) + 2000, 0, 4000)
	add_to_group("tower_sites")


func can_sell() -> bool:
	return state == State.BUILT and _tower != null


func _build_visuals() -> void:
	if VisualStyle:
		VisualStyle.make_blob_shadow(self, 42, 20, 12)
	_platform = Node2D.new()
	add_child(_platform)
	# Large ethereal plinth — Astronomist stone + crystal light
	var outer := FX.make_ellipse_poly(48, 26, 32, Color(0.14, 0.11, 0.22, 0.9))
	_platform.add_child(outer)
	var ring := FX.make_ellipse_poly(40, 21, 30, Color(0.42, 0.55, 0.62, 0.28))
	_platform.add_child(ring)
	var mid := FX.make_ellipse_poly(32, 17, 28, Color(0.30, 0.24, 0.42, 0.84))
	_platform.add_child(mid)
	var glow := FX.make_ellipse_poly(20, 11, 20, Color(0.58, 0.48, 0.85, 0.34))
	_platform.add_child(glow)
	var inner := FX.make_ellipse_poly(12, 7, 16, Color(0.88, 0.78, 0.52, 0.42))
	_platform.add_child(inner)
	# Dashed-feel spokes so empty pads read as “build here”
	for i in 6:
		var ang := TAU * float(i) / 6.0
		var spoke := Polygon2D.new()
		spoke.polygon = PackedVector2Array([
			Vector2(-2, 0), Vector2(2, 0), Vector2(1.5, -10), Vector2(-1.5, -10)
		])
		spoke.color = Color(0.62, 0.72, 0.88, 0.42)
		spoke.position = Vector2(cos(ang), sin(ang) * 0.65) * 28.0
		spoke.rotation = ang + PI * 0.5
		_platform.add_child(spoke)
	_crystal_ornament = Node2D.new()
	_platform.add_child(_crystal_ornament)
	for i in 3:
		var shard := Polygon2D.new()
		var ang := -0.6 + i * 0.6
		var h := 18.0 + i * 4.0
		shard.polygon = PackedVector2Array([
			Vector2(0, -h), Vector2(5, -h * 0.4), Vector2(2.5, 3), Vector2(-2.5, 3), Vector2(-5, -h * 0.4)
		])
		# Teal / amethyst / amber crystal shards
		var scols := [
			Color(0.48, 0.78, 0.72, 0.88),
			Color(0.68, 0.52, 0.88, 0.9),
			Color(0.90, 0.78, 0.48, 0.88),
		]
		shard.color = scols[i]
		shard.position = Vector2(sin(ang) * 12.0, -8)
		shard.rotation = ang * 0.35
		_crystal_ornament.add_child(shard)
	_type_swatch = FX.make_ellipse_poly(10, 6, 14, Color(0.5, 0.85, 0.5, 0.95))
	_type_swatch.position = Vector2(0, 6)
	_type_swatch.visible = false
	_platform.add_child(_type_swatch)
	_range_preview = FX.make_ellipse_poly(100, 72, 48, Color(0.3, 0.85, 0.4, 0.14))
	_range_preview.z_index = -2
	_range_preview.visible = false
	add_child(_range_preview)
	_sync_swatch()


func _sync_swatch() -> void:
	if _type_swatch and TowerTypes:
		var id := _preview_type if state == State.EMPTY else _queued_type
		var d: Dictionary = TowerTypes.def_for(id)
		_type_swatch.color = d.get("color", Color.WHITE)
		if _range_preview and state == State.EMPTY:
			var r: float = float(d.get("range", 340.0))
			_range_preview.color = Color(
				d.get("color", Color.GREEN).r,
				d.get("color", Color.GREEN).g,
				d.get("color", Color.GREEN).b,
				0.14
			)
			_range_preview.scale = Vector2.ONE * (r / 100.0)


func _refresh_label() -> void:
	if _label == null:
		return
	if TowerTypes == null:
		_label.text = "Build"
	else:
		match state:
			State.EMPTY:
				var d: Dictionary = TowerTypes.def_for(_preview_type)
				var n := TowerTypes.unlocked_count()
				var cap := TowerTypes.max_level_for(_preview_type) if TowerTypes.has_method("max_level_for") else 1
				_label.text = "%s %d✦  Z/X · %d  (max Lv%d)" % [d.get("name"), d.get("cost"), n, cap]
			State.QUEUED:
				_label.text = "Building %s..." % TowerTypes.def_for(_queued_type).get("name")
			State.BUILT:
				if _tower and _tower.get("level") != null:
					var lv: int = int(_tower.level)
					var tid := str(_tower.get("type_id"))
					var cap := TowerTypes.max_level_for(tid) if TowerTypes.has_method("max_level_for") else GameState.TOWER_MAX_LEVEL
					if lv >= cap:
						_label.text = "Max Lv%d · E sell" % cap
					else:
						_label.text = "Q →Lv%d · E sell" % (lv + 1)
				else:
					_label.text = "Online"
	_sync_swatch()
	_update_presence_visuals()


func _update_presence_visuals() -> void:
	var near := _players_near > 0
	# Show prompts only when interacting
	if _label:
		if state == State.QUEUED:
			_label.visible = true
		else:
			_label.visible = near
	if _type_swatch:
		_type_swatch.visible = near and state == State.EMPTY
	# Empty pads stay bright enough to spot from the camera
	if _platform:
		if state == State.EMPTY and not near:
			_platform.modulate = Color(1, 1, 1, 0.82)
		elif state == State.BUILT and not near:
			_platform.modulate = Color(1, 1, 1, 0.45)
		else:
			_platform.modulate = Color.WHITE
	if _tower and _tower.has_method("set_info_visible"):
		_tower.call("set_info_visible", near)


func _process(delta: float) -> void:
	if state == State.QUEUED:
		_queue_left -= delta
		_bar.value = 1.0 - (_queue_left / GameState.TOWER_QUEUE_TIME)
		if _queue_left <= 0.0:
			_finish_build()
	if state == State.EMPTY and _players_near > 0:
		_refresh_label()


func cycle_type(dir: int, player_index: int = 0) -> void:
	if TowerTypes == null:
		return
	_last_builder = player_index
	var id: String = TowerTypes.cycle_for_player(player_index, dir)
	if state == State.EMPTY:
		_preview_type = id
		_refresh_label()
	var d: Dictionary = TowerTypes.def_for(id)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -30), str(d.get("name")), d.get("color"))


func set_preview_from_player(player_index: int) -> void:
	if TowerTypes == null or state != State.EMPTY:
		return
	_preview_type = TowerTypes.selected_id_for(player_index)
	_last_builder = player_index
	_refresh_label()


func try_queue_build(player_index: int = 0) -> bool:
	if GameState.is_game_over:
		return false
	if state == State.BUILT:
		return try_upgrade()
	if state != State.EMPTY:
		return false
	_last_builder = player_index
	_queued_type = TowerTypes.selected_id_for(player_index) if TowerTypes else "arrow"
	if TowerTypes and not TowerTypes.is_unlocked(_queued_type):
		_queued_type = TowerTypes.selected_id_for(player_index)
	var cost: int = TowerTypes.cost_for(_queued_type) if TowerTypes else GameState.TOWER_COST_ESSENCE
	if not GameState.try_spend_essence(cost):
		return false
	state = State.QUEUED
	_queue_left = GameState.TOWER_QUEUE_TIME
	_bar.visible = true
	_bar.max_value = 1.0
	_bar.value = 0.0
	_refresh_label()
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -20), "-%d" % cost, Color(1.0, 0.7, 0.3))
	return true


func try_upgrade() -> bool:
	if state != State.BUILT or _tower == null:
		return false
	if _tower.has_method("try_upgrade"):
		var ok: bool = _tower.call("try_upgrade")
		_refresh_label()
		_update_range_preview()
		return ok
	return false


func try_sell() -> bool:
	if state != State.BUILT or _tower == null:
		return false
	var refund := 0
	if _tower.has_method("sell_value"):
		refund = int(_tower.call("sell_value"))
	GameState.add_essence(refund)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -24), "+%d sell" % refund, Color(0.5, 1.0, 0.55))
	_tower.queue_free()
	_tower = null
	state = State.EMPTY
	_refresh_label()
	_update_range_preview()
	if Sfx:
		Sfx.gather()
	return true


func _finish_build() -> void:
	state = State.BUILT
	_bar.visible = false
	var cost: int = TowerTypes.cost_for(_queued_type) if TowerTypes else 25
	if tower_scene:
		_tower = tower_scene.instantiate() as Node2D
		if _tower:
			# type_id BEFORE add_child so _ready applies the correct def.
			_tower.set("type_id", _queued_type)
			if _tower.has_method("set_invested"):
				_tower.call("set_invested", cost)
			if _tower.has_method("set_builder_index"):
				_tower.call("set_builder_index", _last_builder)
			_tower_slot.add_child(_tower)
			# configure after enter tree: rebuilds if needed and records investment.
			if _tower.has_method("configure"):
				_tower.call("configure", _queued_type, cost)
			if _tower.has_method("set_info_visible"):
				_tower.call("set_info_visible", _players_near > 0)
	GameState.message.emit("%s ready!" % TowerTypes.def_for(_queued_type).get("name"))
	_refresh_label()
	_update_range_preview()
	if FX:
		var col: Color = TowerTypes.def_for(_queued_type).get("color", Color.WHITE)
		FX.burst_particles(self, global_position + Vector2(0, -20), col, 18, "star", 0.55)
	if Sfx:
		Sfx.build()


func _update_range_preview() -> void:
	if _range_preview == null:
		return
	var show := _players_near > 0
	_range_preview.visible = show
	if _tower and _tower.has_method("set_range_visible"):
		_tower.call("set_range_visible", show)
	# Preview poly is radius 100; scale so displayed radius == fire_range.
	if state == State.BUILT and _tower and "fire_range" in _tower:
		var fr := float(_tower.fire_range)
		_range_preview.scale = Vector2.ONE * (fr / 100.0)
	elif state == State.EMPTY and TowerTypes:
		var d: Dictionary = TowerTypes.def_for(_preview_type)
		var r: float = float(d.get("range", 340.0))
		var col: Color = d.get("color", Color.GREEN) as Color
		_range_preview.color = Color(col.r, col.g, col.b, 0.14)
		_range_preview.scale = Vector2.ONE * (r / 100.0)


func _on_body_entered(body: Node) -> void:
	if body.has_method("register_build"):
		body.register_build(self)
		_players_near += 1
		if body.get("player_index") != null:
			set_preview_from_player(int(body.player_index))
		_update_range_preview()
		_refresh_label()


func _on_body_exited(body: Node) -> void:
	if body.has_method("unregister_build"):
		body.unregister_build(self)
		_players_near = maxi(0, _players_near - 1)
		_update_range_preview()
		_refresh_label()
