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

class_name HotbarItem extends PanelContainer

@export var element = 1

@onready var UI := $"/root/Main/SimulationUI"

func _ready() -> void:
	if Global.selected_element == element:
		select()
	%Button.texture_normal = ImageTexture.create_from_image(await AtomImager.capture_single(element))

func _on_button_pressed() -> void:
	Global.selected_element = 0 if Global.selected_element == element else element

func _on_button_toggled(toggled_on: bool) -> void:
	%Border.visible = toggled_on

func _on_border_gui_input(event: InputEvent) -> void:
	if (
			event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT
			and event.is_released() and %Button.button_pressed
	):
		Global.selected_element = 0

func select() -> void:
	%Button.button_pressed = true
