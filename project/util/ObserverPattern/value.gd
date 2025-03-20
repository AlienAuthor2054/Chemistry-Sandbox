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

class_name Value extends RefCounted

signal valueChanged
var _value = null
var value:
	set(new_value): set_val(new_value, false)
	get(): return _value
var dependents = []

func _init(new_value) -> void:
	if new_value != null:
		_value = new_value

func set_val(new_value, force: bool = false):
	var is_equal: bool = value == new_value
	print("%s -> %s" % [value, new_value])
	_value = new_value
	if (not is_equal) or force:
		valueChanged.emit()
	return new_value

func add(addend, force: bool = false):
	return set_val(value + addend, force)

func sub(subtrahend, force: bool = false):
	return set_val(value - subtrahend, force)

func mul(factor, force: bool = false):
	return set_val(value * factor, force)

func div(divisor, force: bool = false):
	return set_val(value / divisor, force)

func power(exponent, force: bool = false):
	return set_val(pow(value, exponent), force)

func get_val():
	return _value
