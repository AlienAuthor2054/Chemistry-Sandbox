class_name Lock extends RefCounted

var locked := false
var key

func lock(new_key):
	assert(not locked, "Attempted to lock an already locked Lock")
	locked = true
	key = new_key

func unlock(input_key):
	assert(locked, "Attempted to unlock an already unlocked Lock")
	assert(input_key == key, "Attempted to unlock a Lock with a non-matching key")
	locked = false
	key = null
