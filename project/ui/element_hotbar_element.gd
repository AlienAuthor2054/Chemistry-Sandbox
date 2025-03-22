extends Label

@export var element = 1

@onready var UI := $"/root/Main/UI"

func _on_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()): return
	Global.selected_element = element
