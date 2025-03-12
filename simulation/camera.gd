extends Camera2D

@onready var zoom_value := get_viewport().get_visible_rect().size.y / Global.world_size

var selected_atom = null

func _ready():
	zoom = Vector2(zoom_value, zoom_value)
