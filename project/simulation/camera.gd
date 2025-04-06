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

extends Camera2D

var zoom_factor := 1.25
var mouse_move_factor := 1.0
var key_move_factor := 20.0
var zoom_multi: float = 1.0:
	set(new):
		zoom_multi = clampf(new, 0.5, 5)
		zoom_target = get_viewport().get_visible_rect().size.y * zoom_multi / Simulation.world_size.x
		if zoom_value > 0:
			create_tween().set_ease(Tween.EASE_OUT).tween_property(self, "zoom_value", zoom_target, 0.2).from_current()
		else:
			zoom_value = zoom_target
var zoom_value: float:
	set(new):
		zoom_value = new
		zoom = Vector2(new, new)
var zoom_target: float

var selected_atom = null

func _ready():
	reset_camera()

func _process(delta: float) -> void:
	var vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	move(key_move_factor * vector)

func reset_camera():
	position = Vector2(0, 0)
	zoom_multi = 1.0

func move(delta: Vector2) -> void:
	position = Util.clamp_in_rect(position + (delta / zoom_value), $"../World".world_rect)

func change_zoom(zoom_in: bool):
	zoom_multi *= zoom_factor if zoom_in else 1 / zoom_factor

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo(): return
	if Input.is_action_pressed("move_camera", true) and event is InputEventMouseMotion:
		move(-mouse_move_factor * (event as InputEventMouseMotion).relative)
	elif Input.is_action_pressed("zoom_in", true):
		change_zoom(true)
	elif Input.is_action_pressed("zoom_out", true):
		change_zoom(false)
	elif Input.is_action_pressed("reset_camera", true):
		reset_camera()
