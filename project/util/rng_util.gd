class_name RNGUtil extends RefCounted

var RNG: RandomNumberGenerator

@warning_ignore("shadowed_variable")
func _init(RNG: RandomNumberGenerator) -> void:
	self.RNG = RNG

func in_rect2(rec: Rect2) -> Vector2:
	var pos := rec.position
	var end := rec.end
	return Vector2(RNG.randf_range(pos.x, end.x), RNG.randf_range(pos.y, end.y))

func unit_vec() -> Vector2:
	var angle := RNG.randf_range(0, TAU)
	return Vector2(cos(angle), sin(angle)).normalized()
