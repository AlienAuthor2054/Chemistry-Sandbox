extends Node

signal selected_element_changed(new: int)

var selected_element: int:
	set(new):
		selected_element = new
		selected_element_changed.emit(new)
		
func _ready() -> void:
	selected_element = 1
