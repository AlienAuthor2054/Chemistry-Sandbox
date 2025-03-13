extends CanvasLayer

@onready var zoom_value: float = 1000 / get_viewport().get_visible_rect().size.y

func _on_temperature_button_pressed(velocity_factor: float) -> void:
	get_tree().call_group("atoms", "multiply_velocity", sqrt(velocity_factor))
	$"..".external_change_applied.emit()
