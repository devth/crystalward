extends Area2D
## Kingdom Rush build platform: circular stone pad, build / upgrade / sell.

enum State { EMPTY, QUEUED, BUILT }

@export var tower_scene: PackedScene

var state: State = State.EMPTY
var _queue_left: float = 0.0
var _tower: Node2D = null
var _platform: Node2D
var _range_preview: Polygon2D
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
	_build_visuals()
	FX.style_progress_bar(_bar, Color(0.55, 0.85, 0.45), Color(0.1, 0.08, 0.06, 0.85))
	_bar.visible = false
	_bar.position = Vector2(-30, -56)
	_bar.size = Vector2(60, 9)
	_refresh_label()
	if VisualStyle:
		VisualStyle.style_game_label(_label, 12, true)
	_label.position = Vector2(-56, 30)
	z_index = int(global_position.y)
	add_to_group("tower_sites")


func _build_visuals() -> void:
	if VisualStyle:
		VisualStyle.make_blob_shadow(self, 32, 14, 10)
	_platform = Node2D.new()
	add_child(_platform)

	# KR-style circular stone build pad
	var outer := FX.make_ellipse_poly(36, 22, 28, Color(0.35, 0.32, 0.3, 0.95))
	_platform.add_child(outer)
	var mid := FX.make_ellipse_poly(28, 16, 24, Color(0.48, 0.44, 0.4, 0.95))
	_platform.add_child(mid)
	var inner := FX.make_ellipse_poly(16, 9, 20, Color(0.28, 0.35, 0.28, 0.9))
	_platform.add_child(inner)
	# Green "available" gem
	var gem := FX.make_ellipse_poly(5, 3, 12, Color(0.4, 0.85, 0.45, 0.9))
	gem.position = Vector2(0, -2)
	gem.name = "AvailGem"
	_platform.add_child(gem)

	# Range preview when player nearby (empty or built)
	_range_preview = FX.make_ellipse_poly(85, 52, 40, Color(0.3, 0.85, 0.4, 0.12))
	_range_preview.z_index = -2
	_range_preview.visible = false
	add_child(_range_preview)


func _refresh_label() -> void:
	match state:
		State.EMPTY:
			_label.text = "Build (%d)" % GameState.TOWER_COST_ESSENCE
		State.QUEUED:
			_label.text = "Building..."
		State.BUILT:
			if _tower and _tower.get("level") != null:
				var lv: int = int(_tower.level)
				if lv >= GameState.TOWER_MAX_LEVEL:
					_label.text = "Max · E sell (%d)" % (_tower.sell_value() if _tower.has_method("sell_value") else 0)
				else:
					_label.text = "Q up (%d) · E sell" % GameState.TOWER_UPGRADE_COST
			else:
				_label.text = "Online"


func _process(delta: float) -> void:
	if state == State.QUEUED:
		_queue_left -= delta
		_bar.value = 1.0 - (_queue_left / GameState.TOWER_QUEUE_TIME)
		if _queue_left <= 0.0:
			_finish_build()
	# Pulse available gem
	if state == State.EMPTY and _platform and _platform.has_node("AvailGem"):
		var g: CanvasItem = _platform.get_node("AvailGem")
		g.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)


func try_queue_build() -> bool:
	if GameState.is_game_over:
		return false
	if state == State.BUILT:
		return try_upgrade()
	if state != State.EMPTY:
		return false
	if not GameState.try_spend_essence(GameState.TOWER_COST_ESSENCE):
		return false
	state = State.QUEUED
	_queue_left = GameState.TOWER_QUEUE_TIME
	_bar.visible = true
	_bar.max_value = 1.0
	_bar.value = 0.0
	_refresh_label()
	if _platform and _platform.has_node("AvailGem"):
		_platform.get_node("AvailGem").visible = false
	GameState.message.emit("Tower building…")
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -20), "-%d" % GameState.TOWER_COST_ESSENCE, Color(1.0, 0.7, 0.3))
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


func is_built() -> bool:
	# State.EMPTY=0, QUEUED=1, BUILT=2 — expose without callers hardcoding ints.
	return state == State.BUILT


func can_sell() -> bool:
	return state == State.BUILT and _tower != null


func try_sell() -> bool:
	if not can_sell():
		return false
	var refund := 0
	if _tower.has_method("sell_value"):
		refund = int(_tower.call("sell_value"))
	else:
		refund = int(GameState.TOWER_COST_ESSENCE * GameState.TOWER_SELL_REFUND)
	GameState.add_essence(refund)
	FloatingText.spawn(get_parent(), global_position + Vector2(0, -24), "+%d sell" % refund, Color(0.5, 1.0, 0.55))
	GameState.message.emit("Sold tower +%d Essence" % refund)
	_tower.queue_free()
	_tower = null
	state = State.EMPTY
	if _platform and _platform.has_node("AvailGem"):
		_platform.get_node("AvailGem").visible = true
	_refresh_label()
	_update_range_preview()
	if Sfx:
		Sfx.gather()
	return true


func _finish_build() -> void:
	state = State.BUILT
	_bar.visible = false
	if tower_scene:
		_tower = tower_scene.instantiate() as Node2D
		_tower_slot.add_child(_tower)
		# Always seed invested essence so sell refunds work from first build.
		if _tower.has_method("set_invested"):
			_tower.call("set_invested", GameState.TOWER_COST_ESSENCE)
		else:
			_tower.set("invested_essence", GameState.TOWER_COST_ESSENCE)
	GameState.message.emit("Tower ready!")
	_refresh_label()
	_update_range_preview()
	if FX:
		FX.burst_particles(self, global_position + Vector2(0, -20), Color(0.5, 0.9, 0.45), 18, "star", 0.55)
	if Sfx:
		Sfx.build()


func _update_range_preview() -> void:
	if _range_preview == null:
		return
	var show := _players_near > 0
	_range_preview.visible = show
	if _tower and _tower.has_method("set_range_visible"):
		_tower.call("set_range_visible", show)
	if state == State.BUILT and _tower and "fire_range" in _tower:
		var fr: float = float(_tower.fire_range)
		_range_preview.scale = Vector2.ONE * (fr / 170.0)


func _on_body_entered(body: Node) -> void:
	if body.has_method("register_build"):
		body.register_build(self)
		_players_near += 1
		_update_range_preview()
		_refresh_label()
	if body.has_method("register_tower_site"):
		body.register_tower_site(self)


func _on_body_exited(body: Node) -> void:
	if body.has_method("unregister_build"):
		body.unregister_build(self)
		_players_near = maxi(0, _players_near - 1)
		_update_range_preview()
	if body.has_method("unregister_tower_site"):
		body.unregister_tower_site(self)
