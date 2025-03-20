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

class_name YAMLParser extends Node

static func parse_value(value: String):
	if value.is_valid_int():
		return value.to_int()
	elif value.is_valid_float():
		return value.to_float()
	else:
		return value

static func deep_set_with_final_key(dict: Dictionary, path: Array, final_key, value) -> void:
	for key in path:
		dict = dict.get_or_add(key, {})
	dict[final_key] = value

static func parse(file_path: String) -> Dictionary:
	var result := {}
	var file := FileAccess.open(file_path, FileAccess.READ)
	var path := []
	var prev_depth := 0
	while file.get_position() < file.get_length():
		var line := file.get_line()
		#print(line)
		var split_line := line.split(":")
		var key_string := split_line[0]
		var depth := key_string.count("\t")
		if depth < prev_depth:
			path.resize(depth)
		var key = parse_value(key_string.strip_escapes())
		#print("depth %s: %s" % [depth, key])
		var value_string := split_line[1]
		if value_string.is_empty():
			path.append(key)
		else:
			var value = parse_value(value_string.strip_escapes().substr(1))
			deep_set_with_final_key(result, path, key, value)
			#print(" = " + str(value))
		prev_depth = depth
	return result
