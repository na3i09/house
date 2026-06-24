extends CanvasLayer

const PORT: int = 1027

var host_connect: Callable
var client_connect: Callable

func _on_host_button_pressed() -> void:
	host_connect.call(PORT)
	
	hide()


func _on_client_button_pressed() -> void:
	show_ip_address_input()


func show_ip_address_input() -> void:
	$LineEdit.show()
	$LineEdit.grab_focus()


func _on_line_edit_text_submitted(new_text: String) -> void:
	client_connect.call(new_text,PORT)
	
	hide()
