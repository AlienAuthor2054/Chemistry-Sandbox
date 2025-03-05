extends StaticBody2D

const world_size = Global.world_size

func _ready() -> void:
	$CollisionPolygon2D.set_polygon(PackedVector2Array([
		Vector2(0, 0), Vector2(world_size, 0), 
		Vector2(world_size, world_size), Vector2(0, world_size)
	]))
	$Sprite2D.scale = Vector2(world_size, world_size) / 1000
