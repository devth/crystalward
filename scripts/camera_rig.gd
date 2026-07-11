extends Camera2D
## Free-explore camera: pans with wardens. Zoom via scroll, trackpad, or keys.

@export var follow_speed: float = 7.5
@export var crystal_path: NodePath
@export var world_bound: float = 1800.0
@export var look_ahead: float = 90.0
@export var zoom_min: float = 0.4
@export var zoom_max: float = 1.6
@export var base_zoom: float = 0.82
@export var zoom_step: float = 0.1
@export var zoom_smooth: float = 12.0
## Soft auto pull-out when co-op players split (0 = pure manual).
@export var auto_spread_pull: float = 0.12

var _crystal: Node2D
var _user_zoom: float = 0.82
var _zoom_target: float = 0.82
var _smoothed_target: Vector2 = Vector2.ZERO
var _has_target: bool = false


func _ready() -> void:
	if crystal_path:
		_crystal = get_node_or_null(crystal_path) as Node2D
	position_smoothing_enabled = false
	_user_zoom = base_zoom
	_zoom_target = base_zoom
	zoom = Vector2(base_zoom, base_zoom)
	if Juice:
		Juice.bind_camera(self)
	# Ensure we receive wheel even when UI has focus under the cursor
	set_process_input(true)
	set_process_unhandled_input(true)


func _input(event: InputEvent) -> void:
	## Use _input (not only unhandled) so scroll works over HUD panels.
	if _try_zoom_event(event):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _try_zoom_event(event):
		get_viewport().set_input_as_handled()


func _try_zoom_event(event: InputEvent) -> bool:
	# Mouse wheel
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_nudge_zoom(zoom_step)
			return true
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_nudge_zoom(-zoom_step)
			return true

	# macOS trackpad pinch
	if event is InputEventMagnifyGesture:
		var mag := event as InputEventMagnifyGesture
		# factor > 1 = pinch out / zoom in
		var factor: float = mag.factor
		if factor > 0.001:
			_user_zoom = clampf(_user_zoom * factor, zoom_min, zoom_max)
			_zoom_target = _user_zoom
			return true

	# Keyboard: = / + zoom in, - zoom out, 0 reset
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == KEY_EQUAL or k.keycode == KEY_KP_ADD or k.physical_keycode == KEY_EQUAL:
			_nudge_zoom(zoom_step)
			return true
		if k.keycode == KEY_MINUS or k.keycode == KEY_KP_SUBTRACT or k.physical_keycode == KEY_MINUS:
			_nudge_zoom(-zoom_step)
			return true
		if k.keycode == KEY_0 or k.keycode == KEY_KP_0:
			_user_zoom = base_zoom
			_zoom_target = base_zoom
			return true

	return false


func _nudge_zoom(delta_z: float) -> void:
	_user_zoom = clampf(_user_zoom + delta_z, zoom_min, zoom_max)
	_zoom_target = _user_zoom


func _process(delta: float) -> void:
	var wardens := _follow_targets()
	var target := global_position
	var spread := 0.0
	var lead := Vector2.ZERO

	if wardens.is_empty():
		if _crystal:
			target = _crystal.global_position
	else:
		var sum := Vector2.ZERO
		var vel_sum := Vector2.ZERO
		var n := 0
		for w in wardens:
			sum += w.global_position
			n += 1
			if w is CharacterBody2D:
				vel_sum += (w as CharacterBody2D).velocity
		target = sum / float(n)
		if vel_sum.length() > 40.0:
			lead = vel_sum.normalized() * look_ahead
		target += lead
		for w in wardens:
			spread = maxf(spread, w.global_position.distance_to(sum / float(n)))

	var auto_out := 0.0
	if auto_spread_pull > 0.0 and wardens.size() > 1:
		auto_out = clampf(spread / 900.0, 0.0, auto_spread_pull)
	_zoom_target = clampf(_user_zoom - auto_out, zoom_min, zoom_max)
	var z := lerpf(zoom.x, _zoom_target, 1.0 - exp(-zoom_smooth * delta))
	zoom = Vector2(z, z)

	var margin := 220.0 / maxf(0.35, zoom.x)
	var bound := world_bound - margin * 0.25
	target = GameState.clamp_world_position(target, bound) if GameState else target

	if not _has_target:
		_smoothed_target = target
		global_position = target
		_has_target = true
	else:
		var t := 1.0 - exp(-follow_speed * delta)
		_smoothed_target = _smoothed_target.lerp(target, t)
		global_position = _smoothed_target


func _follow_targets() -> Array[Node2D]:
	var out: Array[Node2D] = []
	if GameState:
		for w in GameState.wardens:
			if is_instance_valid(w) and w.is_inside_tree():
				out.append(w)
	if out.is_empty() and get_tree():
		for n in get_tree().get_nodes_in_group("wardens"):
			if n is Node2D and is_instance_valid(n):
				out.append(n as Node2D)
	return out
