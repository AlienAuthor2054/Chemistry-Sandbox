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

extends StaticBody2D

var clicked_point := Vector2.ZERO
var spawning_atom := false

@onready var world_rect: Rect2
@onready var world_size := Simulation.world_size:
	set(new):
		world_rect = Simulation.world_rect
		var polygon := PackedVector2Array(Util.rect_corners(world_rect))
		$Area/CollisionShape.set_polygon(polygon)
		$Border.set_polygon(polygon)
		$Sprite.scale = world_size / 1000

func _ready() -> void:
	world_size = world_size

func _on_area_input_event(_viewport: Node, event: InputEventWithModifiers, _shape_idx: int) -> void:
	if not event.is_action_pressed("spawn_atom", true) or Global.selected_element == 0: return
	clicked_point = get_global_mouse_position()
	spawning_atom = true

func _on_atom_exited(atom: Atom) -> void:
	if Simulation.running:
		atom.queue_free()

func spawn_atom() -> void:
	if not spawning_atom or Global.selected_element == 0: return
	Atom.create(
			self,
			Global.selected_element,
			clicked_point, (get_global_mouse_position() - clicked_point) * 1.5,
	)
	spawning_atom = false
