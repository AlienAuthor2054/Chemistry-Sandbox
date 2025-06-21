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

var world_size := Vector2(2000, 2000):
	set(new):
		world_size = new
		world_rect = Rect2(-new / 2, new)
var world_rect: Rect2

var running: bool:
	set(new):
		running = new
		running_changed.emit(new)

func _init() -> void:
	world_size = world_size
	running = true

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_simulation_running", true):
		running = not running

func on_unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("benchmark", true):
		clear()
		SimulationBenchmark.new($"/root/Main")

func clear() -> void:
	get_tree().call_group("atoms", "queue_free")

func is_point_in_world(position: Vector2) -> bool:
	return world_rect.has_point(position)
