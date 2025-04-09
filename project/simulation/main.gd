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

var elements_possible := ElementDB.data.keys()
var elements_possible_count := elements_possible.size()
var element_selection_index := 0
var selected_element: int:
	get(): return Global.selected_element
	set(new): Global.selected_element = new

func _ready():
	Global.MAIN_NODE = self
	Global.selected_element_changed.connect(func(new: int):
		element_selection_index = elements_possible.find(new)
	)

func _process(_delta: float) -> void:
	if %TitleScreen.visible: return
	for index in range(4):
		if not Input.is_action_just_pressed("select_hotbar_element_" + str(index + 1), true): continue
		element_selection_index = index
		selected_element = elements_possible[element_selection_index]
	if Input.is_action_pressed("control") or Input.is_action_pressed("shift"): return
	if Input.is_action_just_pressed("hotbar_scroll_up"):
		scroll_element(-1)
	if Input.is_action_just_pressed("hotbar_scroll_down"):
		scroll_element(1)

func _unhandled_input(event: InputEvent) -> void:
	Simulation.on_unhandled_input(event)
	if event.is_action_released("spawn_atom", true):
		$World.spawn_atom()
	elif event.is_action_pressed("ui_cancel"):
		SignalBus.show_title_screen.emit()

func scroll_element(delta: int) -> void:
	element_selection_index = wrapi(element_selection_index + delta, 0, elements_possible_count)
	selected_element = elements_possible[element_selection_index]
