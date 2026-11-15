class_name Interactable
extends StaticBody3D

var kind := ""
var prompt := ""
var enabled := true
var on_interact: Callable

func _init() -> void:
	collision_layer = 2
	collision_mask = 0

func set_active(on: bool) -> void:
	enabled = on
	collision_layer = 2 if on else 0

static func make(size: Vector3, pos: Vector3, kind_: String, prompt_: String, cb: Callable, parent: Node) -> Interactable:
	var b := Interactable.new()
	b.kind = kind_
	b.prompt = prompt_
	b.on_interact = cb
	b.position = pos
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	parent.add_child(b)
	return b
