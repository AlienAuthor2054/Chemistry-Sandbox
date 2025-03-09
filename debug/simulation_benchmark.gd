class_name SimulationBenchmark extends Node

const SIMULATION_RECT := Rect2(200, 200, 1600, 1600)
const PROFILE_TIME := 10
const ATOMS: Dictionary[int, int] = { # 50 atoms
	1: 15,
	6: 20,
	7: 5,
	8: 10,
}

static var ATOMS_TO_SPAWN := Util.count_dict_to_array(ATOMS)

var end_node: Node
var end_time: int
var frame := 0
var frame_start_time: int
var frames: Array[float] = []
var frames_stats := ArrayStats.new(frames)

func _init(parent: Node) -> void:
	var RNG := RandomNumberGenerator.new()
	var RNG_util := RNGUtil.new(RNG)
	RNG.seed = 0
	for protons in ATOMS_TO_SPAWN:
		var position := RNG_util.in_rect2(SIMULATION_RECT)
		Atom.create(parent, protons, position, RNG_util.unit_vec() * 400)
	process_physics_priority = -999
	end_node = LastPhysicsProcessNode.new(parent)
	end_node.physics_process.connect(_on_frame_end)
	end_time = Time.get_ticks_usec() + (PROFILE_TIME * 1000000)
	parent.add_child(self)

func _physics_process(_delta: float) -> void:
	frame += 1
	frame_start_time = Time.get_ticks_usec()

func _on_frame_end() -> void:
	var frame_end_time := Time.get_ticks_usec()
	frames.append(float(frame_end_time - frame_start_time) / 1000)
	if frame_end_time >= end_time:
		end()
		end_node.queue_free()
		queue_free()
	
func end():
	print("Simulation benchmark finished; physics process timings: (%s frames profiled in %s seconds)" % [frames.size(), PROFILE_TIME])
	print("\tAvg: ", frames_stats.mean())
	print("\tMed: ", frames_stats.percentile(50))
	print("\t95%ile: ", frames_stats.percentile(95))
	print("\t99%ile: ", frames_stats.percentile(99))
	print("\tMax: ", frames_stats.percentile(100))
	print("\tMax static memory: ", ceili(Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1000000), " MiB")
