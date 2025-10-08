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

const DB_PATH := "res://chemistry/atom/data/elements/"

var data: Dictionary[int, ElementData] = {}

func get_data(protons: int) -> ElementData:
	return data[protons]

func _init() -> void:
	var dir = DirAccess.open(DB_PATH)
	dir.list_dir_begin()
	var files := dir.get_files()
	for file_name in files:
		if (file_name.get_extension() == "remap"):
			file_name = file_name.replace(".remap", "")
		var element_data: ElementData = ResourceLoader.load(DB_PATH + file_name)
		element_data.initialize()
		data[element_data.atomic_number] = element_data
		file_name = dir.get_next()
