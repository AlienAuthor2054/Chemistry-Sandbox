extends Node2D

@export var atom_scene: PackedScene
var clicked_point := Vector2.ZERO
var atoms_possible := Atom.atom_db.keys()
var atoms_possible_count := atoms_possible.size()
var atom_selection_index := 0

signal external_change_applied

func change(new: Computed):
	print("changed to %s" % [new.value])

func iron_test():
	var orbital_set = AtomicOrbitalSet.from_electron_configuration("1s2 2s2 2p6 3s2 3p6 3d6 4s2")
	print("%s: %s" % [26, orbital_set.get_total_energy(26)])
	orbital_set.get_orbital(1, 0, 0).remove_electrons()
	print("%s (less a 1s electron): %s" % [26, orbital_set.get_total_energy(26)])

func _ready():
	Atom.create_textures()
	spawn_atoms(30)

func spawn_atoms(count: int):
	for _index in count:
		pass

@onready var db := $UI/SelectedAtomLabel/Timer
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			clicked_point = get_global_mouse_position()
		else:
			var atom: Atom = atom_scene.instantiate()
			atom.initialize(atoms_possible[atom_selection_index], clicked_point, (get_global_mouse_position() - clicked_point) * 1.5)
			$/root/Main.add_child(atom)
	elif event is InputEventMouseButton:
		if not db.is_stopped(): return
		db.start()
		match event.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				atom_selection_index += 1
			MOUSE_BUTTON_WHEEL_UP:
				atom_selection_index -= 1
		if atom_selection_index >= atoms_possible_count: atom_selection_index = 0
		if atom_selection_index < 0: atom_selection_index = atoms_possible_count - 1
		$UI/SelectedAtomLabel.text = Atom.atom_db[atoms_possible[atom_selection_index]].symbol
