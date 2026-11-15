extends Node3D

signal order_started
signal finished(success: bool)
signal gone

var body: Node3D
var player: Node3D
var inter: Interactable
var spots: Array = []
var state := "hidden"
var target := Vector3.ZERO
var speed := 0.7
var bob_t := 0.0
var head_y := 1.9
var greeted := false
var result_sent := false
var cust_id := ""
var cust_name := ""

func _ready() -> void:
	player = get_parent().get_node("Player")
	var m := get_parent().get_node_or_null("Markers")
	if m != null:
		_place_markers(m)
	else:
		spots = [Vector3(-3.75, 0.03, 4.05), Vector3(2.25, 0.03, 4.05), Vector3(-3.75, 0.03, 4.05)]
	inter = Interactable.make(Vector3(0.9, 2.0, 0.9), Vector3(0, 1.0, 0), "customer", "Talk", interact_with, self)
	inter.set_active(false)
	visible = false
	set_process(false)

func _place_markers(m: Node) -> void:
	# Use the authored markers. They sit on the sidewalk outside the
	# shop front, so customers never walk through the shop walls.
	var ms: Node3D = m.get_node("CustomerSpawn")
	var mt: Node3D = m.get_node("CustomerSpot")
	var me: Node3D = m.get_node("CustomerExit")
	spots = [ms.global_position, mt.global_position, me.global_position]

func begin(id: String) -> void:
	cust_id = id
	var data: Dictionary = Config.CUSTOMERS[id]
	cust_name = str(data["name"])
	speed = float(data["speed"])
	_load_body(str(data["asset"]))
	greeted = false
	result_sent = false
	global_position = spots[0]
	visible = true
	state = "entering"
	target = spots[1]
	inter.prompt = "Talk to " + cust_name
	inter.set_active(false)
	Game.set_hint(cust_name + " is on the way")
	set_process(true)

func _load_body(path: String) -> void:
	if body != null:
		body.queue_free()
		body = null
	var src: Node3D
	if ResourceLoader.exists(path):
		src = (load(path) as PackedScene).instantiate()
	else:
		src = MeshInstance3D.new()
	body = Node3D.new()
	body.add_child(src)
	add_child(body)
	body.position = Vector3.ZERO
	var b := Config.aabb_of(body)
	# Recenter the model so it stands on the customer origin. Without this
	# the model's offset swings into the shop wall as the customer turns.
	src.position = Vector3(
		-(b.position.x + b.size.x * 0.5),
		-b.position.y,
		-(b.position.z + b.size.z * 0.5)
	)
	Config.set_gi_dynamic(body)
	b = Config.aabb_of(body)
	head_y = b.end.y + 0.25

func _process(delta: float) -> void:
	if state == "entering":
		_walk(delta, "ordering")
	elif state == "leaving":
		_walk(delta, "gone")

func _walk(delta: float, next_state: String) -> void:
	var to: Vector3 = target - global_position
	to.y = 0.0
	if to.length() < 0.06:
		state = next_state
		if body != null:
			body.position.y = 0.0
			body.rotation.z = 0.0
		_arrive(next_state)
		return
	var dir := to.normalized()
	global_position += dir * speed * delta
	rotation.y = atan2(dir.x, dir.z)
	bob_t += delta
	if body != null:
		body.position.y = absf(sin(bob_t * 9.0)) * 0.035
		body.rotation.z = sin(bob_t * 9.0) * 0.03

func _arrive(next_state: String) -> void:
	if next_state == "ordering":
		state = "ordering"
		_face_player()
		inter.set_active(true)
		Game.set_hint("Talk to " + cust_name)
	elif next_state == "gone":
		visible = false
		state = "hidden"
		inter.set_active(false)
		set_process(false)
		gone.emit()

func head_global() -> Vector3:
	return global_transform * Vector3(0, head_y, 0)

func _face_player() -> void:
	var d: Vector3 = player.global_position - global_position
	d.y = 0.0
	if d.length() > 0.01:
		rotation.y = atan2(d.x, d.z)

func interact_with(pi) -> void:
	if state != "ordering":
		return
	if not greeted:
		greeted = true
		var lines: Dictionary = Config.CUSTOMERS[cust_id]["lines"]
		var items: Dictionary = Config.CUSTOMERS[cust_id]["order"]
		Game.set_order(items)
		Game.set_phase("gathering")
		Game.say_as(cust_name, str(lines["order"]))
		Game.set_hint("Bake and bag the order")
		order_started.emit()
		return
	if pi.held_is_bag:
		_hand_over(pi)
		return
	var lines2: Dictionary = Config.CUSTOMERS[cust_id]["lines"]
	Game.say_as(cust_name, str(lines2["repeat"]))

func wants_icon() -> bool:
	return visible and state == "ordering" and not greeted

func timeout() -> void:
	if state != "ordering":
		return
	var lines: Dictionary = Config.CUSTOMERS[cust_id]["lines"]
	Game.say_as(cust_name, str(lines["timeout"]))
	_leave(false)

func _hand_over(pi) -> void:
	pi.clear_hand()
	var st := get_parent().get_node("Stations")
	var lines: Dictionary = Config.CUSTOMERS[cust_id]["lines"]
	var items: Dictionary = Config.CUSTOMERS[cust_id]["order"]
	var fail := ""
	if st.bag_has_raw():
		fail = "raw"
	elif st.bag_count() != Config.order_count(items):
		fail = "count"
	elif not st.bag_matches(items):
		fail = "type"
	if fail != "":
		Game.say_as(cust_name, str(lines[fail]))
		st.reset_after_fail()
		Game.set_phase("gathering")
		Game.set_hint(cust_name + " is waiting")
		return
	var pay := Config.order_total(items)
	Game.say_as(cust_name, str(lines["success"]))
	Game.set_phase("paying")
	Game.add_money(pay)
	Game.float_text.emit("+$%d" % pay, global_position + Vector3(0, 2.0, 0))
	Game.toast.emit("Order complete!")
	Game.set_hint("")
	st.complete_order()
	_leave(true)

func _leave(success: bool) -> void:
	state = "leaving"
	inter.set_active(false)
	target = spots[2]
	set_process(true)
	if not result_sent:
		result_sent = true
		finished.emit(success)
