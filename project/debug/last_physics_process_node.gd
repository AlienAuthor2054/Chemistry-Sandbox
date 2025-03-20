class_name LastPhysicsProcessNode extends Node

signal physics_process

func _init(parent: Node) -> void:
	process_physics_priority = 999
	parent.add_child(self)

func _physics_process(_delta: float) -> void:
	physics_process.emit()
