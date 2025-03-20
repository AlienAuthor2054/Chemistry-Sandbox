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

class_name ArrayStats extends RefCounted

var arr: Array[float] = []
var count: int:
	get(): return arr.size()

func _init(array: Array) -> void:
	arr = array

func sum() -> float:
	return arr.reduce(func(acc: float, num: float): return acc + num, 0)

func mean() -> float:
	return sum() / count

func percentile(pcile: float) -> float:
	var sorted := arr.duplicate()
	sorted.sort()
	return sorted[roundi(pcile / 100 * (count - 1))]
