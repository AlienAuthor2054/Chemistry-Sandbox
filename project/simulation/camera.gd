extends Camera2D

var zoom_multi := 1.0
@onready var zoom_value := get_viewport().get_visible_rect().size.y * zoom_multi / Simulation.world_size.x

var selected_atom = null

func _ready():
	zoom = Vector2(zoom_value, zoom_value)
