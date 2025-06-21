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
var selected: Dictionary[Atom, bool] = {}
var saved_copy: SavedAtomSet

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
	if Input.is_action_just_pressed("cut"):
		cut()
	if Input.is_action_just_pressed("copy"):
		copy()
	elif Input.is_action_just_pressed("paste"):
		paste()

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("remove_atom", true):
		remove_selected()
	if not box_active: return
	$CollisionShape.position = (box_start + box_end) / 2
	($CollisionShape.shape as RectangleShape2D).size = box_rect.size

func _on_body_entered(atom: Atom) -> void:
	if not box_active: return
	add(atom) if box_selecting else remove(atom)

func _draw() -> void:
	if not box_active: return
	draw_rect(box_rect, box_color)

func update(force: bool = false) -> void:
	var mouse_pos := get_global_mouse_position()
	if mouse_pos == box_end and not force: return
	box_end = mouse_pos
	box_rect = Rect2(box_start, box_end - box_start).abs()
	queue_redraw()

func add(atom: Atom) -> void:
	if selected.has(atom): return
	atom.tree_exiting.connect(remove.bind(atom))
	selected[atom] = true
	atom.select()

func remove(atom: Atom, remove_from_selected: bool = true) -> void:
	if not selected.has(atom): return
	atom.tree_exiting.disconnect(remove)
	if remove_from_selected:
		selected.erase(atom)
	atom.deselect()
	
func clear() -> void:
	for atom in selected:
		remove(atom, false)
	selected.clear()

func remove_selected() -> void:
	for atom in selected:
		atom.queue_free()
	selected.clear()

func cut() -> void:
	if selected.is_empty(): return
	copy()
	remove_selected()

func copy() -> void:
	if selected.is_empty(): return
	saved_copy = SavedAtomSet.new(selected.keys())

func paste() -> void:
	if saved_copy == null: return
	clear()
	for atom in saved_copy.spawn($"/root/Main", get_global_mouse_position()):
		add(atom)
