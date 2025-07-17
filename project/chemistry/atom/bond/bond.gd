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

class_name Bond extends Node2D

const ATOM_BOND_LINE_SCENE = preload("uid://cqiykungxfadm")

var order: int
var energy: float
var _atom: Atom
var _other: Atom
var force_multi := 1.0
var base_length: float = 175
var max_length: float = base_length * 1.75
var strength: float = 1000
var lines: Array[Polygon2D] = []
var deleting := false

@warning_ignore("shadowed_variable")
static func get_energy(atom1: Atom, atom2: Atom, order: int) -> float:
	if order == 0: return 0.0
	return BondDB.get_data(atom1, atom2, order)[0]

@warning_ignore("shadowed_variable")
func initialize(atom: Atom, other: Atom, order: int):
	_atom = atom
	_other = other
	force_multi = _atom.mass * _other.mass / (_atom.mass + _other.mass)
	update_order(order)

func _process(_delta: float) -> void:
	update_transform()

func update_order(new_order: int) -> void:
	order = new_order
	energy = get_energy(_atom, _other, order)
	lines.clear()
	for line: Polygon2D in self.get_children():
		line.queue_free()
	var y_offset := (order - 1) / 2.0
	for index in range(order):
		var line: Polygon2D = ATOM_BOND_LINE_SCENE.instantiate()
		var line_width_scale = energy / order / 250
		line.position = Vector2(0, (16 + (line_width_scale * 16)) * (index - y_offset))
		line.scale = Vector2(1, line_width_scale)
		add_child(line)
		lines.append(line)

func update_transform() -> void:
	if deleting == true: return
	var difference := _other.position - _atom.position
	var distance := difference.length()
	var direction := difference.normalized()
	rotation = atan2(direction.y, direction.x)
	scale = Vector2(distance / 100, 1)
