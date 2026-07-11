extends Node
## Ensures window title / identity is Crystalward (not host "Godot").
## Autoloaded early as AppIdentity.


func _ready() -> void:
	_apply_title()
	# Re-apply next frames in case engine overwrites on scene change
	call_deferred("_apply_title")
	get_tree().root.ready.connect(_apply_title)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_apply_title()


func _apply_title() -> void:
	if DisplayServer.has_method("window_set_title"):
		DisplayServer.window_set_title("Crystalward")
