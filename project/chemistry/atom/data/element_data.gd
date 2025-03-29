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

class_name ElementData extends Resource

const BASE_ATOM_TEXTURE := preload("uid://c3yioj1c7fjka")

@export var atomic_number: int
@export var symbol: String
@export var name: String
@export var mass: float
@export var radius: float
@export var electronegativity: float
@export var color: Color

var texture: GradientTexture2D
var collision_shape: CollisionShape2D

func initialize() -> void:
	texture = BASE_ATOM_TEXTURE.duplicate(true)
	texture.gradient.set_color(0, color)
