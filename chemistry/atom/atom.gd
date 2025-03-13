class_name Atom extends RigidBody2D

const ATOM_SCENE = preload("uid://b8mej4rmqjbp3")
const ATOM_BOND_SCENE = preload("uid://d1awp4hbumust")
const BASE_ATOM_TEXTURE: GradientTexture2D = preload("uid://c3yioj1c7fjka")

static var next_id := 1
static var atom_id_register: Dictionary[int, Atom] = {}
static var atom_db: Dictionary = YAMLParser.parse("res://chemistry/atom/atom_db.yaml")
static var atom_textures: Dictionary = {}
static var atom_visual_radius_multi = 1
static var LOCK := Lock.new()

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
var orbital_set: AtomicOrbitalSet
var bond_length: float = 175
var max_bond_length: float = bond_length * 1.75
var bond_strength: float = 1000
var repulsion_force: float = 200
var field_radius: float = 175
var interatomic_forces := true
var atoms_in_field: Array[Atom] = []
var atoms_in_molecule_checked: Array[Atom] = []
var atoms_outside_molecule_checked := AtomSignalSet.new(_on_other_molecule_dirty, true)
var this_atom_db: Dictionary
var molecule: Molecule:
	set(new_mol):
		if is_instance_valid(molecule) and not removing:
			molecule.dirty.disconnect(_on_molecule_dirty)
		new_mol.dirty.connect(_on_molecule_dirty)
		molecule = new_mol
var bond_order: int:
	get:
		return bonds.values().reduce(func(total: int, bond: Bond): return total + bond.order, 0)
var electrons: int:
	get: return orbital_set.electrons
var valence_left: int:
	get: return orbital_set.valence_max
var bonds_left: int:
	get: return valence_left - bond_order
var bond_changed_event_queue: Array[BondChangedEvent] = []
var removing := false
@onready var max_bonds: int = orbital_set.valence_left
@onready var electronegativity: float = this_atom_db.electronegativity
@onready var radius: float = this_atom_db.radius

static func create(parent: Node, atomic_number: int, pos: Vector2, vel: Vector2) -> void:
	var atom: Atom = ATOM_SCENE.instantiate()
	atom.initialize(atomic_number, pos, vel)
	parent.add_child(atom)

static func get_id_priority(atom1: Atom, atom2: Atom):
	return atom1 if atom1.id < atom2.id else atom2

static func create_textures():
	@warning_ignore("shadowed_variable")
	for protons in atom_db:
		var data: Dictionary = atom_db[protons]
		var color: Color = Color.from_string(data.color, Color.ORCHID)
		var texture: GradientTexture2D = BASE_ATOM_TEXTURE.duplicate(true)
		texture.gradient.set_color(0, color)
		atom_textures[protons] = texture

func initialize(atomic_number: int, pos: Vector2, vel: Vector2):
	id = next_id
	next_id += 1
	protons = atomic_number
	this_atom_db = atom_db[protons]
	symbol = this_atom_db.symbol
	mass = protons * 2 if protons > 1 else protons
	orbital_set = AtomicOrbitalSet.from_electron_configuration(this_atom_db.electron_configuration)
	orbital_set.parent = self
	$SymbolLabel.text = symbol
	$SymbolLabel.add_theme_font_size_override("font_size", this_atom_db.radius * 0.6)
	$IdLabel.text = str(id)
	#print("%s: %s" % [protons, orbital_set.get_total_energy()])
	#print(Combination.combos(range(1, 3+1), 2))
	#print(Combination.combos_range(range(1, 4+1)))
	$Sprite2D.scale = Vector2.ONE * this_atom_db.radius * atom_visual_radius_multi / 100
	$Sprite2D.texture = atom_textures[protons]
	if not interatomic_forces:
		bond_length = 300
		max_bond_length = bond_length * 2.0
		bond_strength = 0
		repulsion_force = 0
		field_radius = 300
	position = pos
	apply_central_impulse(vel)
	add_to_group("atoms")
	atom_id_register[id] = self
	molecule = Molecule.new([self])

func _to_string() -> String:
	return "%s(%s)" % [symbol, id]

func get_kinetic_energy() -> float:
	return mass * linear_velocity.length() ** 2 / 2000

func add_kinetic_energy(energy: float) -> void:
	var speed := linear_velocity.length()
	var impulse := sqrt(2000 * (get_kinetic_energy() + energy)) - speed
	var direction := linear_velocity.normalized() if speed > 0 else Vector2(1, 0)
	apply_central_impulse(direction * impulse)

func get_potential_energy() -> float:
	var potential_energy := 0.0
	for other: Atom in $AtomField.get_overlapping_bodies():
		if other == self: continue
		var distance := (other.position - position).length()
		if distance > field_radius: continue
		potential_energy += repulsion_force * (((1000 / maxf(distance, 10)) + (maxf(10 - distance, 0) * 10) - (1000 / field_radius)) / 2)
	for other: Atom in bonds:
		var distance := (other.position - position).length()
		potential_energy += bond_strength * ((distance - bond_length) ** 2) / 4000 
	return potential_energy

func multiply_velocity(factor):
	apply_central_impulse(mass * linear_velocity * (factor - 1))

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
	var difference := other.position - position
	var _direction := difference.normalized()
	var distance := difference.length()
	var _potential_energy := bond_strength * ((minf(distance, max_bond_length) - bond_length) ** 2) / 4000
	
	# Offset to prevent temperature spiral, most likely from physics inaccuracy
	
	#potential_energy -= 7.5
	
	#add_kinetic_energy(potential_energy)
	#other.add_kinetic_energy(potential_energy)
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

func remove() -> void:
	removing = true
	molecule.dirty.disconnect(_on_molecule_dirty)
	atom_removing.emit(self)
	unbond_all()
	atom_id_register.erase(id)
	remove_from_group("atoms")
	queue_free()

func _physics_process(_delta: float) -> void:
	var force_list = AdderDict.new()
	var new_atoms_in_field: Array[Atom] = []
	# TODO: Consider using signals
	for other: Atom in $AtomField.get_overlapping_bodies():
		if other == self or other.removing: continue
		var difference := other.position - position
		var direction := difference.normalized()
		var distance := difference.length()
		if distance > field_radius: continue
		if distance <= bond_length:
			new_atoms_in_field.append(other)
		if other.id < id: continue
		var force = (repulsion_force * direction * 1000000) / (maxf(distance, 50) ** 2)
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
	for other: Atom in bonds.keys():
		if other.id < id: continue
		var difference := other.position - position
		var distance := difference.length()
		if distance <= max_bond_length:
			var direction := difference.normalized()
			var force := bond_strength * direction * (distance - bond_length)
			force_list.add(other, -force)
			force_list.add(self, force)
		else:
			unbond_atom(other, false)
	for atom: Atom in force_list.dict:
		atom.apply_central_force(force_list.dict[atom])
	#$SymbolLabel.text = str(molecule.id)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			remove()

func _on_visible_on_screen_notifier_screen_exited() -> void:
	remove()

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
