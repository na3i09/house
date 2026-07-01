extends CanvasLayer

@onready var start_button: Button = $Control/StartButton
@onready var player_list: ItemList = $Control/PlayerList



func _on_visibility_changed() -> void:
	if visible:
		if multiplayer.is_server():
			start_button.show()
