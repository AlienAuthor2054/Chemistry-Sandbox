extends Node

signal running_changed(new: bool)

const world_size = Vector2(2000, 2000)

var running: bool:
	set(new):
		running = new
		running_changed.emit(new)

func _init() -> void:
	running = false

func on_unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_simulation_running"):
		running = not running
	elif event.is_action_pressed("benchmark"):
		clear()
		SimulationBenchmark.new($"/root/Main")

func clear() -> void:
	get_tree().call_group("atoms", "remove")
