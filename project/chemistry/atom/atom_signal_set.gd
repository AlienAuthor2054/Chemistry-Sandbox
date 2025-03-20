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

class_name AtomSignalSet extends RefCounted

var _set: Dictionary[Atom, Signal]
var _callable: Callable
var _bind_self: bool

func _init(callable: Callable, bind_self: bool = false):
	_callable = callable
	_bind_self = bind_self

func has(atom: Atom) -> bool:
	return _set.has(atom)

func add(sig: Signal) -> void:
	var atom: Atom = sig.get_object()
	if _bind_self:
		sig.connect(_callable.bind(atom))
	else:
		sig.connect(_callable)
	_set[atom] = sig

func erase(atom: Atom) -> void:
	_set[atom].disconnect(_callable)
	_set.erase(atom)

func clear() -> void:
	for atom in _set:
		_set[atom].disconnect(_callable)
	_set.clear()
