class_name BondChange extends RefCounted

var atom1: Atom
var atom2: Atom
var prev_order: int
var new_order: int
var formed_order: int:
	get: return new_order - prev_order
var energy_change: float
var parent: BondChanges

@warning_ignore("shadowed_variable")
static func modify_bond_order(atom1: Atom, atom2: Atom, order_mod: int, parent: BondChanges = BondChanges.EMPTY) -> BondChange:
	var new := BondChange.new(atom1, atom2, parent)
	@warning_ignore("shadowed_variable")
	var prev_order = parent.get_bond_order(atom1, atom2)
	@warning_ignore("shadowed_variable")
	var new_order = prev_order + order_mod
	new.prev_order = prev_order
	new.new_order = new_order
	new.energy_change = atom1.get_bond_energy(atom2, prev_order) - atom1.get_bond_energy(atom2, new_order)
	return new

@warning_ignore("shadowed_variable")
static func set_bond_order(atom1: Atom, atom2: Atom, new_order: int, parent: BondChanges = BondChanges.EMPTY) -> BondChange:
	var new := BondChange.new(atom1, atom2, parent)
	@warning_ignore("shadowed_variable")
	var prev_order = parent.get_bond_order(atom1, atom2)
	new.prev_order = prev_order
	new.new_order = new_order
	new.energy_change = atom1.get_bond_energy(atom2, prev_order) - atom1.get_bond_energy(atom2, new_order)
	return new

@warning_ignore("shadowed_variable")
func _init(atom1: Atom, atom2: Atom, parent: BondChanges = BondChanges.EMPTY) -> void:
	self.atom1 = atom1
	self.atom2 = atom2
	self.parent = parent

func _to_string() -> String:
	return "%s - [%s -> %s] - %s | %s" % [atom1.to_string(), prev_order, new_order, atom2.to_string(), roundi(energy_change)]

func duplicate(new_parent: BondChanges = parent) -> BondChange:
	var new = BondChange.new(atom1, atom2, new_parent)
	new.prev_order = prev_order
	new.new_order = new_order
	new.energy_change = energy_change
	return new

func swap() -> BondChange:
	var old_atom1 := atom1
	atom1 = atom2
	atom2 = old_atom1
	return self

func dupe_and_swap() -> BondChange:
	return duplicate().swap()

func execute():
	atom1.set_bond_order(atom2, new_order)
