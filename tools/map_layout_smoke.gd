extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== map layout smoke ===")
	var err = change_scene_to_file("res://scenes/main.tscn")
	print("change_scene=", err)
	for i in 8:
		await process_frame
	var main = root.get_node_or_null("Main")
	var world = main.get_node_or_null("World") if main else null
	if world == null:
		print("no world")
		quit(1)
		return
	var sites: Array = []
	var ess: Array = []
	for c in world.get_children():
		var n = str(c.name)
		var vis = c.visible if c is CanvasItem else true
		var active = c.process_mode != Node.PROCESS_MODE_DISABLED
		if c.has_method("try_queue_build"):
			print("SITE ", n, " vis=", vis, " active=", active, " pos=", c.global_position)
			if vis and active:
				sites.append(c.global_position)
		if c.is_in_group("essence_nodes") or n.begins_with("Essence"):
			print("ESS ", n, " vis=", vis, " active=", active, " group=", c.is_in_group("essence_nodes"), " pos=", c.global_position)
			if vis and active:
				ess.append(c.global_position)
	var min_se := 99999.0
	for s in sites:
		for e in ess:
			min_se = minf(min_se, s.distance_to(e))
	var min_ss := 99999.0
	for i in sites.size():
		for j in range(i+1, sites.size()):
			min_ss = minf(min_ss, sites[i].distance_to(sites[j]))
	print("active sites=", sites.size(), " active ess=", ess.size(), " min_ss=", min_ss, " min_se=", min_se)
	quit(0)
