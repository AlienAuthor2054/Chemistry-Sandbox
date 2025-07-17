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

extends Node

var BOND_DB: Dictionary[String, PackedFloat32Array]

func _ready() -> void:
	var file := FileAccess.open("res://chemistry/atom/bond/bond_db.txt", FileAccess.READ)
	while not file.eof_reached():
		var entry := file.get_csv_line()
		if entry[0] == "": continue
		BOND_DB[entry[0]] = PackedFloat32Array([float(entry[1]), float(entry[2])])

func get_data(atom1: Atom, atom2: Atom, order: int) -> PackedFloat32Array:
	var bond_symbol: String = ["-", "=", "#"][order - 1]
	var data = BOND_DB.get(atom1.symbol + bond_symbol + atom2.symbol)
	if data == null:
		data = BOND_DB[atom2.symbol + bond_symbol + atom1.symbol]
	return data
