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

class_name Atom extends RigidBody2D

const ATOM_SCENE = preload("uid://b8mej4rmqjbp3")
const ATOM_BOND_SCENE = preload("uid://d1awp4hbumust")
const SPEED_LIMIT := 3000.0
const BOND_STIFFNESS := 0.03
const BOND_STRENGTH := 30000
const MAX_FORCE := SPEED_LIMIT * 300

static var LOCK := Lock.new()
static var next_id := 1
static var atom_id_register: Dictionary[int, Atom] = {}
static var atom_visual_radius_multi := 0.5

@warning_ignore("unused_signal")
signal electronAdded
@warning_ignore("unused_signal")
signal electronLost
signal dirty
signal atom_removing(atom: Atom)

enum {NONE, SELF, OTHER, BOTH, ID_PRIORITY}

var id: int
var protons: int
var symbol: String
var bonds: Dictionary[Atom, Bond] = {}
var bonds_order: Dictionary[Atom, int]:
	get:
		var result: Dictionary[Atom, int] = {}
		for atom: Atom in bonds:
			result[atom] = bonds[atom].order
		return result 
var valence_shell: ValenceShell
var repulsion_force: float = 5000
var bonding_radius: float = 175
var field_radius: float = 175
var atoms_in_field: Array[Atom] = []
var atoms_in_molecule_checked: Array[Atom] = []
var atoms_outside_molecule_checked := AtomSignalSet.new(_on_other_molecule_dirty, true)
var element_data: ElementData
var molecule: Molecule:
	set(new_mol):
		if is_instance_valid(molecule) and not removing:
			molecule.dirty.disconnect(_on_molecule_dirty)
		new_mol.dirty.connect(_on_molecule_dirty)
		molecule = new_mol
var bond_order: int:
	get:
		return bonds.values().reduce(func(total: int, bond: Bond): return total + bond.order, 0)
var valence_count: int:
	get: return valence_shell.count
var valence_left: int:
	get: return valence_shell.max
var bonds_left: int:
	get: return valence_left - bond_order
var bond_changed_event_queue: Array[BondChangedEvent] = []
var removing := false
var frozen := false
var frozen_velocity := Vector2.ZERO

@onready var max_bonds: int = valence_shell.left
@onready var electronegativity: float = element_data.electronegativity
@onready var radius: float = element_data.radius
@onready var visual_radius: float = radius * atom_visual_radius_multi

static func create(parent: Node, atomic_number: int, pos: Vector2, vel: Vector2 = Vector2.ZERO) -> Atom:
	var atom: Atom = ATOM_SCENE.instantiate()
	atom.initialize(atomic_number, pos, vel)
	parent.add_child(atom)
	return atom

static func get_id_priority(atom1: Atom, atom2: Atom):
	return atom1 if atom1.id < atom2.id else atom2

func initialize(atomic_number: int, pos: Vector2, vel: Vector2):
	id = next_id
	next_id += 1
	protons = atomic_number
	element_data = ElementDB.get_data(protons)
	symbol = element_data.symbol
	mass = protons * 2 if protons > 1 else protons
	valence_shell = ValenceShell.new(protons)
	$SymbolLabel.text = symbol
	$SymbolLabel.add_theme_font_size_override("font_size", element_data.radius * 0.6)
	$IdLabel.text = str(id)
	#print("%s: %s" % [protons, orbital_set.get_total_energy()])
	#print(Combination.combos(range(1, 3+1), 2))
	#print(Combination.combos_range(range(1, 4+1)))
	position = pos
	add_to_group("atoms")
	atom_id_register[id] = self
	molecule = Molecule.new([self])
	if Simulation.running:
		apply_central_impulse(vel)
	else:
		frozen_velocity = vel
	on_simulation_running_changed(Simulation.running)
	Simulation.running_changed.connect(on_simulation_running_changed)

func _to_string() -> String:
	return "%s(%s)" % [symbol, id]

func get_kinetic_energy() -> float:
	return mass * linear_velocity.length() ** 2 / 2000

func add_kinetic_energy(energy: float) -> void:
	var speed := linear_velocity.length()
	var impulse := sqrt(2000 * (get_kinetic_energy() + energy)) - speed
	var direction := linear_velocity.normalized() if speed > 0 else Vector2(1, 0)
	apply_central_impulse(direction * impulse)

func multiply_velocity(factor):
	if frozen:
		frozen_velocity *= factor
	else:
		apply_central_impulse(mass * linear_velocity * (factor - 1))

