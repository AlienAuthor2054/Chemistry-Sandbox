class_name RunningList extends RefCounted

var list: Array[float] = []
var max_size := 0
var average := 0.0

func _init(_max_size: int) -> void:
	max_size = _max_size

func insert(number: float) -> void:
	if list.size() == max_size:
		list.resize(max_size - 1)
	list.push_front(number)
	average = _average()
	
func clear() -> void:
	list.clear()
	average = 0

func _average() -> float:
	if list.is_empty(): return 0
	var sum := 0.0
	for number in list:
		sum += number
	return sum / list.size()
