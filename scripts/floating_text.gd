extends Node2D
class_name FloatingText
## Kingdom Rush–style floating combat / economy text.


func setup(text: String, color: Color = Color.WHITE, rise: float = 36.0) -> void:
	var lab := Label.new()
	lab.text = text
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector2(-40, -10)
	lab.size = Vector2(80, 20)
	lab.add_theme_font_size_override("font_size", 16)
	lab.add_theme_color_override("font_color", color)
	lab.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.95))
	lab.add_theme_constant_override("outline_size", 4)
	lab.z_index = 200
	add_child(lab)
	z_index = 200
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position", position + Vector2(randf_range(-8, 8), -rise), 0.75).set_ease(Tween.EASE_OUT)
	tw.tween_property(lab, "modulate:a", 0.0, 0.75).set_delay(0.25)
	tw.chain().tween_callback(queue_free)


static func spawn(parent: Node, world_pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	# Instantiate via script resource so callers work even before global class cache warms.
	var script: GDScript = load("res://scripts/floating_text.gd") as GDScript
	if script == null:
		return
	var ft: Node2D = script.new() as Node2D
	if ft == null:
		return
	parent.add_child(ft)
	ft.global_position = world_pos
	if ft.has_method("setup"):
		ft.call("setup", text, color)
