extends Node3D

const TRAY_HOME := Vector3(1.28, 1.0, 2.55)
const TRAY_OVEN := Vector3(2.5, 1.15, -5.55)
const BAG_POS := Vector3(1.82, 1.0, 2.28)
const OVEN_FRONT := Vector3(2.5, 1.0, -5.0)

var player: Node
var tray: Node3D
var slots: Array = []
var tray_inter: Interactable
var tray_held := false
var oven_open: Node3D
var oven_closed: Array = []
var glow: OmniLight3D
var oven_state := "idle"
var oven_inter: Interactable
var bake_left := 0.0
var bag: Node3D
var bag_slots: Node3D
var bag_state := "open"
var bag_items: Array = []
var bag_inter: Interactable
var freezer_open := false
var freezer_inter: Interactable
var freezer_close: Interactable
var freezer_hinges: Array = []
var freezer_sections: Array = []
var sticker_pics: Array = []
var _sticker_tex: ImageTexture

func _ready() -> void:
	player = get_parent().get_node("Player/Interact")
	_build_freezer()
	_build_tray()
	_build_oven()
	_build_bag()
	set_process(false)

# ---------------- freezer ----------------

func _build_freezer() -> void:
	var shop := get_parent().get_node("CookieShop")
	var fr: Node3D = shop.get_node_or_null("Freezer")
	if fr == null:
		push_warning("Freezer missing from shop")
		return
	for c in fr.get_children():
		if str(c.name).begins_with("FREEZER_") or str(c.name) == "FreezerDoorsOpen":
			Config.set_gi_dynamic(c)
	var doors_open := fr.get_node_or_null("FreezerDoorsOpen")
	if doors_open != null:
		Config.set_gi_dynamic(doors_open)
	var keys: Array = Config.COOKIES.keys()
	_sticker_tex = _make_sticker_texture()
	var front: Vector3 = fr.global_transform * Vector3(0, 0.85, 0.45)
	freezer_inter = Interactable.make(Vector3(0.55, 1.5, 1.45), front, "freezer", "Open freezer", _toggle_freezer, self)
	freezer_close = Interactable.make(Vector3(0.55, 0.5, 1.45), front + Vector3(0, 0.85, 0), "freezer", "Close freezer", _toggle_freezer, self)
	freezer_close.set_active(false)
	for s in range(1, 7):
		var hinge: Node3D = fr.get_node_or_null("Hinge_%d" % s)
		if hinge != null:
			freezer_hinges.append(hinge)
	for i in keys.size():
		var id: String = keys[i]
		var section := i + 1
		for k in range(1, 7):
			var slot: Node3D = fr.get_node_or_null("Slot_%d_%d" % [section, k])
			if slot != null:
				slot.add_child(Config.build_cookie(id))
		var sec: Node3D = fr.get_node_or_null("Section_%d" % section)
		if sec == null:
			continue
		var it := Interactable.make(Vector3(0.5, 0.45, 0.36), sec.global_position, "cookie", "Take " + Config.display_name(id), _take_cookie.bind(id), self)
		it.set_active(false)
		freezer_sections.append({"inter": it, "id": id})
		var mount: Node3D = fr.get_node_or_null("StickerMount_%d" % section)
		if mount != null:
			_build_sticker(id, mount)
	_render_stickers()

func _build_sticker(id: String, mount: Node3D) -> void:
	var root := Node3D.new()
	root.rotation = Vector3(0, PI, 0)
	mount.add_child(root)
	var back := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.13, 0.15)
	back.mesh = qm
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.albedo_texture = _sticker_tex
	back.material_override = bm
	root.add_child(back)
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.034
	cm.bottom_radius = 0.034
	cm.height = 0.002
	disc.mesh = cm
	disc.rotation_degrees = Vector3(90, 0, 0)
	disc.position = Vector3(0, 0.022, 0.003)
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Config.COOKIE_COLORS.get(id, Config.MAUVE)
	dm.roughness = 0.6
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material_override = dm
	root.add_child(disc)
	var pic := MeshInstance3D.new()
	var pq := QuadMesh.new()
	pq.size = Vector2(0.075, 0.075)
	pic.mesh = pq
	pic.position = Vector3(0, 0.022, 0.0035)
	pic.visible = false
	root.add_child(pic)
	var lbl := Label3D.new()
	lbl.text = Config.display_name(id)
	lbl.font_size = 18
	lbl.pixel_size = 0.001
	lbl.modulate = Config.CHARCOAL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector3(0, -0.05, 0.004)
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	root.add_child(lbl)
	sticker_pics.append({"id": id, "disc": disc, "pic": pic})

