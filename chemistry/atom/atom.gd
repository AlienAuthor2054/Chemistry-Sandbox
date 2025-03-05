class_name Atom extends RigidBody2D

@export var atom_bond_scene: PackedScene

const BASE_ATOM_TEXTURE: GradientTexture2D = preload("res://chemistry/atom/atom_texture.tres")

static var next_id := 1
static var atom_id_register: Dictionary[int, Atom]= {}
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

enum {SELF, OTHER, BOTH, ID_PRIORITY}

var id: int
var protons: int
var symbol: String
var bonds: Dictionary[Atom, AtomBond] = {}
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
var this_atom_db: Dictionary
var molecule: Molecule:
	set(new_mol):
		if molecule != null:
			molecule.dirty.disconnect(_on_molecule_dirty)
		new_mol.dirty.connect(_on_molecule_dirty)
		molecule = new_mol
var bond_order: int:
	get:
		return bonds.values().reduce(func(total: int, bond: AtomBond): return total + bond.order, 0)
var valence_left: int:
	get: return orbital_set.valence_max
var bonds_left: int:
	get: return valence_left - bond_order
var bond_changed_event_queue: Array[BondChangedEvent] = []
var removing := false
@onready var max_bonds: int = orbital_set.valence_left
@onready var electronegativity: float = this_atom_db.electronegativity
@onready var radius: float = this_atom_db.radius

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

func initialize(atomic_number, clicked_point, velocity):
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
	position = clicked_point
	apply_central_impulse(velocity)
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

func execute_bond_changed_event_queue(emit_dirty: int = ID_PRIORITY) -> void:
	for bond_changed_event: BondChangedEvent in bond_changed_event_queue.duplicate():
		bond_changed_event.execute(emit_dirty)
		bond_changed_event_queue.erase(bond_changed_event)

class BondChangedEvent:
	var _atom: Atom
	var _other: Atom
	var _broadcast_unbond_event: bool
		
	func _init(atom: Atom, other: Atom, broadcast_unbond_event: bool = false) -> void:
		_atom = atom
		_other = other
		_broadcast_unbond_event = broadcast_unbond_event
	
	func execute(emit_dirty: int = ID_PRIORITY) -> void:
		#Atom.LOCK.lock(self)
		if emit_dirty == ID_PRIORITY:
			Atom.get_id_priority(_atom, _other).dirty.emit()
		else:
			if emit_dirty != OTHER:
				_atom.dirty.emit()
			if emit_dirty != SELF:
				_other.dirty.emit()
		#Atom.LOCK.unlock(self)
		#if _broadcast_unbond_event:
		_atom.molecule.dirty.emit()
		if _atom.molecule.id != _other.molecule.id:
			_other.molecule.dirty.emit()
		if _broadcast_unbond_event and _atom.molecule.id != _other.molecule.id:
			CascadingBondsModel.new().from_unbonded_atom(_atom)
			CascadingBondsModel.new().from_unbonded_atom(_other)
		

@warning_ignore("shadowed_variable")
func bond_atom(other: Atom, bond_order: int = 1, broadcast_dirty_event: bool = true) -> void:
	#assert(not bonds.has(other), "Atom already bonded to this atom")
	if id > other.id:
		other.bond_atom(self, bond_order, broadcast_dirty_event)
		return
	var bond: AtomBond
	if not bonds.has(other):
		#print("bond #%s | %s -> %s" % [bonds.size() + 1, id, other.id])
		bond = atom_bond_scene.instantiate()
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
	(bonds[other] as AtomBond).free()
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
	if bond_order == 0: return 0.0
	var bond_energy: float = [100, 180, 250][bond_order - 1]
	var en_diff := absf(electronegativity - other.electronegativity)
	var en_sum := electronegativity + other.electronegativity
	bond_energy *= 1 + en_diff
	bond_energy /= (radius + other.radius) / 200.0
	bond_energy -= 1.0 * (en_sum ** 2.0)
	assert(bond_energy > 0, "Bond energy should be more than zero")
	return bond_energy

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

class BondChange:
	var atom1: Atom
	var atom2: Atom
	var prev_order: int
	var new_order: int
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
	
	func duplicate() -> BondChange:
		var new = BondChange.new(atom1, atom2, parent)
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

