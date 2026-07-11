extends Area2D
## Build pad: cycle tower type, build, upgrade, sell (KR + multi-type).
## Labels / type swatches only when a player is near — keeps the map readable.

enum State { EMPTY, QUEUED, BUILT }

@export var tower_scene: PackedScene

var state: State = State.EMPTY
var _queue_left: float = 0.0
var _tower: Node2D = null
var _queued_type: String = "thornspire"
var _platform: Node2D
var _range_preview: Polygon2D
var _type_swatch: Polygon2D
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
		VisualStyle.make_blob_shadow(self, 28, 12, 10)
	_platform = Node2D.new()
	add_child(_platform)
	# Stone build pad — quiet marker, not a neon manhole
	var outer := FX.make_ellipse_poly(30, 16, 28, Color(0.22, 0.2, 0.18, 0.7))
	_platform.add_child(outer)
	var mid := FX.make_ellipse_poly(20, 11, 24, Color(0.36, 0.34, 0.3, 0.65))
	_platform.add_child(mid)
	var inner := FX.make_ellipse_poly(10, 6, 16, Color(0.48, 0.5, 0.42, 0.4))
	_platform.add_child(inner)
	_type_swatch = FX.make_ellipse_poly(6, 3.5, 12, Color(0.5, 0.85, 0.5, 0.85))
	_type_swatch.position = Vector2(0, -2)
	_type_swatch.visible = false
	_platform.add_child(_type_swatch)
	# Base ring = 100px radius; scaled so preview matches tower fire_range.
	_range_preview = FX.make_ellipse_poly(100, 72, 48, Color(0.3, 0.85, 0.4, 0.14))
	_range_preview.z_index = -2
	_range_preview.visible = false
	add_child(_range_preview)
	_sync_swatch()


func _sync_swatch() -> void:
	if _type_swatch and TowerTypes:
		var d: Dictionary = TowerTypes.selected_def() if state == State.EMPTY else TowerTypes.def_for(_queued_type)
		_type_swatch.color = d.get("color", Color.WHITE)


func _refresh_label() -> void:
	if _label == null:
		return
	if TowerTypes == null:
		_label.text = "Build"
	else:
		match state:
			State.EMPTY:
				var d: Dictionary = TowerTypes.selected_def()
				_label.text = "%s %d✦  [←→]" % [d.get("name"), d.get("cost")]
			State.QUEUED:
				_label.text = "Building %s..." % TowerTypes.def_for(_queued_type).get("name")
			State.BUILT:
				if _tower and _tower.get("level") != null:
					var lv: int = int(_tower.level)
					if lv >= GameState.TOWER_MAX_LEVEL:
						_label.text = "Max · E sell"
					else:
						_label.text = "Q up · E sell"
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
	# Soft dim for empty far pads so they mark space without dominating
	if _platform:
		if state == State.EMPTY and not near:
			_platform.modulate = Color(1, 1, 1, 0.55)
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


func cycle_type(dir: int) -> void:
	if state != State.EMPTY or TowerTypes == null:
		return
	TowerTypes.cycle(dir)
	_refresh_label()
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -30), str(TowerTypes.selected_def().get("name")), TowerTypes.selected_def().get("color"))


func try_queue_build() -> bool:
	if GameState.is_game_over:
		return false
	if state == State.BUILT:
		return try_upgrade()
	if state != State.EMPTY:
		return false
	_queued_type = TowerTypes.selected_id() if TowerTypes else "thornspire"
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
			# type_id BEFORE add_child so _ready applies the correct def (not default thornspire).
			_tower.set("type_id", _queued_type)
			if _tower.has_method("set_invested"):
				_tower.call("set_invested", cost)
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
		var r: float = float(TowerTypes.selected_def().get("range", 340.0))
		var col: Color = TowerTypes.selected_def().get("color", Color.GREEN) as Color
		_range_preview.color = Color(col.r, col.g, col.b, 0.14)
		_range_preview.scale = Vector2.ONE * (r / 100.0)


func _on_body_entered(body: Node) -> void:
	if body.has_method("register_build"):
		body.register_build(self)
		_players_near += 1
		_update_range_preview()
		_refresh_label()


func _on_body_exited(body: Node) -> void:
	if body.has_method("unregister_build"):
		body.unregister_build(self)
		_players_near = maxi(0, _players_near - 1)
		_update_range_preview()
		_refresh_label()