func _make_sticker_texture() -> ImageTexture:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var half := 61.0
	var r := 22.0
	for y in s:
		for x in s:
			var px := float(x) - 63.5
			var py := float(y) - 63.5
			var qx: float = absf(px) - (half - r)
			var qy: float = absf(py) - (half - r)
			var d: float = Vector2(maxf(qx, 0.0), maxf(qy, 0.0)).length() + minf(maxf(qx, qy), 0.0) - r
			if d < -6.0:
				img.set_pixel(x, y, Config.CREAM)
			elif d < 0.0:
				img.set_pixel(x, y, Config.MAUVE)
	return ImageTexture.create_from_image(img)

func _render_stickers() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(128, 128)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.own_world_3d = true
	add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 0.18
	cam.position = Vector3(0, 0.5, 0)
	cam.rotation_degrees = Vector3(-90, 0, 0)
	cam.near = 0.01
	cam.far = 2.0
	vp.add_child(cam)
	var dl := DirectionalLight3D.new()
	dl.rotation_degrees = Vector3(-90, 0, 0)
	dl.light_color = Color(1, 0.94, 0.86)
	dl.light_energy = 1.3
	vp.add_child(dl)
	var dl2 := DirectionalLight3D.new()
	dl2.rotation_degrees = Vector3(-45, 45, 0)
	dl2.light_color = Color(0.85, 0.9, 1)
	dl2.light_energy = 0.6
	vp.add_child(dl2)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 0.92, 0.84)
	e.ambient_light_energy = 0.7
	we.environment = e
	vp.add_child(we)
	for item in sticker_pics:
		var c := Config.build_cookie(str(item["id"]))
		vp.add_child(c)
		await get_tree().process_frame
		await get_tree().process_frame
		var tex: Texture2D = null
		var vt := vp.get_texture()
		if vt != null:
			var img := vt.get_image()
			if img != null and not img.is_empty() and img.get_pixel(64, 64).a > 0.05:
				tex = ImageTexture.create_from_image(img)
		if tex != null:
			var pm := StandardMaterial3D.new()
			pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			pm.albedo_texture = tex
			(item["pic"] as MeshInstance3D).material_override = pm
			(item["pic"] as MeshInstance3D).visible = true
			(item["disc"] as MeshInstance3D).visible = false
		c.queue_free()
		await get_tree().process_frame
	vp.queue_free()

func _toggle_freezer(_pi) -> void:
	freezer_open = not freezer_open
	for h in freezer_hinges:
		var tw := create_tween()
		tw.tween_property(h, "rotation:y", -1.75 if freezer_open else 0.0, 0.35)
	for s in freezer_sections:
		s["inter"].set_active(freezer_open)
	freezer_inter.set_active(not freezer_open)
	freezer_close.set_active(freezer_open)
	if freezer_open:
		Game.set_hint("Take a cookie")
	else:
		Game.set_hint("Open the freezer")

func _take_cookie(pi, id: String) -> void:
	if pi.has_item():
		return
	pi.hold_cookie(id, false)
	Game.set_hint("Put the cookie on the tray by the window")

# ---------------- tray ----------------

