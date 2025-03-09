class_name Molecule extends RefCounted

signal dirty

static var next_id := 1

var id: int
var atoms: Array[Atom] = []

func _init(init_atoms: Array[Atom]) -> void:
	id = next_id
	next_id += 1
	atoms.assign(init_atoms)
	dirty.emit()

class MoleculeGetter:
	var atoms: Array[Atom] = []
	var origin_loop := false
	var excluded_atom_included := false
	
	var _origin_atom: Atom
	var _excluded_atom: Atom
	
	func _init(origin_atom: Atom, excluded_atom: Atom) -> void:
		_origin_atom = origin_atom
		_excluded_atom = excluded_atom
		atoms.clear()
		_poll_bonds(origin_atom, excluded_atom)
	
	func _poll_bonds(atom: Atom, last_atom: Atom) -> void:
		atoms.append(atom)
		for other: Atom in atom.bonds:
			if other == last_atom: continue
			if other == _origin_atom:
				origin_loop = true
				continue
			if other == _excluded_atom:
				excluded_atom_included = true
				continue
			if other in atoms: continue
			_poll_bonds(other, atom)

func split(staying_atom: Atom, leaving_atom: Atom) -> void:
	assert(staying_atom.molecule.id == leaving_atom.molecule.id, "Atoms are not in the same molecule")
	var leaving_mol_data := MoleculeGetter.new(leaving_atom, staying_atom)
	if leaving_mol_data.excluded_atom_included: return
	var leaving_atoms: Array[Atom] = leaving_mol_data.atoms
	var leaving_mol := Molecule.new(leaving_atoms)
	for atom in leaving_atoms:
		atoms.erase(atom)
		atom.molecule = leaving_mol

func merge(merger_atom: Atom, merged_atom: Atom) -> void:
	assert(merger_atom.molecule.id == id, "Merger atom is not in this molecule")
	if merged_atom.molecule.id == id: return
	var merged_mol_data := MoleculeGetter.new(merged_atom, merger_atom)
	assert(not merged_mol_data.excluded_atom_included, "Internal molecule error: Molecules of atoms are already merged")
	var merged_mol := merged_atom.molecule
	var merged_atoms := merged_mol.atoms
	atoms.append_array(merged_atoms)
	for atom in merged_atoms:
		atom.molecule = self
	merged_mol.atoms.clear()
