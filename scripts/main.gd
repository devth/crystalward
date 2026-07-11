extends Node2D
## World bootstrap + atmosphere.


func _ready() -> void:
	print("Crystalward — devices: ", Input.get_connected_joypads())
	_build_atmosphere()


func _build_atmosphere() -> void:
	# Vignette / color grade overlay in world space (large)
	var grade := Polygon2D.new()
	grade.z_index = 80
	grade.color = Color(0.12, 0.05, 0.18, 0.0)  # driven by children instead
	# Use a CanvasLayer-less approach: dark corners via four gradients is heavy;
	# instead add floating ambient particles around the crystal.
	var ambient := FX.spark_particles(self, Color(0.55, 0.4, 0.85, 0.35), 24)
	ambient.position = Vector2(0, 40)
	var pm := ambient.process_material as ParticleProcessMaterial
	if pm:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 200.0
		pm.gravity = Vector3(0, -2, 0)
		pm.initial_velocity_min = 2.0
		pm.initial_velocity_max = 10.0
		pm.scale_min = 0.6
		pm.scale_max = 1.8

	# Soft god-ray polygons from crystal
	for i in 3:
		var ray := Polygon2D.new()
		var ang := -0.5 + i * 0.5
		ray.polygon = PackedVector2Array([
			Vector2(0, 20),
			Vector2(cos(ang - 0.15) * 40, sin(ang - 0.15) * 40 - 80),
			Vector2(cos(ang + 0.15) * 200, sin(ang + 0.15) * 120 - 200),
			Vector2(cos(ang - 0.15) * 200, sin(ang - 0.15) * 120 - 200),
		])
		ray.color = Color(0.55, 0.4, 0.85, 0.04 + i * 0.01)
		ray.z_index = -20
		ray.position = Vector2(0, 40)
		add_child(ray)
