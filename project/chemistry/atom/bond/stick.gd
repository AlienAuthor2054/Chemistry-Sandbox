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

class_name Stick extends RigidBody2D

const SCENE = preload("res://chemistry/atom/bond/stick.tscn")

var stiffness: float = 1000
var damping: float = 50
var atom1: Atom
var atom2: Atom
var reduced_mass: float
var length: float
var motor_enabled := false

@onready var pin: PinJoint2D = $PinJoint
@onready var groove: GrooveJoint2D = $GrooveJoint

@warning_ignore("shadowed_variable")
static func bond(atom1: Atom, atom2: Atom, length: float) -> Stick:
	var stick: Stick = SCENE.instantiate()
	atom1.add_sibling(stick)
	stick.atom1 = atom1
	stick.atom2 = atom2
	stick.reduced_mass = (atom1.mass * atom2.mass) / (atom1.mass + atom2.mass)
	stick.length = length
	stick.initialize()
	stick.motor_enabled = true
	return stick

func initialize() -> void:
	position = (atom2.position + atom1.position) / 2
	look_at(atom2.position)
	var distance := (atom2.position - atom1.position).length()
	pin.position.x = -distance / 2
	groove.position.x = -distance / 2
	groove.initial_offset = distance
	connect_joints()

func replace_joint(joint: PinJoint2D, x_pos: float) -> PinJoint2D:
	#joint.queue_free()
	#joint = PinJoint2D.new()
	joint.position.x = x_pos
	#add_child(joint)
	return joint

func _physics_process(_delta: float) -> void:
	if not motor_enabled: return
	var difference := atom2.position - atom1.position
	var length_error := length - difference.length()
	var direction := difference.normalized()
	var damp := (atom2.linear_velocity - atom1.linear_velocity).dot(direction) * damping
	var force := (length_error * stiffness - damp) * reduced_mass * direction
	atom2.apply_central_force(force)
	apply_central_force(-force)

#func set_length(length: float) -> void:
	#print("Set length ", length)
	#var center := (atom1.position + atom2.position) / 2
	#var direction := (atom2.position - atom1.position).normalized()
	#var half := length / 2
	#disconnect_joints()
	#await wait(0.5)
	#set_Atom_pos(atom1, center + direction * half)
	#set_Atom_pos(atom2, center - direction * half)
	#await wait(0.5)
	#teleport_joint_x(joint1, -half)
	#teleport_joint_x(joint2, half)
	#await wait(0.5)
	#connect_joints() 

func connect_joints() -> void:
	pin.node_a = self.get_path()
	pin.node_b = atom1.get_path()
	groove.node_a = self.get_path()
	groove.node_b = atom2.get_path()

func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout
