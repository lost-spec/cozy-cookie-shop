extends Node3D

var button: Button
var open_doors: Node3D
var shop: Node3D
var _near := false
var _open := false

func _ready() -> void:
	shop = get_node("../CookieShop")
	open_doors = shop.get_node("FreezerDoorsOpen")
	button = get_node("../HUD/InteractButton")
	open_doors.visible = false
	button.visible = false
	button.pressed.connect(toggle)
	$Area.body_entered.connect(_entered)
	$Area.body_exited.connect(_exited)

func _entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		_near = true
		button.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		_near = false
		button.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if _near and event.is_action_pressed("interact"):
		toggle()

func toggle() -> void:
	_open = not _open
	open_doors.visible = _open
	for c in shop.get_children():
		var n: String = c.name
		if n.begins_with("FREEZER_DoorFrame_") or n.begins_with("FREEZER_Glass_") or n.begins_with("FREEZER_Handle"):
			c.visible = not _open
	button.text = "Close Freezer" if _open else "Open Freezer"
