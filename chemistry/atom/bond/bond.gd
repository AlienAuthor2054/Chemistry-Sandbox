class_name Bond extends Node2D

const ATOM_BOND_LINE_SCENE = preload("uid://cqiykungxfadm")

var order := 1
var atom: Atom
var other: Atom
var lines: Array[Polygon2D] = []
var deleting := false

@warning_ignore("shadowed_variable")
func initialize(atom: Atom, other: Atom, order: int):
	self.atom = atom
	self.other = other
	update_order(order)

func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE: return
	deleting = true
	process_mode = PROCESS_MODE_DISABLED

func update_order(new_order: int) -> void:
	order = new_order
	lines.clear()
	for line: Polygon2D in self.get_children():
		line.queue_free()
	var y_offset := (order - 1) / 2.0
	for index in range(order):
		var line: Polygon2D = ATOM_BOND_LINE_SCENE.instantiate()
		line.position = Vector2(0, 30 * (index - y_offset))
		add_child(line)
		lines.append(line)

func _physics_process(_delta: float) -> void:
	if deleting == true: return
	var difference := other.position - atom.position
	var distance := difference.length()
	var direction := difference.normalized()
	rotation = atan2(direction.y, direction.x)
	scale = Vector2(distance / 100, 1)
