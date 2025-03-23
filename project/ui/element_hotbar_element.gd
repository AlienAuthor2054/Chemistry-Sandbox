extends Button

@export var element = 1

@onready var UI := $"/root/Main/UI"

func _on_pressed() -> void:
	Global.selected_element = element
