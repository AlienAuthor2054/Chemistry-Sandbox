class_name AtomicOrbitalSet extends OrbitalSet

# Energy constant, set to the absolute value of the binding energy in eV of the hydrogen electron
const energy_constant := 13.59844
const aufbau_orbital_series = [
	[[1, 0]],
	[[2, 0]],
	[[2, 1], [3, 0]],
	[[3, 1], [4, 0]],
]
const principal_conversion: Array[float] = [1.0, 2.0, 3.0, 3.7, 4.0, 4.2]
const azimuthal_conversion := {"s" = 0, "p" = 1, "d" = 2}

var parent: Atom
var orbitals = {}
var orbitals_electron_counts := {}
var electrons := 0
var orbitals_array: Array[AtomicOrbital]:
	get():
		var result: Array[AtomicOrbital] = []
		for shell: Dictionary in orbitals.values():
			for subshell: Dictionary in shell.values():
				for orbital: AtomicOrbital in subshell.values():
					result.append(orbital)
		return result
var valence_shell:
	get(): return orbitals.get_or_add(orbitals.keys().max(), {})
var valence_count:
	get(): return orbitals_electron_counts.get(orbitals.keys().max(), {"count": 0}).count
var valence_max:
	get(): return 2 if electrons <= 2 else 8
var valence_left:
	get(): return valence_max - valence_count

func _on_electron_configuration_changed(count: int, orbital: AtomicOrbital, added: bool):
	if not added: count = -count
	electrons += count
	var shell_counts: Dictionary = orbitals_electron_counts.get_or_add(orbital.n, {"count": 0})
	shell_counts.count += count
	var subshell_count = shell_counts.get_or_add(orbital.l, {"count": 0, orbital.l: 0})
	subshell_count[orbital.l] += count

static func from_electron_configuration(config_string: String) -> AtomicOrbitalSet:
	var orbital_set := AtomicOrbitalSet.new()
	var config_array: PackedStringArray = config_string.split(" ")
	for subshell_info: String in config_array:
		var principal: int = subshell_info[0].to_int()
		var azimuthal: int = azimuthal_conversion[subshell_info[1]]
		var remaining_subshell_electrons: int = subshell_info.right(-2).to_int()
		var magnetic: int = -azimuthal
		while remaining_subshell_electrons > 0:
			orbital_set.get_orbital(principal, azimuthal, magnetic).add_electrons(min(2, remaining_subshell_electrons))
			#print("Added orbital (%s, %s, %s) with %s electrons" % [principal, azimuthal, magnetic, min(2, remaining_subshell_electrons)])
			magnetic += 1
			remaining_subshell_electrons -= 2
	return orbital_set

func _init() -> void:
	electronsAdded.connect(_on_electron_configuration_changed.bind(true))
	electronsRemoved.connect(_on_electron_configuration_changed.bind(false))

func get_shell(principal: int) -> Dictionary:
	return orbitals.get_or_add(principal, {})

func get_subshell(principal: int, azimuthal: int) -> Dictionary:
	var shell := get_shell(principal)
	return shell.get_or_add(azimuthal, {})

func get_orbital(principal: int, azimuthal: int, magnetic: int) -> AtomicOrbital:
	var subshell := get_subshell(principal, azimuthal)
	var orbital: AtomicOrbital = subshell.get_or_add(magnetic, AtomicOrbital.new(self, principal, azimuthal, magnetic))
	return orbital

func get_valence_shell() -> Dictionary:
	return valence_shell

func get_shell_electron_count(principal: int) -> int:
	return orbitals_electron_counts.get(principal, {"count": 0}).count

func get_subshell_electron_count(principal: int, azimuthal: int) -> int:
	return orbitals_electron_counts.get(principal, {}).get(azimuthal, {"count": 0}).count

func add_electrons(principal: int, azimuthal: int, magnetic: int, count: int = 1) -> AtomicOrbital:
	var orbital := get_orbital(principal, azimuthal, magnetic)
	orbital.add_electrons(count)
	return orbital

func remove_electrons(principal: int, azimuthal: int, magnetic: int, count: int = 1) -> AtomicOrbital:
	var orbital := get_orbital(principal, azimuthal, magnetic)
	orbital.remove_electrons(count)
	return orbital

func find_lowest_free_orbital() -> AtomicOrbital:
	if orbitals.is_empty():
		return get_orbital(1, 0, 0)
	var lowest_orbital: AtomicOrbital
	var lowest_energy = 0
	@warning_ignore("unused_variable")
	var highest_energy_number = 0
	for orbital: AtomicOrbital in orbitals_array:
		if orbital.is_full: continue
		if orbital.energy < lowest_energy:
			lowest_orbital = orbital
			lowest_energy = orbital.energy
			highest_energy_number = orbital.energy_number
		elif orbital.energy == lowest_energy:
			pass
	return lowest_orbital

func duplicate() -> AtomicOrbitalSet:
	var orbital_set := AtomicOrbitalSet.new()
	for n: int in orbitals:
		var shell = orbitals[n]
		for l: int in shell:
			var subshell = shell[l]
			for m: int in subshell:
				var electron_count: int = subshell[l].electron_count
				var new_orbital := orbital_set.get_orbital(n, l, m)
				if electron_count > 0:
					new_orbital.add_electrons(electron_count)
	return orbital_set

func get_total_energy(protons: int = parent.protons) -> float:
	var total_energy := 0.0
	var orbital_series = {}
	var last_shell_electrons := 0
	var below_last_shell_electrons := 0
	for orbital: AtomicOrbital in orbitals_array:
		var principal_group: Dictionary = orbital_series.get_or_add(orbital.n, {})
		var group_num = maxi(1, orbital.l)
		if not principal_group.has(group_num): principal_group[group_num] = 0
		principal_group[group_num] += orbital.electron_count
	for principal: int in orbital_series:
		var principal_group: Dictionary = orbital_series[principal]
		var shell_electrons := 0
		for group_num: int in principal_group:
			var group_electrons: int = principal_group[group_num]
			var effective_nuclear_charge := protons \
				# Effective nuclear charge reduced based on other electrons in...
				# ...same group
				- (maxi(0, group_electrons - 1) * (0.30 if principal == 1 else 0.35)) \
				# ...same shell, lower groups (d and above orbitals)
				- (maxi(0, shell_electrons) * 1.00) \
				# ...groups in shell n-1
				- (maxi(0, last_shell_electrons) * (0.85 if group_num == 1 else 1.00)) \
				# ...groups in shells lower than n-1
				- (maxi(0, below_last_shell_electrons) * 1.00)
			var group_energy = -group_electrons * energy_constant * (effective_nuclear_charge / principal_conversion[principal - 1]) ** 2
			#print("Group %s.%s: %s * %s * (%s / %s) ^ 2 = %s" % [principal, group_num, group_electrons, energy_constant, effective_nuclear_charge, principal_conversion[principal - 1], group_energy])
			total_energy -= group_energy
			shell_electrons += group_electrons
		below_last_shell_electrons += last_shell_electrons
		last_shell_electrons = shell_electrons
	return total_energy