class BondChanges:
	static var EMPTY = BondChanges.new()
	
	# Don't forget to add new properties to the duplicate method!
	var changes: Array[BondChange] = []
	var energy_change := 0.0
	var activation_energy := 0.0
	var affected_atoms: Dictionary[Atom, Dictionary] = {} # {Atom: {Atom: int}}
	var depth := 0
	var operation := 0
	
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
				combined_combos.append(combo1.duplicate().add_combo(combo2))
		return combined_combos
	
	func add(atom1: Atom, atom2: Atom, new_order: int) -> BondChanges:
		assert(new_order >= 0, "Invalid bond change: Parameter new_order is less than 0")
		return _add(BondChange.set_bond_order(atom1, atom2, new_order), atom1, atom2, new_order)
	
	func add_combo(combo: BondChanges) -> BondChanges:
		for change in combo.changes:
			_add(change)
		return self
	
	func dupe_and_add_combo(combo: BondChanges) -> BondChanges:
		return duplicate().add_combo(combo)
	
	# Don't forget to use the duplicate() method of arrays and dictionaries! May need to pass true as param if deep
	func duplicate() -> BondChanges:
		var new := BondChanges.new()
		new.changes = changes.duplicate() as Array[BondChange]
		new.energy_change = energy_change
		new.activation_energy = activation_energy
		new.affected_atoms = affected_atoms.duplicate(true)
		new.depth = depth
		new.operation = operation
		return new
	
	func dupe_and_add(atom1: Atom, atom2: Atom, new_order: int) -> BondChanges:
		return duplicate().add(atom1, atom2, new_order)
	
	func execute():
		Atom.LOCK.lock(self)
		for change in changes:
			change.execute()
		Atom.LOCK.unlock(self)
		for atom: Atom in affected_atoms:
			atom.execute_bond_changed_event_queue(BOTH)
	
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

	func get_bond_form_combos(atom: Atom, min_bonds: int, max_bonds: int, excluded_atom: Atom) -> Array:
		if atom.removing: return []
		var bonds := get_atom_bonds(atom)
		var bonds_array: Array[Atom] = []
		var excluded_id := excluded_atom.id
		max_bonds = mini(max_bonds, get_atom_bonds_left(atom))
		for other: Atom in atom.atoms_in_field:
			if other in bonds: continue
			bonds[other] = 0
		for other: Atom in bonds:
			if other in affected_atoms or other.id == excluded_id or other.removing: continue
			for _i in range(mini(max_bonds, get_max_bond_order(atom, other) - bonds[other])):
				bonds_array.append(other)
		return _get_bond_combos(bonds_array, min_bonds, max_bonds)
	
	func debug():
		print("\tEnergy change: %s" % [roundi(energy_change)])
		for change in changes:
			print("\t\t" + change.to_string())
		
	func _add(bond_change: BondChange, atom1: Atom = bond_change.atom1, atom2: Atom = bond_change.atom2, new_order: int = bond_change.new_order) -> BondChanges:
		changes.append(bond_change)
		energy_change += bond_change.energy_change
		activation_energy = maxf(energy_change, activation_energy)
		_change_atom_bonds(atom1, atom2, new_order)
		_change_atom_bonds(atom2, atom1, new_order)
		return self
	
	func _get_bond_combos(bonds_array: Array[Atom], min_bonds: int, max_bonds: int) -> Array:
		var bond_count := bonds_array.size()
		if bond_count < min_bonds:
			return []
		return Combination.combos_range_counts(bonds_array, min_bonds, max_bonds)
	
	func _change_atom_bonds(atom: Atom, other: Atom, bond_order: int) -> void:
		var bonds := get_atom_bonds(atom)
		bonds[other] = bond_order
		affected_atoms[atom] = bonds

