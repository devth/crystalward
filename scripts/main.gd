extends Node2D
## Bootstrap: ensure dual pad devices map, light ambient motion.


func _ready() -> void:
	# Joy-Cons / Pro Controllers show up as separate devices; p1=0 p2=1 already in input map.
	print("Crystalward v0 — wardens ready. Devices: ", Input.get_connected_joypads())
