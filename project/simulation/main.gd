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

extends Node2D

@warning_ignore("unused_signal")
signal external_change_applied

var clicked_point := Vector2.ZERO
var atoms_possible := Atom.atom_db.keys()
var atoms_possible_count := atoms_possible.size()
var atom_selection_index := 0

func _ready():
	Atom.create_textures()

@onready var db := $UI/SelectedAtomLabel/Timer
func _unhandled_input(event: InputEvent) -> void:
	Simulation.on_unhandled_input(event)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			clicked_point = get_global_mouse_position()
		else:
			Atom.create(self, atoms_possible[atom_selection_index], clicked_point, (get_global_mouse_position() - clicked_point) * 1.5)
	elif event is InputEventMouseButton:
		if not db.is_stopped(): return
		db.start()
		match event.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				atom_selection_index += 1
			MOUSE_BUTTON_WHEEL_UP:
				atom_selection_index -= 1
		if atom_selection_index >= atoms_possible_count: atom_selection_index = 0
		if atom_selection_index < 0: atom_selection_index = atoms_possible_count - 1
		$UI/SelectedAtomLabel.text = Atom.atom_db[atoms_possible[atom_selection_index]].symbol
