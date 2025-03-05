class_name AtomicOrbital extends Orbital

var n := 1
var l := 0
var m := 0

@warning_ignore("shadowed_variable")
func _init(orbital_set: AtomicOrbitalSet, principal: int, azimuthal: int, magnetic: int, electrons: int = 0) -> void:
	parent = orbital_set
	n = principal
	l = azimuthal
	m = magnetic
	if electrons > 0:
		add_electrons(electrons)
		parent.electronsAdded.emit(electrons, self)
