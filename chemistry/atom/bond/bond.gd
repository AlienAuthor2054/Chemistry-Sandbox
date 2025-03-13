class_name Bond extends Node2D

const ATOM_BOND_LINE_SCENE = preload("uid://cqiykungxfadm")

var order: int
var energy: float
var _atom: Atom
var _other: Atom
var lines: Array[Polygon2D] = []
var deleting := false

@warning_ignore("shadowed_variable")
static func get_energy(atom1: Atom, atom2: Atom, order: int) -> float:
	if order == 0: return 0.0
	@warning_ignore("shadowed_variable")
	var energy: float = [100, 180, 250][order - 1]
	var en_diff := absf(atom1.electronegativity - atom2.electronegativity)
	var en_sum := atom1.electronegativity + atom2.electronegativity
	energy *= 1 + en_diff
	energy /= (atom1.radius + atom2.radius) / 200.0
	energy -= 1.0 * (en_sum ** 2.0)
	assert(energy > 0, "Bond energy should be more than zero")
	return energy

@warning_ignore("shadowed_variable")
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
	energy = get_energy(_atom, _other, order)
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
