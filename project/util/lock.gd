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

class_name Lock extends RefCounted

var locked := false
var key

func lock(new_key):
	assert(not locked, "Attempted to lock an already locked Lock")
	locked = true
	key = new_key

func unlock(input_key):
	assert(locked, "Attempted to unlock an already unlocked Lock")
	assert(input_key == key, "Attempted to unlock a Lock with a non-matching key")
	locked = false
	key = null
