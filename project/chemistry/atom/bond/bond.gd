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

enum STATE {
	FIRST_ATTRACTION = -2,
	FIRST_REPULSION = -1,
	REACHED_REST_LENGTH = 0,
	REBOUND_REST_LENGTH = 1,
	FINAL = 2,
}

const ATOM_BOND_LINE_SCENE = preload("uid://cqiykungxfadm")
# Physical bond strength nerfed according to hydrogen count
const H_BOND_PHYSICAL_STRENGTH_MULTI: Array[float] = [0.4, 0.2]

var order: int
var energy: float
var _atom: Atom
var _other: Atom
var state: STATE = STATE.FIRST_ATTRACTION
var base_length: float = 175
var max_length: float = 200
var length: float:
	get():
		return (_other.position - _atom.position).length()
var physical_strength_multi := 1.0
var reduced_mass: float
var vdw_distance: float
var transitional_total_impulse := 0.0
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
	var hydrogens := int(atom.protons == 1) + int(other.protons == 1)
	if hydrogens >= 1:
		physical_strength_multi = H_BOND_PHYSICAL_STRENGTH_MULTI[hydrogens - 1]
	reduced_mass = (_atom.mass * _other.mass) / (_atom.mass + _other.mass)
	vdw_distance = (_atom.radius + _other.radius) / 2.0
	update_order(order)

func _process(_delta: float) -> void:
	update_transform()

func update_order(new_order: int) -> void:
	order = new_order
	var bond_data := BondDB.get_data(_atom, _other, order)
	energy = bond_data[0]
	base_length = bond_data[1]
	if length > base_length:
		state = STATE.FIRST_ATTRACTION
	elif length < base_length:
		state = STATE.FIRST_REPULSION
	else:
		state = STATE.FINAL
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
