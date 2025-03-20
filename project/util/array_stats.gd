class_name ArrayStats extends RefCounted

var arr: Array[float] = []
var count: int:
	get(): return arr.size()

func _init(array: Array) -> void:
	arr = array

func sum() -> float:
	return arr.reduce(func(acc: float, num: float): return acc + num, 0)

func mean() -> float:
	return sum() / count

func percentile(pcile: float) -> float:
	var sorted := arr.duplicate()
	sorted.sort()
	return sorted[roundi(pcile / 100 * (count - 1))]
