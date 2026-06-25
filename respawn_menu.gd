extends CanvasLayer


var respawn: Callable


func _on_respawn_pressed() -> void:
	hide()
	respawn.call()