func set_velocity(vel: Vector2):
	if frozen:
		frozen_velocity = vel
	else:
		apply_central_impulse(mass * (vel - linear_velocity))

func execute_bond_changed_event_queue(emit_atom_dirty: int = ID_PRIORITY, emit_mol_dirty: bool = true) -> void:
	for bond_changed_event: BondChangedEvent in bond_changed_event_queue.duplicate():
		bond_changed_event.execute(emit_atom_dirty, emit_mol_dirty)
		bond_changed_event_queue.erase(bond_changed_event)

@warning_ignore("shadowed_variable")
func bond_atom(other: Atom, bond_order: int = 1, broadcast_dirty_event: bool = true) -> void:
	#assert(not bonds.has(other), "Atom already bonded to this atom")
	if id > other.id:
		other.bond_atom(self, bond_order, broadcast_dirty_event)
		return
	var bond: Bond
	if not bonds.has(other):
		#print("bond #%s | %s -> %s" % [bonds.size() + 1, id, other.id])
		bond = ATOM_BOND_SCENE.instantiate()
		bond.initialize(self, other, bond_order)
		self.add_child(bond)
		bonds[other] = bond
		other.bonds[self] = bond
		molecule.merge(self, other)
	else:
		bond = bonds[other]
	bond.update_order(bond_order)
	var bond_changed_event := BondChangedEvent.new(self, other, false)
	if broadcast_dirty_event:
		bond_changed_event.execute()
	else:
		bond_changed_event_queue.append(bond_changed_event)

func unbond_atom(other: Atom, chemical: bool = true, broadcast_dirty_event: bool = true) -> void:
	#assert(bonds.has(other), "Atom not bonded to this atom")
	if not bonds.has(other):
		return
	if id > other.id:
		other.unbond_atom(self, chemical, broadcast_dirty_event)
		return
	(bonds[other] as Bond).free()
	bonds.erase(other)
	other.bonds.erase(self)
	molecule.split(self, other)
	var bond_changed_event := BondChangedEvent.new(self, other, not chemical)
	if broadcast_dirty_event:
		bond_changed_event.execute()
	else:
		bond_changed_event_queue.append(bond_changed_event)
	#print(str(id) + " unbonded with " + str(other.id))

func unbond_all() -> void:
	#print(str(id) + " start unbond all")
	if bonds.is_empty(): return
	var bonded_atoms: Array = bonds.keys()
	for other: Atom in bonded_atoms:
		unbond_atom(other, false, false)
	execute_bond_changed_event_queue(BOTH)
	for other: Atom in bonded_atoms:
		other.execute_bond_changed_event_queue(BOTH)
	#print(str(id) + " end unbond all")	

@warning_ignore("shadowed_variable")
func get_bond_energy(other: Atom, bond_order: int) -> float:
	return Bond.get_energy(self, other, bond_order)

func get_bond_order(other: Atom) -> int:
	if not bonds.has(other): return 0
	return bonds[other].order

@warning_ignore("shadowed_variable")
func set_bond_order(other: Atom, bond_order: int, broadcast_dirty_event: bool = false):
	if bond_order == 0:
		unbond_atom(other, true, broadcast_dirty_event)
	else:
		bond_atom(other, bond_order, broadcast_dirty_event)

func get_max_bond_order(other: Atom) -> int:
	return mini(3, mini(bonds_left, other.bonds_left) + get_bond_order(other))

func get_isolated_max_bond_order(other: Atom) -> int:
	return mini(3, mini(max_bonds, other.max_bonds))

func evaluate_field(emit_dirty: bool = true) -> void:
	for other in atoms_in_field:
		# TODO: Allow intramolecular bonding (rings)
		if id > other.id: continue
		#if id > other.id or molecule.id == other.molecule.id: continue
		if molecule.id == other.molecule.id:
			if other in atoms_in_molecule_checked: continue
			atoms_in_molecule_checked.append(other)
		else:
			if atoms_outside_molecule_checked.has(other): continue
			atoms_outside_molecule_checked.add(other.dirty)
		CascadingBondsModel.new(emit_dirty).from_bonding_pair(self, other)

func atom_list_to_ids(_accum, _atom_list: Array[Atom]) -> Array[int]:
	return [1]

func atoms_in_field_changed(new_atoms_in_field: Array[Atom]) -> bool:
	if atoms_in_field.size() != new_atoms_in_field.size():
		return true
	return atoms_in_field.hash() != new_atoms_in_field.hash()

