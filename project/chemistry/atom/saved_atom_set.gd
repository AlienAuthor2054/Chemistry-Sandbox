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

class_name SavedAtomSet extends Resource

var atom_saves: Dictionary[int, SavedAtom] = {}
var save_rect: Rect2

func _init(atoms: Array[Atom]) -> void:
	var rect_center := Vector2.ZERO
	save_rect = Rect2(atoms[0].position, Vector2.ZERO)
	for atom in atoms:
		atom_saves[atom.id] = SavedAtom.new(atom)
		save_rect = save_rect.expand(atom.position)
	save_rect = save_rect.grow(50)
	rect_center = save_rect.get_center()
	save_rect = Util.rect_with_center(save_rect, Vector2.ZERO)
	for id in atom_saves:
		var save := atom_saves[id]
		save.position -= rect_center

func spawn(parent: Node, spawn_center: Vector2) -> Array[Atom]:
	var spawned_atoms: Dictionary[int, Atom] = {}
	var spawned_saves: Dictionary[int, SavedAtom] = {}
	spawn_center = Util.enclose_rect(
			Util.rect_with_center(save_rect, spawn_center),
			Simulation.world_rect
	).get_center()
	for id in atom_saves:
		var save := atom_saves[id]
		var spawn_pos := spawn_center + save.position
		if not Simulation.is_point_in_world(spawn_pos): continue
		spawned_atoms[id] = Atom.create(parent, save.atomic_number, spawn_pos, save.velocity)
		spawned_saves[id] = save
	for id in spawned_saves:
		var spawned_atom := spawned_atoms[id]
		var bonds := spawned_saves[id].bonds
		for bonded_id in bonds:
			var bonded: Atom = spawned_atoms.get(bonded_id)
			if bonded == null: continue
			spawned_atom.bond_atom(bonded, bonds[bonded_id], false)
	return spawned_atoms.values()

class SavedAtom extends Resource:
	var id: int
	var atomic_number: int
	var position: Vector2
	var velocity: Vector2
	var bonds: Dictionary[int, int]
	
	func _init(atom: Atom) -> void:
		id = atom.id
		atomic_number = atom.protons
		position = atom.position
		velocity = atom.frozen_velocity if atom.frozen else atom.linear_velocity
		var atom_bonds: Dictionary[Atom, Bond] = atom.bonds
		for bonded in atom_bonds:
			if id > bonded.id: continue
			bonds[bonded.id] = atom_bonds[bonded].order