func _build_tray() -> void:
	tray = Node3D.new()
	tray.position = TRAY_HOME
	add_child(tray)
	var model: Node3D
	if ResourceLoader.exists(Config.ASSET_TRAY):
		model = (load(Config.ASSET_TRAY) as PackedScene).instantiate()
	else:
		model = _fallback_tray()
	var b := Config.aabb_of(model)
	model.position = Vector3(-(b.position.x + b.size.x * 0.5), -b.position.y, -(b.position.z + b.size.z * 0.5))
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color("b6b0ac")
	tm.metallic = 0.15
	tm.roughness = 0.6
	for mn in model.find_children("*", "MeshInstance3D", true, false):
		(mn as MeshInstance3D).material_override = tm
	tray.add_child(model)
	for i in 4:
		var x := 0.15 if i % 2 == 1 else -0.15
		var z := 0.07 if i > 1 else -0.07
		var mark := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.07
		cm.bottom_radius = 0.07
		cm.height = 0.004
		mark.mesh = cm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("7d7773")
		m.roughness = 0.6
		mark.material_override = m
		mark.position = Vector3(x, 0.024, z)
		tray.add_child(mark)
		var it := Interactable.make(Vector3(0.19, 0.18, 0.19), TRAY_HOME + Vector3(x, 0.07, z), "slot", "Put cookie on tray", _slot_interact.bind(i), self)
		slots.append({"inter": it, "node": null, "id": "", "baked": false, "off": Vector3(x, 0.03, z)})
	tray_inter = Interactable.make(Vector3(0.72, 0.06, 0.34), TRAY_HOME + Vector3(0, 0.03, 0), "tray", "Pick up tray", _tray_interact, self)
	tray_inter.set_active(false)
	Config.set_gi_dynamic(tray)

func _fallback_tray() -> Node3D:
	var root := Node3D.new()
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 0.02, 0.35)
	base.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("9a9490")
	m.metallic = 0.4
	m.roughness = 0.5
	base.material_override = m
	root.add_child(base)
	return root

func _slot_interact(pi, i: int) -> void:
	if tray_held or oven_state == "baking" or oven_state == "ready":
		return
	var s: Dictionary = slots[i]
	if s["node"] == null:
		if pi.has_item() and not pi.held_is_bag and not pi.held_is_tray:
			_place_on_slot(i, pi.held_id, pi.held_baked)
			pi.clear_hand()
			if _raw_count() >= Config.order_count(Game.order):
				Game.set_hint("Pick up the tray")
			else:
				Game.set_hint("Put 2 cookies on the tray by the window")
			_refresh_tray_inter()
		return
	if pi.has_item():
		return
	var id: String = s["id"]
	var baked: bool = s["baked"]
	s["node"].queue_free()
	s["node"] = null
	s["id"] = ""
	s["baked"] = false
	if baked:
		pi.hold_cookie(id, true)
		Game.set_hint("Put the cookies in the bag")
	_refresh_tray_inter()

