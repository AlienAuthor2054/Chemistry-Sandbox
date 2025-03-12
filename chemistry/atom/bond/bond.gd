class_name Bond extends Node2D

const ATOM_BOND_LINE_SCENE = preload("uid://cqiykungxfadm")

var order := 1
var _atom: Atom
var _other: Atom
var lines: Array[Polygon2D] = []
var deleting := false

func initialize(atom: Atom, other: Atom, order: int):
	_atom = atom
	_other = other
	update_order(order)
	update_transform()
	reset_physics_interpolation()

func _physics_process(_delta: float) -> void:
	update_transform()

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

func update_transform() -> void:
	if deleting == true: return
	var difference := _other.position - _atom.position
	var distance := difference.length()
	var direction := difference.normalized()
	rotation = atan2(direction.y, direction.x)
	scale = Vector2(distance / 100, 1)
