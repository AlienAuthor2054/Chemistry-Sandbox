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

signal running_changed(new: bool)

var world_size := Vector2(2000, 2000)

var running: bool:
	set(new):
		running = new
		running_changed.emit(new)

func _init() -> void:
	running = true

func on_unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_simulation_running", true):
		running = not running
	elif event.is_action_pressed("benchmark", true):
		clear()
		SimulationBenchmark.new($"/root/Main")

func clear() -> void:
	get_tree().call_group("atoms", "remove")
