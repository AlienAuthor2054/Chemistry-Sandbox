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

var enabled := false
var running_list := RunningList.new(Engine.physics_ticks_per_second)
var frame_combos := 0

func _ready() -> void:
	process_physics_priority = 999
	Performance.add_custom_monitor("Reaction/CPS", func(): return running_list.sum)
	Performance.add_custom_monitor("Reaction/CPF Worst", func(): return running_list.max_num)

func _physics_process(_delta: float) -> void:
	running_list.insert(frame_combos)
	frame_combos = 0
