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

extends Node2D

@warning_ignore("unused_signal")
signal external_change_applied

var elements_possible := ElementDB.data.keys()
var elements_possible_count := elements_possible.size()
var element_selection_index := 0
var selected_element: int:
	get(): return Global.selected_element
	set(new): Global.selected_element = new

func _ready():
	Global.selected_element_changed.connect(func(new: int):
		element_selection_index = elements_possible.find(new)
	)

@onready var db := $UI/SelectedElementButton/Timer
func _unhandled_input(event: InputEvent) -> void:
	Simulation.on_unhandled_input(event)
	if event.is_action_released("spawn_atom", true):
		$World.spawn_atom()
	elif event is InputEventMouseButton and event is not InputEventWithModifiers:
		if not db.is_stopped(): return
		db.start()
		match event.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				element_selection_index += 1
			MOUSE_BUTTON_WHEEL_UP:
				element_selection_index -= 1
		if element_selection_index >= elements_possible_count: element_selection_index = 0
		if element_selection_index < 0: element_selection_index = elements_possible_count - 1
		selected_element = elements_possible[element_selection_index]
	else:
		for index in range(4):
			if not event.is_action_pressed("select_hotbar_element_" + str(index + 1), true): continue
			element_selection_index = index
			selected_element = elements_possible[element_selection_index]
