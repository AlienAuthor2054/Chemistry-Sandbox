class_name ValenceShell extends RefCounted

var count: int
# No suitable short synonym, closest would be "max_electrons" or "limit"
@warning_ignore("shadowed_global_identifier")
var max: int 
var left: int:
	get(): return max - count

# For now, only considers up to Neon (10 protons)
func _init(protons: int) -> void:
	if protons <= 2:
		count = protons
		max = 2
		return
	count = protons - 2
	max = 8
