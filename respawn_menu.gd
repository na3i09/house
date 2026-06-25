extends CanvasLayer


var respawn: Callable


func _on_respawn_pressed() -> void:
	hide()
	assert(respawn.is_valid())
	respawn.call()
