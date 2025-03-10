class_name BondChanges extends RefCounted

static var EMPTY = BondChanges.new()

# Don't forget to add new properties to the duplicate method!
var changes: Array = []
var energy_change := 0.0
var activation_energy := 0.0
var affected_atoms: Dictionary[Atom, Dictionary] = {} # {Atom: {Atom: int}}
var depth := 0
var operation := 0
var heads: Array[Atom] = []

static func init_and_add(atom1: Atom, atom2: Atom, new_order: int) -> BondChanges:
	return BondChanges.new().add(atom1, atom2, new_order)

static func _sort_combos_callable(combo1: BondChanges, combo2: BondChanges) -> bool:
	if not is_equal_approx(combo1.energy_change, combo2.energy_change):
		return combo1.energy_change < combo2.energy_change
	if not is_equal_approx(combo1.activation_energy, combo2.activation_energy):
		return combo1.activation_energy < combo2.activation_energy
	return combo1.changes.size() < combo1.changes.size()

static func sort_combos(combos: Array[BondChanges]):
	combos.sort_custom(_sort_combos_callable)

static func combine_combos(combos1: Array[BondChanges], combos2: Array[BondChanges]) -> Array[BondChanges]:
	var combined_combos: Array[BondChanges] = []
	for combo1 in combos1:
		for combo2 in combos2:
			var combined_combo := combo1.duplicate().add_combo(combo2)
			var combined_heads := combo1.heads.duplicate()
			combined_heads.append_array(combo2.heads)
			combined_combo.set_heads(combined_heads)
			combined_combos.append(combined_combo)
	return combined_combos

func add(atom1: Atom, atom2: Atom, new_order: int, head: bool = false) -> BondChanges:
	assert(new_order >= 0, "Invalid bond change: Parameter new_order is less than 0")
	return add_change(BondChange.set_bond_order(atom1, atom2, new_order, self), head, atom1, atom2, new_order)

func add_change(bond_change: BondChange, head: bool = false, atom1: Atom = bond_change.atom1, atom2: Atom = bond_change.atom2, new_order: int = bond_change.new_order) -> BondChanges:
	bond_change.parent = self
	changes.append(bond_change)
	energy_change += bond_change.energy_change
	activation_energy = maxf(energy_change, activation_energy)
	_change_atom_bonds(atom1, atom2, new_order)
	_change_atom_bonds(atom2, atom1, new_order)
	if head:
		heads.append(atom2)
	return self

func add_combo(combo: BondChanges) -> BondChanges:
	for change in combo.changes:
		add_change(change.duplicate())
	return self

func dupe_and_add_combo(combo: BondChanges) -> BondChanges:
	return duplicate().add_combo(combo)

# Don't forget to use the duplicate() method of arrays and dictionaries! May need to pass true as param if deep
func duplicate() -> BondChanges:
	var new := BondChanges.new()
	new.changes = changes.map(func(change: BondChange): return change.duplicate(new)) as Array[BondChange]
	new.energy_change = energy_change
	new.activation_energy = activation_energy
	new.affected_atoms = affected_atoms.duplicate(true)
	new.depth = depth
	new.operation = operation
	return new

func dupe_and_add(atom1: Atom, atom2: Atom, new_order: int) -> BondChanges:
	return duplicate().add(atom1, atom2, new_order)

func set_heads(new_heads: Array[Atom]) -> void:
	heads.assign(new_heads)

func clear_heads() -> void:
	heads.clear()
	
func execute(emit_dirty: bool = true):
	var emit_atom_dirty := Atom.BOTH if emit_dirty else Atom.NONE
	Atom.LOCK.lock(self)
	for change in changes:
		change.execute()
	Atom.LOCK.unlock(self)
	for atom: Atom in affected_atoms:
		atom.execute_bond_changed_event_queue(emit_atom_dirty, emit_dirty)

func get_atom_bonds(atom: Atom) -> Dictionary[Atom, int]:
	return affected_atoms[atom] if affected_atoms.has(atom) else atom.bonds_order

func get_bond_order(atom: Atom, other: Atom) -> int:
	if affected_atoms.has(atom):
		var bonds := get_atom_bonds(atom)
		return bonds[other] if bonds.has(other) else atom.get_bond_order(other)
	return atom.get_bond_order(other)

func get_atom_bond_order(atom: Atom) -> int:
	return Util.sumi_dict_values(get_atom_bonds(atom))

func get_atom_bonds_left(atom: Atom) -> int:
	return atom.max_bonds - get_atom_bond_order(atom)

func get_max_bond_order(atom: Atom, other: Atom) -> int:
	return mini(3, mini(get_atom_bonds_left(atom), get_atom_bonds_left(other)) + get_bond_order(atom, other))

func get_bond_break_combos(atom: Atom, min_bonds: int, max_bonds: int, excluded_atom: Atom) -> Array:
	var bonds := get_atom_bonds(atom)
	var bonds_array: Array[Atom] = []
	var excluded_id := excluded_atom.id
	for other: Atom in bonds:
		if other.id == excluded_id or other in affected_atoms: continue
		for _i in range(mini(max_bonds, bonds[other])):
			bonds_array.append(other)
	return _get_bond_combos(bonds_array, min_bonds, max_bonds)

func get_bond_form_combos(atom: Atom, min_bonds: int, max_bonds: int) -> Array:
	if atom.removing: return []
	var bonds := get_atom_bonds(atom)
	var bonds_array: Array[Atom] = []
	max_bonds = mini(max_bonds, get_atom_bonds_left(atom))
	for other: Atom in atom.atoms_in_field:
		if other in bonds: continue
		bonds[other] = 0
	for other: Atom in bonds:
		if other in affected_atoms or other.removing: continue
		for _i in range(mini(max_bonds, get_max_bond_order(atom, other) - bonds[other])):
			bonds_array.append(other)
	return _get_bond_combos(bonds_array, min_bonds, max_bonds)

func debug():
	print("\tEnergy change: %s" % [roundi(energy_change)])
	for change in changes:
		print("\t\t" + change.to_string())

func _get_bond_combos(bonds_array: Array[Atom], min_bonds: int, max_bonds: int) -> Array:
	var bond_count := bonds_array.size()
	if bond_count < min_bonds:
		return []
	return Combination.combos_range_counts(bonds_array, min_bonds, max_bonds)

func _change_atom_bonds(atom: Atom, other: Atom, bond_order: int) -> void:
	var bonds := get_atom_bonds(atom)
	bonds[other] = bond_order
	affected_atoms[atom] = bonds
