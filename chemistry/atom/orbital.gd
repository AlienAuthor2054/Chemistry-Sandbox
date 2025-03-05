class_name Orbital extends RefCounted

var parent: OrbitalSet
var electrons: Array[Electron] = []
var electron_count:
	get(): return electrons.size()
var is_free:
	get(): return electrons.size() < 2
var is_full:
	get(): return electrons.size() == 2

static func get_energy_group(principal: int, azimuthal: int) -> int:
	var result := 1
	match principal:
		1: result = 1
		2: result = 2
		3: result = 3
		4: result = 5
	if azimuthal > 1: result += azimuthal - 1
	return result

func add_electrons(count: int = 1, slient: bool = false) -> Array[Electron]:
	assert(electron_count + count <= 2, "Attempted to overfill an orbital")
	var new_electrons: Array[Electron] = []
	for _i in range(count):
		var electron := Electron.new()
		electrons.append(electron)
	if parent != null and not slient:
		parent.electronsAdded.emit(count, self)
	return new_electrons

func remove_electrons(count: int = 1, slient: bool = false) -> Array[Electron]:
	assert(electron_count - count >= 0, "Attempted to remove %s electron(s) from an orbital with %s electron(s)" % [count, electron_count])
	var new_electrons: Array[Electron] = []
	for _i in range(count):
		electrons.pop_back()
	if parent != null and not slient:
		parent.electronsRemoved.emit(count, self)
	return new_electrons