func _place_on_slot(i: int, id: String, baked: bool) -> void:
	var s: Dictionary = slots[i]
	var c := Config.build_cookie(id)
	c.position = Vector3(s["off"].x, 0.16, s["off"].z)
	tray.add_child(c)
	var tw := create_tween()
	tw.tween_property(c, "position:y", 0.03, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	s["node"] = c
	s["id"] = id
	s["baked"] = baked
	if not baked:
		Config.set_overlay(c, Config.raw_material())
	Game.set_baked(_baked_count())

func _baked_count() -> int:
	var n := 0
	for s in slots:
		if s["node"] != null and s["baked"]:
			n += 1
	return n

func _raw_count() -> int:
	var n := 0
	for s in slots:
		if s["node"] != null and not s["baked"]:
			n += 1
	return n

func _tray_count() -> int:
	var n := 0
	for s in slots:
		if s["node"] != null:
			n += 1
	return n

func _refresh_tray_inter() -> void:
	if tray_inter == null:
		return
	if tray_held:
		tray_inter.prompt = "Put tray down"
		tray_inter.set_active(true)
		return
	if oven_state == "idle" and _tray_count() > 0:
		tray_inter.prompt = "Pick up tray"
		tray_inter.set_active(true)
	else:
		tray_inter.set_active(false)

func _tray_interact(pi) -> void:
	if tray_held:
		put_tray_down()
		return
	if oven_state != "idle":
		return
	if pi.has_item():
		return
	if _tray_count() == 0:
		return
	tray_held = true
	_set_slots_enabled(false)
	tray_inter.set_active(false)
	pi.grab_tray(tray, 0.35)
	Game.set_hint("Put the tray in the oven")

func put_tray_down() -> void:
	if not tray_held:
		return
	tray_held = false
	player.release_tray()
	var tw := create_tween()
	tw.tween_property(tray, "global_transform", Transform3D(Basis(), TRAY_HOME), 0.3).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_set_slots_enabled(true)
	_refresh_tray_inter()
	if _baked_count() > 0:
		Game.set_hint("Put the cookies in the bag")
	else:
		Game.set_hint("Put 2 cookies on the tray by the window")

func _set_slots_enabled(on: bool) -> void:
	for s in slots:
		s["inter"].set_active(on)

# ---------------- oven ----------------

func _build_oven() -> void:
	oven_inter = Interactable.make(Vector3(1.6, 1.7, 0.35), OVEN_FRONT, "oven", "Put the tray in the oven", _oven_interact, self)
	glow = get_parent().get_node_or_null("CookieShop/OVEN_Body/OvenGlow") as OmniLight3D
	if glow == null:
		glow = OmniLight3D.new()
		glow.light_color = Color("ff9a3c")
		glow.light_energy = 0.0
		glow.omni_range = 3.2
		glow.position = Vector3(2.5, 1.0, -4.85)
		add_child(glow)
	if ResourceLoader.exists(Config.ASSET_OVEN_OPEN):
		oven_open = (load(Config.ASSET_OVEN_OPEN) as PackedScene).instantiate()
		oven_open.position = Vector3(2.5, 0, -5.55)
		oven_open.visible = false
		Config.set_gi_dynamic(oven_open)
		add_child(oven_open)
	for c in get_parent().get_node("CookieShop").get_children():
		if c.name.begins_with("OVEN_"):
			oven_closed.append(c)

func _show_oven(open: bool) -> void:
	for c in oven_closed:
		c.visible = not open
	if oven_open != null:
		oven_open.visible = open

func _oven_interact(pi) -> void:
	if oven_state == "baking":
		return
	if oven_state == "ready":
		_take_tray_out(pi)
		return
	if oven_state != "idle":
		return
	if not pi.held_is_tray:
		return
	if _raw_count() == 0:
		return
	_start_bake(pi)

func _start_bake(pi) -> void:
	oven_state = "baking"
	oven_inter.prompt = "Baking..."
	_set_slots_enabled(false)
	tray_inter.set_active(false)
	_show_oven(true)
	tray_held = false
	pi.release_tray()
	var t := create_tween()
	t.tween_property(tray, "global_transform", Transform3D(Basis(), TRAY_OVEN), 0.6).set_trans(Tween.TRANS_SINE)
	await t.finished
	_show_oven(false)
	var g := create_tween()
	g.tween_property(glow, "light_energy", 2.0, 0.4)
	bake_left = Config.BAKE_TIME
	Game.set_hint("Baking...")
	set_process(true)

func _process(delta: float) -> void:
	if oven_state != "baking":
		set_process(false)
		return
	bake_left -= delta
	Game.bake_progress.emit(clamp(1.0 - bake_left / Config.BAKE_TIME, 0.0, 1.0))
	if bake_left <= 0.0:
		set_process(false)
		_finish_bake()

func _finish_bake() -> void:
	oven_state = "ready"
	for s in slots:
		if s["node"] != null and not s["baked"]:
			s["baked"] = true
			var mat := Config.raw_material()
			Config.set_overlay(s["node"], mat)
			var tw := create_tween()
			tw.tween_property(mat, "albedo_color:a", 0.0, 0.5)
	Game.set_baked(_baked_count())
	_show_oven(true)
	var g := create_tween()
	g.tween_property(glow, "light_energy", 0.8, 0.4)
	oven_inter.prompt = "Take tray out"
	Game.bake_progress.emit(1.0)
	Game.set_hint("Take the tray out")

func _take_tray_out(pi) -> void:
	if oven_state != "ready":
		return
	if pi.has_item():
		return
	oven_state = "idle"
	oven_inter.prompt = "Put the tray in the oven"
	Game.bake_progress.emit(0.0)
	_show_oven(false)
	tray_held = true
	pi.grab_tray(tray, 0.5)
	_refresh_tray_inter()
	Game.set_hint("Put the tray on the table")

# ---------------- bag ----------------

func _build_bag() -> void:
	bag = Node3D.new()
	bag.position = BAG_POS
	add_child(bag)
	bag_slots = Node3D.new()
	bag_slots.position = BAG_POS
	add_child(bag_slots)
	_set_bag_model(true)
	bag_inter = Interactable.make(Vector3(0.3, 0.32, 0.3), BAG_POS + Vector3(0, 0.12, 0), "bag", "Put cookies in the bag", _bag_interact, self)

func _set_bag_model(open: bool) -> void:
	for c in bag.get_children():
		c.free()
	var path: String = Config.ASSET_BAG_OPEN if open else Config.ASSET_BAG_SEALED
	if not ResourceLoader.exists(path):
		return
	var m: Node3D = (load(path) as PackedScene).instantiate()
	var b := Config.aabb_of(m)
	m.position = Vector3(-(b.position.x + b.size.x * 0.5), -b.position.y, -(b.position.z + b.size.z * 0.5))
	Config.set_gi_dynamic(m)
	bag.add_child(m)

func _bag_interact(pi) -> void:
	if bag_state == "held":
		return
	if pi.held_is_tray:
		return
	if pi.has_item():
		if pi.held_is_bag:
			return
		if not pi.held_baked:
			Game.say("Needs baking first")
			return
		if bag_items.size() >= 2:
			return
		_add_to_bag(pi.held_id)
		pi.clear_hand()
		Game.set_hint("Seal the bag")
		return
	if bag_state == "sealed":
		bag_state = "held"
		bag.visible = false
		bag_inter.set_active(false)
		pi.hold_bag()
		Game.set_hint("Give the bag to Granny")
		return
	if bag_items.size() > 0:
		_seal_bag()

func _add_to_bag(id: String) -> void:
	var idx := bag_items.size()
	var c := Config.build_cookie(id)
	var holder := Node3D.new()
	holder.add_child(c)
	holder.position = Vector3(0.03 if idx == 0 else -0.03, 0.1, 0.0)
	holder.scale = Vector3.ONE * 0.2
	bag_slots.add_child(holder)
	var t := create_tween()
	t.tween_property(holder, "scale", Vector3.ONE * 0.42, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bag_items.append({"id": id, "node": holder, "baked": true})
	Game.set_bagged(bag_items.size())
	bag_inter.prompt = "Seal bag"

func _seal_bag() -> void:
	bag_state = "sealed"
	bag_inter.prompt = "Pick up bag"
	_set_bag_model(false)
	var t := create_tween()
	t.tween_property(bag, "scale", Vector3(0.9, 0.9, 0.9), 0.12)
	t.tween_property(bag, "scale", Vector3.ONE, 0.18)
	Game.set_hint("Give the bag to Granny")

func return_bag() -> void:
	if bag_state == "held":
		bag_state = "sealed"
		bag.visible = true
		bag_inter.set_active(true)
		bag_inter.prompt = "Pick up bag"

func complete_order() -> void:
	reset_after_fail()

func reset_full() -> void:
	set_process(false)
	oven_state = "idle"
	oven_inter.prompt = "Put the tray in the oven"
	bake_left = 0.0
	glow.light_energy = 0.8
	Game.bake_progress.emit(0.0)
	_show_oven(false)
	if tray_held:
		tray_held = false
		player.release_tray()
	if player.held_is_tray:
		player.release_tray()
	player.clear_hand()
	tray.global_transform = Transform3D(Basis(), TRAY_HOME)
	tray.scale = Vector3.ONE
	reset_after_fail()
	_set_slots_enabled(true)
	_refresh_tray_inter()
	Game.set_hint("")

func reset_after_fail() -> void:
	for it in bag_items:
		it["node"].queue_free()
	bag_items.clear()
	Game.set_bagged(0)
	bag_state = "open"
	bag.visible = true
	bag.scale = Vector3.ONE
	bag_inter.prompt = "Put cookies in the bag"
	_set_bag_model(true)
	bag_inter.set_active(true)
	for s in slots:
		if s["node"] != null:
			s["node"].queue_free()
			s["node"] = null
			s["id"] = ""
			s["baked"] = false
	Game.set_baked(0)
	_refresh_tray_inter()

func bag_count() -> int:
	return bag_items.size()

func bag_has_raw() -> bool:
	for it in bag_items:
		if not it["baked"]:
			return true
	return false

func bag_matches(want: Dictionary) -> bool:
	var counts := {}
	for it in bag_items:
		counts[it["id"]] = int(counts.get(it["id"], 0)) + 1
	for id in want:
		if int(counts.get(id, 0)) != int(want[id]):
			return false
	return true
