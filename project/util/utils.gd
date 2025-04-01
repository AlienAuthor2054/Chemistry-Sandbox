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

class_name Util extends RefCounted

static func count_array(array: Array) -> Dictionary[Variant, int]:
	var counts: Dictionary[Variant, int] = {}
	for value in array:
		counts[value] = counts.get_or_add(value, 0) + 1
	return counts

static func count_dict_to_array(dict: Dictionary) -> Array:
	var arr := []
	for item in dict:
		var item_arr = []
		item_arr.resize(dict[item])
		item_arr.fill(item)
		arr.append_array(item_arr)
	return arr

static func sumi_dict_values(dict: Dictionary) -> int:
	return dict.values().reduce(func(total: int, num: int): return total + num, 0)

static func sumf_dict_values(dict: Dictionary) -> float:
	return dict.values().reduce(func(total: float, num: float): return total + num, 0.0)
	
static func multi_mini(ints: Array[int]) -> int:
	return ints.min()

static func clamp_in_rect(vec: Vector2, rect: Rect2) -> Vector2:
	return Vector2(clampf(vec.x, rect.position.x, rect.end.x), clampf(vec.y, rect.position.y, rect.end.y))

static func rect_corners(rect: Rect2) -> Array[Vector2]:
	return [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]

static func to_center_origin_rect(vec: Vector2) -> Rect2:
	return Rect2(-vec / 2, vec)

static func rect_with_center(rect: Rect2, vec: Vector2) -> Rect2:
	rect.position += vec - rect.get_center()
	return rect

static func enclose_rect(to_enclose: Rect2, enclosure: Rect2) -> Rect2:
	var offset := Vector2.ZERO
	offset.x += min(0, enclosure.end.x - to_enclose.end.x)
	offset.x += max(0, enclosure.position.x - to_enclose.position.x)
	offset.y += min(0, enclosure.end.y - to_enclose.end.y)
	offset.y += max(0, enclosure.position.y - to_enclose.position.y)
	to_enclose.position += offset
	return to_enclose
