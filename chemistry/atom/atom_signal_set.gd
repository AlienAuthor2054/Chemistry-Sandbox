class_name AtomSignalSet extends RefCounted

var _set: Dictionary[Atom, Signal]
var _callable: Callable
var _bind_self: bool

func _init(callable: Callable, bind_self: bool = false):
	_callable = callable
	_bind_self = bind_self

func has(atom: Atom) -> bool:
	return _set.has(atom)

func add(sig: Signal) -> void:
	var atom: Atom = sig.get_object()
	if _bind_self:
		sig.connect(_callable.bind(atom))
	else:
		sig.connect(_callable)
	_set[atom] = sig

func erase(atom: Atom) -> void:
	_set[atom].disconnect(_callable)
	_set.erase(atom)

func clear() -> void:
	for atom in _set:
		_set[atom].disconnect(_callable)
	_set.clear()
