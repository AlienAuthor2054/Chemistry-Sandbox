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

class_name RunningList extends RefCounted

var list: Array[float] = []
var max_size := 0
var average := 0.0

func _init(_max_size: int) -> void:
	max_size = _max_size

func insert(number: float) -> void:
	if list.size() == max_size:
		list.resize(max_size - 1)
	list.push_front(number)
	average = _average()
	
func clear() -> void:
	list.clear()
	average = 0

func _average() -> float:
	if list.is_empty(): return 0
	var sum := 0.0
	for number in list:
		sum += number
	return sum / list.size()
