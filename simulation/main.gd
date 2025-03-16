extends Node2D

@warning_ignore("unused_signal")
signal external_change_applied

var clicked_point := Vector2.ZERO
var atoms_possible := Atom.atom_db.keys()
var atoms_possible_count := atoms_possible.size()
var atom_selection_index := 0

func _ready():
	Atom.create_textures()

@onready var db := $UI/SelectedAtomLabel/Timer
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			clicked_point = get_global_mouse_position()
		else:
			Atom.create(self, atoms_possible[atom_selection_index], clicked_point, (get_global_mouse_position() - clicked_point) * 1.5)
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
	elif event.is_action_pressed("benchmark"):
		clear_simulation()
		SimulationBenchmark.new($".")

func clear_simulation() -> void:
	get_tree().call_group("atoms", "remove")
