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

class_name CascadingBondsModel extends RefCounted

const MAX_DEPTH := 3

var combos: Array[BondChanges] = []
var depth := 0
var _emit_dirty: bool

func _init(emit_dirty: bool = true) -> void:
	_emit_dirty = emit_dirty

func from_bonding_pair(atom1: Atom, atom2: Atom) -> void:
	if atom1.removing or atom2.removing: return
	for bond_order in range(1, atom1.get_isolated_max_bond_order(atom2) - atom1.get_bond_order(atom2) + 1):
		var bond_change := BondChange.modify_bond_order(atom1, atom2, bond_order)
		CascadingBondsModelOperation.new(combos, BondChanges.new(), bond_change, true)
	_evaluate()

func from_unbonded_atom(broken: Atom) -> void:
	if broken.removing: return
	CascadingBondsModelOperation.from_broken_atoms(combos, BondChanges.new(), broken)
	_evaluate()

func debug():
	print("\n%s combos" % [combos.size()])
	for combo in combos:
		combo.debug()

func _evaluate() -> void:
	if combos.is_empty(): return
	PerfReactions.frame_combos += combos.size()
	var winning_combo: BondChanges
	var energy_change := 0.0
	for combo in combos:
		var combo_energy := combo.energy_change
		if combo_energy >= energy_change: continue
		winning_combo = combo
		energy_change = combo_energy
	if winning_combo == null: return
	winning_combo.execute(_emit_dirty)

func _add_combo(combo: BondChanges, dupe: bool = false) -> void:
	if dupe:
		combos.append(combo.duplicate())
	else:
		combos.append(combo)

class CascadingBondsModelOperation:
	var combo_input: Array[BondChanges]
	var formed_order: int
	var depth: int
	
	@warning_ignore("shadowed_variable")
	static func from_broken_atoms(combo_input: Array[BondChanges], base_combo: BondChanges, broken: Atom) -> void:
		var bond_combos := base_combo.get_bond_form_combos(broken, 0, 3)
		for bond_combo: Dictionary in bond_combos:
			# TODO: In cases of more than one broken atom, combos only continue on one broken atom each
			var combo := base_combo.duplicate()
			for bonding: Atom in bond_combo:
				if bonding.removing: continue
				var bond_change := BondChange.modify_bond_order(broken, bonding, bond_combo[bonding], combo)
				CascadingBondsModelOperation.new(combo_input, base_combo, bond_change)
	
	@warning_ignore("shadowed_variable")
	func _init(combo_input: Array[BondChanges], base_combo: BondChanges, bond_change: BondChange, bidirectional: bool = false) -> void:
		self.combo_input = combo_input
		self.formed_order = bond_change.formed_order
		assert(formed_order >= 1, "Parameter formed_order is less than 1")
		base_combo.depth += 1
		depth = base_combo.depth
		#assert(depth <= MAX_DEPTH, "Combo depth exceeds max depth allowed")
		var go_deeper := depth < MAX_DEPTH
		var combos1 := break_bonds(base_combo, bond_change)
		if combos1.is_empty(): return
		var combos: Array[BondChanges]
		if bidirectional:
			var combos2 := break_bonds(base_combo, bond_change.dupe_and_swap())
			if combos2.is_empty(): return
			combos = BondChanges.combine_combos(combos1, combos2)
		else:
			combos = combos1
		for combo in combos:
			#print("%s existing order + %s formed" % [combo.get_bond_order(bonder, bonded), formed_order])
			combo_input.append(combo.add_change(bond_change))
			if not go_deeper: continue
			for head in combo.heads:
				CascadingBondsModelOperation.from_broken_atoms(combo_input, combo, head)
	
	func break_bonds(base_combo: BondChanges, bond_change: BondChange) -> Array[BondChanges]:
		var bonder := bond_change.atom1
		var bonded := bond_change.atom2
		var combos: Array[BondChanges] = []
		var bonds_to_break := maxi(0, formed_order - base_combo.get_atom_bonds_left(bonder))
		#print("%s <[%s]- %s: %s bonds (%s left) / %s -> %s bonds to break" % [
				#bonder.to_string(), formed_order, bonded.to_string(), 
				#base_combo.get_atom_bond_order(bonder), base_combo.get_atom_bonds_left(bonder), bonder.max_bonds,  
				#bonds_to_break, 
		#])
		if bonds_to_break > base_combo.get_atom_bond_order(bonder):
			#print("\tBond combo impossible")
			return []
		if bonds_to_break == 0:
			return [base_combo.duplicate()]
		for break_combo: Dictionary in base_combo.get_bond_break_combos(bonder, bonds_to_break, bonds_to_break, bonded):
			#print("\tBreak combo:")
			# TODO: In cases of more than one broken atom, combos only continue on one broken atom each
			var combo := base_combo.duplicate()
			var broken_atoms: Array[Atom] = []
			for broken: Atom in break_combo:
				#print("\t\t%s x%s" % [broken.to_string(), break_combo[broken]])
				combo.add(bonder, broken, combo.get_bond_order(bonder, broken) - break_combo[broken], true)
				broken_atoms.append(broken)
			combos.append(combo)
		return combos
