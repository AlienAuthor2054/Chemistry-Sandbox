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

class_name BondChangedEvent extends Node

var _atom: Atom
var _other: Atom
var _broadcast_unbond_event: bool
	
func _init(atom: Atom, other: Atom, broadcast_unbond_event: bool = false) -> void:
	_atom = atom
	_other = other
	_broadcast_unbond_event = broadcast_unbond_event

func execute(emit_atom_dirty: int = Atom.ID_PRIORITY, emit_mol_dirty: bool = true) -> void:
	if emit_atom_dirty == Atom.ID_PRIORITY:
		Atom.get_id_priority(_atom, _other).dirty.emit()
	elif emit_atom_dirty != Atom.NONE:
		if emit_atom_dirty != Atom.OTHER:
			_atom.dirty.emit()
		if emit_atom_dirty != Atom.SELF:
			_other.dirty.emit()
	if not emit_mol_dirty: return
	_atom.molecule.dirty.emit()
	if _atom.molecule.id != _other.molecule.id:
		_other.molecule.dirty.emit()
	if _broadcast_unbond_event and _atom.molecule.id != _other.molecule.id:
		CascadingBondsModel.new().from_unbonded_atom(_atom)
		CascadingBondsModel.new().from_unbonded_atom(_other)
