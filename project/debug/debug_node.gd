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

class_name DebugNode extends Node2D

const SCENE := preload("uid://cp3eqxp5tp4oy")

static var debug_nodes: Array[DebugNode] = []

var color: Color

static func create(pos: Vector2, color: Color = Color.MAGENTA) -> void:
	var new: DebugNode = SCENE.instantiate()
	new.position = pos
	new.color = color
	Global.MAIN_NODE.add_child(new)
	debug_nodes.append(new)

static func remove_all() -> void:
	for debug_node in debug_nodes:
		debug_node.queue_free()
	debug_nodes.clear()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 25, color)
