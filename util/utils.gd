class_name Util extends RefCounted

static func count_array(array: Array) -> Dictionary:
	var counts := {}
	for value in array:
		counts[value] = counts.get_or_add(value, 0) + 1
	return counts

static func sumi_dict_values(dict: Dictionary) -> int:
	return dict.values().reduce(func(total: int, num: int): return total + num, 0)

static func sumf_dict_values(dict: Dictionary) -> float:
	return dict.values().reduce(func(total: float, num: float): return total + num, 0.0)
	
static func multi_mini(ints: Array[int]) -> int:
	return ints.min()
