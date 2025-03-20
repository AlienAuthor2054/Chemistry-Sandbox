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

class_name Combination extends RefCounted

@warning_ignore("shadowed_variable")
static func _combos_index(list: Array, combo_size: int, n: int, combo: Array, combos: Array) -> Array:
	var next_list: Array = list.duplicate()
	if combo.size() == combo_size:
		combos.append(combo)
		#print(combo)
		return combos
	#print("n = %s, list = %s" % [str(n), str(list)])
	for index in range(n):
		if index > 0: n -= 1
		var new_combo = combo.duplicate()
		var first = next_list.pop_front()
		new_combo.append(first)
		#print(new_combo)
		_combos_index(next_list, combo_size, n, new_combo, combos)
	return combos

static func combos(list: Array, n: int) -> Array:
	var size = list.size()
	if n == 0:
		return [[]]
	if n > size:
		return []
	#assert(n > 0 and n <= size, "n must be within [0, list size]!")
	@warning_ignore("shadowed_variable")
	var combos = _combos_index(range(size), n, size - n + 1, [], [])
	combos = combos.map(func(combo): return combo.map(func(index): return list[index]))
	return combos

static func combos_range(list: Array, min_n: int = 0, max_n: int = list.size()) -> Array:
	@warning_ignore("shadowed_variable")
	var combos := []
	for n in range(min_n, max_n + 1):
		combos.append_array(combos(list, n))
	return combos

static func combos_range_counts(list: Array, min_n: int = 0, max_n: int = list.size()) -> Array:
	return combos_range(list, min_n, max_n).map(func(combo: Array):
		var size := combo.size()
		assert(size >= min_n and size <= max_n, "Combo error: Combo size of %s is outside bounds of range parameters [%s, %s]" % [size, min_n, max_n])
		return Util.count_array(combo)
	)
