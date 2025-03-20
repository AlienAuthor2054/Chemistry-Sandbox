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

class_name Computed extends RefCounted

signal valueChanged
var value = null
var _calc_func: Callable
var dependents = []

func calculate():
	@warning_ignore("shadowed_variable")
	value = _calc_func.call(func(value: Value): return value.value)
	valueChanged.emit()

@warning_ignore("shadowed_variable")
func use(value: Value):
	if not dependents.has(value):
		dependents.append(value)
		value.valueChanged.connect(calculate)
	return value.value

func _init(calc_func: Callable) -> void:
	_calc_func = calc_func
	_calc_func.call(use)
	calculate()
