class_name BondOrbitalSet extends OrbitalSet

var orbitals: Array[AtomicOrbital] = []

static func from_atomic_orbital_sets(set1: AtomicOrbitalSet, set2: AtomicOrbitalSet) -> BondOrbitalSet:
	var orbital_set := BondOrbitalSet.new()
	var set1_valence_shell = set1.get_valence_shell()
	var set2_valence_shell = set2.get_valence_shell()
	orbital_set.orbitals.append(set1_valence_shell[0][0])
	return orbital_set

static func archive(set1: AtomicOrbitalSet, set2: AtomicOrbitalSet):
	var principal := 1
	var azimuthal := 0
	while true:
		var combined_count = set1.get_subshell_electron_count(principal, azimuthal) + set2.get_subshell_electron_count(principal, azimuthal)
		if azimuthal + 1 == principal:
			principal += 1
			azimuthal = 0
		else:
			azimuthal += 1
