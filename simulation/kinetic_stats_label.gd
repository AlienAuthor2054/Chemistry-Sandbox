extends Label

var kinetic_energy_list = RunningList.new(1)
var potential_energy_list = RunningList.new(1)
var previous_atom_count = 0

func clear_running_lists():
	kinetic_energy_list.clear()
	potential_energy_list.clear()

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	var atom_count = 0
	var kinetic_energy = 0
	var potential_energy = 0
	for atom: Atom in get_tree().get_nodes_in_group("atoms"):
		atom_count += 1
		kinetic_energy += atom.get_kinetic_energy()
		potential_energy += atom.get_potential_energy()
	kinetic_energy_list.insert(kinetic_energy)
	potential_energy_list.insert(potential_energy)
	if atom_count != previous_atom_count: clear_running_lists()
	var mechanical_energy = kinetic_energy_list.average + potential_energy_list.average
	var temperature = kinetic_energy / atom_count if atom_count > 0 else 0
	text = (
		str(roundi(temperature)) + " K\n"
		+ str(roundi(mechanical_energy)) + " J_m\n"
		 + str(roundi(kinetic_energy_list.average)) + " J_k\n"
		 + str(roundi(potential_energy_list.average)) + " J_u"
	)
	previous_atom_count = atom_count

func _on_main_external_change_applied() -> void:
	clear_running_lists()
