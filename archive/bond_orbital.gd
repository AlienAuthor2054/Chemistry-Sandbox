class_name BondOrbital extends Orbital

func _init(orbital_set: AtomicOrbitalSet, principal: int, azimuthal: int, magnetic: int, electrons: int = 0) -> void:
	parent = orbital_set
	if electrons > 0:
		add_electrons(electrons)
