extends CanvasLayer

const PORT: int = 1027

@onready var line_edit: LineEdit = $LineEdit
@onready var host_port: LineEdit = $HostPort

var host_connect: Callable
var client_connect: Callable

func _ready() -> void:
	host_port.text = str(PORT)


func hide_buttons() -> void:
	$HostButton.hide()
	$ClientButton.hide()

func _on_host_button_pressed() -> void:
	hide_buttons()
	show_host_port_input()


func show_host_port_input() -> void:
	host_port.show()
	host_port.grab_focus()


func _on_client_button_pressed() -> void:
	hide_buttons()
	show_ip_address_input()


func show_ip_address_input() -> void:
	line_edit.show()
	line_edit.grab_focus()


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


func _on_host_port_text_submitted(new_text: String) -> void:
	host_connect.call(new_text.to_int())
	
	hide()
