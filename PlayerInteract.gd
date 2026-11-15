extends Node3D

var cam: Camera3D
var hold: Node3D
var held: Node3D = null
var held_id := ""
var held_baked := false
var held_is_bag := false
var held_is_tray := false
var current: Interactable = null

var base_hold := Vector3(0.28, -0.22, -0.55)
var sway := 0.0
var tray_follow := false
var tray_tween: Tween

func _ready() -> void:
	cam = get_parent().get_node("Camera")
	hold = Node3D.new()
	hold.position = base_hold
	hold.rotation_degrees = Vector3(-8, 24, 5)
	cam.add_child(hold)

func has_item() -> bool:
	return held != null

func clear_hand() -> void:
	if held_is_tray:
		return
	if held != null:
		held.queue_free()
		held = null
	held_id = ""
	held_baked = false
	held_is_bag = false

func hold_cookie(id: String, baked: bool) -> void:
	clear_hand()
	var model := Config.build_cookie(id)
	hold.add_child(model)
	held = model
	held_id = id
	held_baked = baked
	held_is_bag = false
	if not baked:
		Config.set_overlay(model, Config.raw_material())

func hold_bag() -> void:
	clear_hand()
	var src: Node3D
	if ResourceLoader.exists(Config.ASSET_BAG_SEALED):
		src = (load(Config.ASSET_BAG_SEALED) as PackedScene).instantiate()
	else:
		src = MeshInstance3D.new()
	var b := Config.aabb_of(src)
	src.position = Vector3(-(b.position.x + b.size.x * 0.5), -b.position.y, -(b.position.z + b.size.z * 0.5))
	var w := Node3D.new()
	w.add_child(src)
	w.scale = Vector3.ONE * 1.2
	Config.set_gi_dynamic(w)
	hold.add_child(w)
	held = w
	held_is_bag = true
	held_id = "bag"

func tray_target() -> Vector3:
	return cam.global_transform * Vector3(0, -0.3, -0.6)

func grab_tray(t: Node3D, dur := 0.35) -> void:
	clear_hand()
	if tray_tween != null and tray_tween.is_valid():
		tray_tween.kill()
	held = t
	held_is_tray = true
	held_id = "tray"
	held_baked = false
	tray_follow = false
	var start := t.global_position
	var start_rot := t.global_rotation
	tray_tween = create_tween()
	tray_tween.tween_method(func(p: float):
		t.global_position = start.lerp(tray_target(), p)
		t.global_rotation = start_rot.lerp(Vector3.ZERO, p)
	, 0.0, 1.0, dur)
	tray_tween.tween_callback(func(): tray_follow = true)

func release_tray() -> void:
	if tray_tween != null and tray_tween.is_valid():
		tray_tween.kill()
	tray_tween = null
	held = null
	held_is_tray = false
	held_id = ""
	held_baked = false
	tray_follow = false

func _process(delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		current = null
		Game.set_prompt("")
		return
	current = _ray()
	if current != null:
		Game.set_prompt("[E] " + current.prompt)
	else:
		Game.set_prompt("")
	sway += delta
	if held != null:
		var wobble := Vector3(sin(sway * 1.7) * 0.008, cos(sway * 2.1) * 0.008, 0.0)
		hold.position = hold.position.lerp(base_hold + wobble, delta * 8.0)
	if held_is_tray and held != null and tray_follow:
		held.global_position = tray_target()
		held.global_rotation = Vector3.ZERO

func _ray() -> Interactable:
	var from: Vector3 = cam.global_position
	var to: Vector3 = from - cam.global_transform.basis.z * Config.INTERACT_RANGE
	var q := PhysicsRayQueryParameters3D.create(from, to, 2)
	q.exclude = [get_parent().get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return null
	var c = hit.get("collider")
	if c is Interactable and c.enabled:
		return c
	return null

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var use := event.is_action_pressed("interact")
	var drop_it := event.is_action_pressed("drop")
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			use = true
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			drop_it = true
	if use and current != null and current.on_interact.is_valid():
		current.on_interact.call(self)
		get_viewport().set_input_as_handled()
	elif drop_it:
		drop()

func drop() -> void:
	if held == null:
		return
	if held_is_tray:
		get_parent().get_parent().get_node("Stations").put_tray_down()
		return
	if held_is_bag:
		get_parent().get_parent().get_node("Stations").return_bag()
	clear_hand()
