class_name Value extends RefCounted

signal valueChanged
var _value = null
var value:
	set(new_value): set_val(new_value, false)
	get(): return _value
var dependents = []

func _init(new_value) -> void:
	if new_value != null:
		_value = new_value

func set_val(new_value, force: bool = false):
	var is_equal: bool = value == new_value
	print("%s -> %s" % [value, new_value])
	_value = new_value
	if (not is_equal) or force:
		valueChanged.emit()
	return new_value

func add(addend, force: bool = false):
	return set_val(value + addend, force)

func sub(subtrahend, force: bool = false):
	return set_val(value - subtrahend, force)

func mul(factor, force: bool = false):
	return set_val(value * factor, force)

func div(divisor, force: bool = false):
	return set_val(value / divisor, force)

func power(exponent, force: bool = false):
	return set_val(pow(value, exponent), force)

func get_val():
	return _value
