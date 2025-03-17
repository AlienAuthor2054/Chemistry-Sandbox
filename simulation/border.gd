extends StaticBody2D

const world_size = Simulation.world_size

func _ready() -> void:
	$CollisionPolygon2D.set_polygon(PackedVector2Array([
		Vector2(0, 0), Vector2(world_size.x, 0), 
		world_size, Vector2(0, world_size.y)
	]))
	$Sprite2D.scale = world_size / 1000