func select() -> void:
	$Selection.visible = true

func deselect() -> void:
	$Selection.visible = false

func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE: return
	removing = true
	if molecule.dirty.is_connected(_on_molecule_dirty):
		molecule.dirty.disconnect(_on_molecule_dirty)
	atom_removing.emit(self)
	unbond_all()
	atom_id_register.erase(id)
	remove_from_group("atoms")

func on_simulation_running_changed(running: bool) -> void:
	set_physics_process(running)
	frozen = not running
	if frozen:
		frozen_velocity += linear_velocity
		linear_velocity = Vector2.ZERO
	else:
		apply_central_impulse(frozen_velocity * mass)
		frozen_velocity = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if frozen: return
	var force_list = AdderDict.new()
	var new_atoms_in_field: Array[Atom] = []
	# TODO: Consider using signals
	for other: Atom in $AtomField.get_overlapping_bodies():
		if other == self or other.removing: continue
		var difference := other.position - position
		var direction := difference.normalized()
		var distance := difference.length()
		if distance > field_radius: continue
		if distance <= bonding_radius:
			new_atoms_in_field.append(other)
		if other.id < id: continue
		var force: Vector2
		if is_zero_approx(distance):
			force = RNGUtil.new(RandomNumberGenerator.new()).unit_vec() * 1000
		elif not other in bonds:
			var vdw_distance := radius + other.radius
			if distance < vdw_distance:
				force = minf(MAX_FORCE, repulsion_force * mass * other.mass / (mass + other.mass)
						/ ((distance / vdw_distance) ** 2)) * direction
		force_list.add(other, force)
		force_list.add(self, -force)
	if atoms_in_field_changed(new_atoms_in_field):
		for prev_atom in atoms_in_field:
			if not is_instance_valid(prev_atom) or prev_atom in new_atoms_in_field: continue
			if prev_atom.dirty.is_connected(_on_field_dirty):
				prev_atom.dirty.disconnect(_on_field_dirty)
		for new_atom in new_atoms_in_field:
			if new_atom in atoms_in_field: continue
			if not new_atom.atom_removing.is_connected(_on_atom_removing):
				new_atom.atom_removing.connect(_on_atom_removing, CONNECT_ONE_SHOT)
			new_atom.dirty.connect(_on_field_dirty)
		atoms_in_field = new_atoms_in_field
		evaluate_field()
	for other: Atom in bonds:
		var bond := bonds[other]
		if other.id < id: continue
		var difference := other.position - position
		var distance := difference.length()
		if distance <= bond.max_length:
			var direction := difference.normalized()
			var factor := exp(-BOND_STIFFNESS * (distance - bond.base_length))
			var force_strength := -BOND_STRENGTH * BOND_STIFFNESS * bond.energy * factor * (factor - 1)
			var force = minf(MAX_FORCE, absf(force_strength) * bond.force_multi) * signf(force_strength) * direction
			#print(-BOND_STRENGTH * BOND_STIFFNESS * bond.energy * factor * (factor - 1))
			force_list.add(other, -force)
			force_list.add(self, force)
		else:
			unbond_atom(other, false)
	for atom: Atom in force_list.dict:
		atom.apply_central_force(force_list.dict[atom])
	if linear_velocity.length() > SPEED_LIMIT:
		set_velocity(linear_velocity.limit_length(SPEED_LIMIT))
	#$SymbolLabel.text = str(molecule.id)

func _draw() -> void:
	draw_circle(Vector2.ZERO, visual_radius, element_data.color, true, -1.0, true)

func _on_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	if Input.is_action_pressed("remove_atom", true):
		queue_free()

func _on_field_dirty() -> void:
	evaluate_field(false)

func _on_atom_removing(atom: Atom) -> void:
	if atom.dirty.is_connected(_on_field_dirty):
		atom.dirty.disconnect(_on_field_dirty)
	atoms_in_field.erase(atom)
	atoms_in_molecule_checked.erase(atom)
	if atoms_outside_molecule_checked.has(atom):
		atoms_outside_molecule_checked.erase(atom)

func _on_other_molecule_dirty(other: Atom) -> void:
	atoms_outside_molecule_checked.erase(other)

func _on_molecule_dirty() -> void:
	atoms_in_molecule_checked.clear()
	atoms_outside_molecule_checked.clear()
