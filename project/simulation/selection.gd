extends Area2D

const SELECTION_COLOR = Color("#4dabfa", 0.35)
const DESELECTION_COLOR = Color("#fa9c4d", 0.35)

var box_active := false:
	set(new):
		box_active = new
		monitoring = new
var box_selecting := true
var box_color: Color
var box_start := Vector2.ZERO
var box_end := Vector2.ZERO
var box_rect := Rect2(0, 0, 0, 0)
var selected: Dictionary[Node2D, bool] = {}

func _process(_delta: float) -> void:
	if Input.is_action_pressed("select_atoms") and not Input.is_action_pressed("control"):
		if not box_active:
			box_selecting = not Input.is_action_pressed("shift")
			box_color = SELECTION_COLOR if box_selecting else DESELECTION_COLOR
			box_start = get_global_mouse_position()
			box_end = get_global_mouse_position()
			update(true)
			visible = true
			box_active = true
		else:
			update()
	else:
		if box_active:
			visible = false
		box_active = false

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("remove_atom"):
		for node in selected.duplicate():
			if node is not Atom: continue
			remove(node)
			(node as Atom).remove()
	if not box_active: return
	$CollisionShape.position = (box_start + box_end) / 2
	($CollisionShape.shape as RectangleShape2D).size = box_rect.size

func _on_body_entered(body: Node2D) -> void:
	if not box_active: return
	add(body) if box_selecting else remove(body)

func _draw() -> void:
	if not box_active: return
	draw_rect(box_rect, box_color)

func update(force: bool = false) -> void:
	var mouse_pos := get_global_mouse_position()
	if mouse_pos == box_end and not force: return
	box_end = mouse_pos
	box_rect = Rect2(box_start, box_end - box_start).abs()
	queue_redraw()

func add(node: Node2D) -> void:
	if selected.has(node): return
	node.tree_exiting.connect(remove.bind(node))
	selected[node] = true
	node.select()

func remove(node: Node2D) -> void:
	if not selected.has(node): return
	node.tree_exiting.disconnect(remove)
	selected.erase(node)
	node.deselect()
	
func clear() -> void:
	for node in selected:
		remove(node)
