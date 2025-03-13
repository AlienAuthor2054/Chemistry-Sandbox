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
	var energy: float = 100
	# Electronegativity difference -> Ionic character (strengthens)
	energy += 40 * (absf(atom1.electronegativity - atom2.electronegativity) ** 2)
	# Bond order -> Bonded electrons (strengthens)
	energy *= [1.0, 1.8, 2.4][order - 1]
	# Unbonded electron repulsion (weakens)
	# TODO: Consider external bonds. With that, external changes can affect bond energy, which CBM does not currently support.
	energy -= 1.0 * (atom1.electrons - order) * (atom2.electrons - order)
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
		var line_width_scale = energy / order / 64
		line.position = Vector2(0, (16 + (line_width_scale * 16)) * (index - y_offset))
		line.scale = Vector2(1, line_width_scale)
		add_child(line)
		lines.append(line)

func update_transform() -> void:
	if deleting == true: return
	var difference := _other.position - _atom.position
	var distance := difference.length()
	var direction := difference.normalized()
	rotation = atan2(direction.y, direction.x)
	scale = Vector2(distance / 100, 1)
