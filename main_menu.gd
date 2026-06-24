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
	var address: String = new_text
	var port: int = PORT
	
	if new_text.find(":") != -1:
		var ip_split: PackedStringArray = new_text.split(":")
		
		if ip_split.size() != 2:
			push_error("Invalid client ip address")
			return
		
		address = ip_split[0]
		port = ip_split[1].to_int()
	
	client_connect.call(address,port)
	
	hide()
