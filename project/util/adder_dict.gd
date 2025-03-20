class_name AdderDict extends RefCounted

var dict = {}

func add(key, value):
	if not dict.has(key):
		dict[key] = value
	else:
		dict[key] += value
