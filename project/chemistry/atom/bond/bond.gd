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
const STIFFNESS = 0.03
const STRENGTH = 150000.0
# Physical bond strength nerfed according to hydrogen count
const H_BOND_PHYSICAL_STRENGTH_MULTI: Array[float] = [0.4, 0.2]

var order: int
var base_energy: float
var energy: float
var _atom: Atom
var _other: Atom
var state: STATE = STATE.FIRST_ATTRACTION
var base_length: float = 175
var max_length: float = 200
var length: float
var physical_strength_multi := 1.0
var reduced_mass: float
var vdw_distance: float
var transitional_total_impulse := 0.0
var lines: Array[Polygon2D] = []
var deleting := false

@warning_ignore("shadowed_variable")
static func get_base_energy(atom1: Atom, atom2: Atom, order: int) -> float:
	if order == 0: return 0.0
	return BondDB.get_data(atom1, atom2, order)[0]

@warning_ignore("shadowed_variable")
static func get_energy(atom1: Atom, atom2: Atom, order: int) -> float:
	if order == 0: return 0.0
	var bond_data := BondDB.get_data(atom1, atom2, order)
	var morse_energy := -bond_data[0] * ((1 - 
			exp(-STIFFNESS * ((atom2.position - atom1.position).length() - bond_data[1]))
	) ** 2 - 1)
	return morse_energy - (
			(atom2.velocity - atom1.velocity).length_squared()
			* atom1.mass * atom2.mass / (atom1.mass + atom2.mass) / STRENGTH
	)

@warning_ignore("shadowed_variable")
func initialize(atom: Atom, other: Atom, order: int):
	_atom = atom
	_other = other
	var hydrogens := int(atom.protons == 1) + int(other.protons == 1)
	if hydrogens >= 1:
		physical_strength_multi = H_BOND_PHYSICAL_STRENGTH_MULTI[hydrogens - 1]
	reduced_mass = (_atom.mass * _other.mass) / (_atom.mass + _other.mass)
	vdw_distance = (_atom.radius + _other.radius) / 2.0
	length = (_other.position - _atom.position).length()
	update_order(order)

func _physics_process(_delta: float) -> void:
	update_energy()

func _process(_delta: float) -> void:
	update_transform()
	update_lines()

func update_order(new_order: int) -> void:
	order = new_order
	var bond_data := BondDB.get_data(_atom, _other, order)
	base_length = bond_data[1]
	# Reset accumulated impulse on bond order change
	transitional_total_impulse = 0.0
	if length > base_length:
		state = STATE.FIRST_ATTRACTION
	elif length < base_length:
		state = STATE.FIRST_REPULSION
	else:
		state = STATE.FINAL
	base_energy = get_base_energy(_atom, _other, order)
	update_energy()

func update_lines() -> void:
	lines.clear()
	for line: Polygon2D in self.get_children():
		line.queue_free()
	if energy <= 0: return
	var y_offset := (order - 1) / 2.0
	for index in range(order):
		var line: Polygon2D = ATOM_BOND_LINE_SCENE.instantiate()
		var line_width_scale = energy / order / 250
		line.position = Vector2(0, (16 + (line_width_scale * 16)) * (index - y_offset))
		line.scale = Vector2(1, line_width_scale)
		add_child(line)
		lines.append(line)

func update_energy() -> void:
	energy = get_energy(_atom, _other, order)
	assert(energy <= base_energy, "Bond should not be more stable than ground state!")

func update_transform() -> void:
	if deleting == true: return
	#print(int(energy/base_energy*100))
	var difference := _other.position - _atom.position
	length = difference.length()
	var direction := difference.normalized()
	rotation = atan2(direction.y, direction.x)
	scale = Vector2(length / 100, 1)
