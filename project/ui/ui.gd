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

extends CanvasLayer

@onready var zoom_value: float = 1000 / get_viewport().get_visible_rect().size.y

func _ready() -> void:
	Simulation.running_changed.connect(_on_simulation_running_changed)
	Global.selected_element_changed.connect(_on_selected_element_changed)

func _on_temperature_button_pressed(velocity_factor: float) -> void:
	get_tree().call_group("atoms", "multiply_velocity", sqrt(velocity_factor))
	$"..".external_change_applied.emit()

func _on_clear_button_pressed() -> void:
	Simulation.clear()

func _on_pause_toggle_pressed() -> void:
	Simulation.running = not Simulation.running

func _on_simulation_running_changed(running: bool) -> void:
	$SimulationStateTools/PauseToggle.text = "Pause" if running else "Resume"

func _on_selected_element_changed(element: int) -> void:
	$SelectedElementButton.text = ElementDB.get_data(element).symbol

func _on_selected_element_button_pressed() -> void:
	$ElementHotbar.visible = not $ElementHotbar.visible
