class_name Computed extends RefCounted

signal valueChanged
var value = null
var _calc_func: Callable
var dependents = []

func calculate():
	@warning_ignore("shadowed_variable")
	value = _calc_func.call(func(value: Value): return value.value)
	valueChanged.emit()

@warning_ignore("shadowed_variable")
func use(value: Value):
	if not dependents.has(value):
		dependents.append(value)
		value.valueChanged.connect(calculate)
	return value.value

func _init(calc_func: Callable) -> void:
	_calc_func = calc_func
	_calc_func.call(use)
	calculate()
