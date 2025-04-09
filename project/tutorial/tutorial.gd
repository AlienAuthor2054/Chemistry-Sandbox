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

extends Window

var stages: Array[TutorialStage] = []
var stage_count: int
var active_stage_num: int
var active_stage: TutorialStage

func _ready() -> void:
	for stage: TutorialStage in $Stages.get_children():
		stages.append(stage)
	stage_count = stages.size()
	SignalBus.start_tutorial.connect(start)
	SignalBus.show_title_screen.connect(func(): visible = false)

func start() -> void:
	active_stage_num = 1
	update()
	visible = true

func update() -> void:
	%BackButton.disabled = active_stage_num <= 1
	%NextButton.text = "Next" if active_stage_num < stage_count else "Finish"
	active_stage = stages[active_stage_num - 1]
	%Label.text = active_stage.text
	%StageNum.text = "%s / %s" % [active_stage_num, stage_count]

func _on_back_button_pressed() -> void:
	if active_stage_num <= 1:
		visible = false
		return
	active_stage_num -= 1
	update()

func _on_next_button_pressed() -> void:
	if active_stage_num >= stage_count:
		visible = false
		return
	active_stage_num += 1
	update()
