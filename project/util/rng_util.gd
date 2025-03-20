# Chemistry Sandbox
# Copyright (C) 2025 AlienAuthor2054 & Chemistry Sandbox contributors

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
