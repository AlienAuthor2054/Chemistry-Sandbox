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

class_name AtomImager extends SubViewport

const IMAGER_SCENE = preload("uid://cos1dm2stta20")

signal atom_node_ready

@onready var atom_node := $AtomNode

static func from_saved_atom_set(save: SavedAtomSet) -> Image:
	var imager := await create_imager()
	return await imager.capture_saved_set(save)

static func capture_single(atomic_number: int) -> Image:
	var imager := await create_imager()
	imager.size = Vector2i(200, 200)
	Atom.create(imager.atom_node, atomic_number, Vector2.ZERO)
	return await imager.capture()

static func create_imager() -> AtomImager:
	var imager: AtomImager = IMAGER_SCENE.instantiate()
	Global.MAIN_NODE.add_child.call_deferred(imager)
	await imager.atom_node_ready
	return imager

func _ready() -> void:
	atom_node_ready.emit()

func capture_saved_set(save: SavedAtomSet) -> Image:
	size = Vector2i(save.save_rect.size)
	save.spawn($AtomNode, Vector2.ZERO, true)
	var image = await capture()
	return image

func capture() -> Image:
	await get_tree().process_frame
	await get_tree().process_frame
	var image: Image = get_texture().get_image()
	queue_free()
	return image
