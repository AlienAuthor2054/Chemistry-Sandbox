extends Node

signal selected_element_changed(new: int)

var MAIN_NODE: Node2D

var selected_element: int:
	set(new):
		selected_element = new
		selected_element_changed.emit(new)

func _ready() -> void:
	selected_element = 1