class CascadingBondsModel:
	var combos: Array[BondChanges] = []
	var depth := 0
	
	func _init() -> void:
		_add_combo(BondChanges.EMPTY)
	
	func from_bonding_pair(atom1: Atom, atom2: Atom) -> void:
		if atom1.removing or atom2.removing: return
		for bond_order in range(1, atom1.get_isolated_max_bond_order(atom2) - atom1.get_bond_order(atom2) + 1):
			CascadingBondsModelOperation.new(combos, BondChanges.new(), atom1, atom2, bond_order, true)
		_evaluate()
	
	func from_unbonded_atom(broken: Atom) -> void:
		if broken.removing: return
		CascadingBondsModelOperation.from_broken_atoms(combos, BondChanges.new(), [broken], broken)
		_evaluate()
	
	func debug():
		print("\n%s combos" % [combos.size()])
		for combo in combos:
			combo.debug()
	
	func _evaluate() -> void:
		BondChanges.sort_combos(combos)
		debug()
		combos[0].execute()
	
	func _add_combo(combo: BondChanges, dupe: bool = false) -> void:
		if dupe:
			combos.append(combo.duplicate())
		else:
			combos.append(combo)
	
	class CascadingBondsModelOperation:
		var combo_input: Array[BondChanges]
		var formed_order: int
		var depth: int
		# {BondChanges: [Atom]}
		var break_bonds_results: Array[BreakBondsResult] = []
		
		@warning_ignore("shadowed_variable")
		static func from_broken_atoms(combo_input: Array[BondChanges], base_combo: BondChanges, broken_atoms: Array[Atom], breaker: Atom) -> void:
			for broken in broken_atoms:
				var bond_combos := base_combo.get_bond_form_combos(broken, 0, 3, breaker)
				for bond_combo: Dictionary in bond_combos:
					# TODO: In cases of more than one broken atom, combos only continue on one broken atom each
					var combo := base_combo.duplicate()
					for bonding: Atom in bond_combo:
						if bonding.removing: continue
						CascadingBondsModelOperation.new(combo_input, combo, bonding, broken, bond_combo[bonding])
		
		@warning_ignore("shadowed_variable")
		func _init(combo_input: Array[BondChanges], base_combo: BondChanges, bonder: Atom, bonded: Atom, formed_order: int, 
				bidirectional: bool = false) -> void:
			assert(formed_order >= 1, "Parameter formed_order is less than 1")
			self.combo_input = combo_input
			self.formed_order = formed_order
			base_combo.depth += 1
			depth = base_combo.depth
			if depth > 5: return
			var combos1 := break_bonds(base_combo, bonder, bonded)
			if combos1.is_empty(): return
			var combos: Array[BondChanges]
			if bidirectional:
				var combos2 := break_bonds(base_combo, bonded, bonder)
				if combos2.is_empty(): return
				combos = BondChanges.combine_combos(combos1, combos2)
			else:
				combos = combos1
			for combo in combos:
				#print("%s existing order + %s formed" % [combo.get_bond_order(bonder, bonded), formed_order])
				combo_input.append(combo.add(bonder, bonded, combo.get_bond_order(bonder, bonded) + formed_order))
			for result in break_bonds_results:
				result.execute()
		
		func break_bonds(base_combo: BondChanges, bonder: Atom, bonded: Atom) -> Array[BondChanges]:
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
				return [base_combo]
			for break_combo: Dictionary in base_combo.get_bond_break_combos(bonder, bonds_to_break, bonds_to_break, bonded):
				#print("\tBreak combo:")
				# TODO: In cases of more than one broken atom, combos only continue on one broken atom each
				var combo := base_combo.duplicate()
				var broken_atoms: Array[Atom] = []
				for broken: Atom in break_combo:
					#print("\t\t%s x%s" % [broken.to_string(), break_combo[broken]])
					combo.add(bonder, broken, combo.get_bond_order(bonder, broken) - break_combo[broken])
					broken_atoms.append(broken)
				combos.append(combo)
				break_bonds_results.append(BreakBondsResult.new(combo_input, combo, bonder, broken_atoms))
			return combos
		
		class BreakBondsResult:
			var _combo_input: Array[BondChanges]
			var _combo: BondChanges
			var _breaker: Atom
			var _broken_atoms: Array[Atom] = []
			
			func _init(combo_input: Array[BondChanges], combo: BondChanges, breaker: Atom, broken_atoms: Array[Atom]) -> void:
				_combo_input = combo_input
				_combo = combo
				_breaker = breaker
				_broken_atoms = broken_atoms
			
			func execute() -> void:
				CascadingBondsModelOperation.from_broken_atoms(_combo_input, _combo, _broken_atoms, _breaker)

func evaluate_field() -> void:
	for other in atoms_in_field:
		# TODO: Allow intramolecular bonding (rings)
		if id > other.id: continue
		#if id > other.id or molecule.id == other.molecule.id: continue
		if molecule.id == other.molecule.id:
			if atoms_in_molecule_checked.has(other): continue
			atoms_in_molecule_checked.append(other)
		CascadingBondsModel.new().from_bonding_pair(self, other)

func atom_list_to_ids(_accum, _atom_list: Array[Atom]) -> Array[int]:
	return [1]

func atoms_in_field_changed(new_atoms_in_field: Array[Atom]) -> bool:
	if atoms_in_field.size() != new_atoms_in_field.size():
		return true
	return atoms_in_field.hash() != new_atoms_in_field.hash()

func remove() -> void:
	removing = true
	unbond_all()
	atom_removing.emit(self)
	atom_id_register.erase(id)
	remove_from_group("atoms")
	#await get_tree().create_timer(0.5).timeout
	queue_free()

func _physics_process(_delta: float) -> void:
	var force_list = AdderDict.new()
	var new_atoms_in_field: Array[Atom] = []
	# TODO: Consider using signals
	for other: Atom in $AtomField.get_overlapping_bodies():
		if other == self: continue
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
			prev_atom.atom_removing.disconnect(_on_atom_removing)
			prev_atom.dirty.disconnect(_on_field_dirty)
		for new_atom in new_atoms_in_field:
			if new_atom in atoms_in_field: continue
			new_atom.atom_removing.connect(_on_atom_removing, CONNECT_ONE_SHOT)
			if not new_atom.dirty.is_connected(_on_field_dirty):
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
	evaluate_field()

func _on_atom_removing(atom: Atom) -> void:
	atoms_in_field.erase(atom)

func _on_molecule_dirty() -> void:
	atoms_in_molecule_checked.clear()
