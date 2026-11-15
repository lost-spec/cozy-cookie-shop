extends CanvasLayer

var menu: Control
var menu_cam: Camera3D
var player_cam: Camera3D
var customer: Node3D
var day_node: Node

var money_label: Label
var money_box: PanelContainer
var shown_money := 0.0
var order_card: PanelContainer
var order_label: Label
var order_rows: VBoxContainer
var check_styles: Array = []
var timer_box: HBoxContainer
var timer_bar: TimerBar
var timer_label: Label
var day_hud: PanelContainer
var day_label: Label
var cust_label: Label
var phase_dot: Panel
var phase_dot_style: StyleBoxFlat
var phase_label: Label
var day_card: ColorRect
var day_card_label: Label
var complete_panel: PanelContainer
var complete_title: Label
var complete_served: Label
var complete_earned: Label
var complete_total: Label
var next_btn: Button
var hint: Label
var prompt: Label
var cross: Control
var dlg: PanelContainer
var dlg_text: RichTextLabel
var dlg_name: Label
var dlg_tail: Panel
var dlg_timer := 0.0
var speech: Panel
var speech_tail: Panel
var toast: PanelContainer
var toast_timer := 0.0
var fade: ColorRect
var time_caption: Label
var ring: Control
var pop: Label
var play_btn: Button
var playing := false
var order_active := false
var menu_base_y := 0.0
var floaters: Array = []

class TimerBar extends Control:
	var ratio := 1.0
	var col := Color("A9B77B")
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("F1E4D3"), true)
		if ratio > 0.0:
			draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * ratio, size.y)), col, true)

class BakeRing extends Control:
	var v := 0.0
	func _draw() -> void:
		var c := size * 0.5
		var r: float = minf(c.x, c.y) - 4.0
		draw_circle(c, r, Color(0.15, 0.12, 0.1, 0.5))
		if v > 0.001:
			draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * v, 48, Config.GOLD, 6.0, true)


func _ready() -> void:
	player_cam = get_parent().get_node("Player/Camera")
	menu_cam = get_parent().get_node("MenuCamera")
	customer = get_parent().get_node("Customer")
	day_node = get_parent().get_node("Day")
	menu_base_y = menu_cam.rotation.y
	_build()
	_build_menu()
	Game.money_changed.connect(_on_money)
	Game.order_changed.connect(_on_order)
	Game.phase_changed.connect(_on_phase)
	Game.hint_changed.connect(_on_hint)
	Game.prompt_changed.connect(_on_prompt)
	Game.dialogue.connect(_on_dialogue)
	Game.toast.connect(_on_toast)
	Game.bake_progress.connect(_on_progress)
	Game.checks_changed.connect(_on_checks)
	Game.float_text.connect(_on_float)
	Game.day_changed.connect(_on_day_changed)
	Game.order_timer_changed.connect(_on_timer)
	Game.day_complete.connect(_on_day_complete)
	Game.time_changed.connect(_on_time_changed)
	menu_cam.current = true
	player_cam.current = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_hud(false)
	if Config.DEBUG_PHASE >= 0:
		call_deferred("_debug_start")

func _debug_start() -> void:
	playing = true
	menu.visible = false
	menu_cam.current = false
	player_cam.current = true
	_set_hud(true)
	day_node.begin()

# ---------------- widgets ----------------

func _panel(bg: Color, radius := 16, pad := 16) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = int(pad * 0.6)
	sb.content_margin_bottom = int(pad * 0.6)
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 3)
	p.add_theme_stylebox_override("panel", sb)
	return p

func _label(text: String, size := 18, color := Config.CHARCOAL) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _dot(sz: float, col: Color) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(sz))
	p.add_theme_stylebox_override("panel", sb)
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = -sz * 0.5
	p.offset_right = sz * 0.5
	p.offset_top = -sz * 0.5
	p.offset_bottom = sz * 0.5
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_color_override("font_color", Config.CHARCOAL)
	b.add_theme_color_override("font_hover_color", Config.CHARCOAL)
	b.add_theme_color_override("font_pressed_color", Config.CREAM)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Config.PINK
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	b.add_theme_stylebox_override("normal", sb)
	var h := sb.duplicate() as StyleBoxFlat
	h.bg_color = Config.GOLD
	b.add_theme_stylebox_override("hover", h)
	var pr := sb.duplicate() as StyleBoxFlat
	pr.bg_color = Config.MAUVE
	b.add_theme_stylebox_override("pressed", pr)
	b.pivot_offset = Vector2(170, 23)
	b.mouse_entered.connect(func(): b.create_tween().tween_property(b, "scale", Vector2.ONE * 1.05, 0.12))
	b.mouse_exited.connect(func(): b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.12))
	return b

# ---------------- build ----------------

func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	cross = Control.new()
	cross.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cross)
	cross.add_child(_dot(9.0, Config.CHARCOAL))
	cross.add_child(_dot(5.0, Config.CREAM))

	prompt = _label("", 15, Config.CREAM)
	prompt.anchor_left = 0.5
	prompt.anchor_right = 0.5
	prompt.anchor_top = 0.5
	prompt.anchor_bottom = 0.5
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.offset_left = -220
	prompt.offset_right = 220
	prompt.offset_top = 16
	prompt.offset_bottom = 40
	prompt.add_theme_color_override("font_outline_color", Config.CHARCOAL)
	prompt.add_theme_constant_override("outline_size", 4)
	root.add_child(prompt)

	money_box = _panel(Config.CREAM, 20, 14)
	money_box.position = Vector2(24, 22)
	money_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mh := HBoxContainer.new()
	mh.add_theme_constant_override("separation", 10)
	money_box.add_child(mh)
	var coin := Panel.new()
	var csb := StyleBoxFlat.new()
	csb.bg_color = Config.GOLD
	csb.set_corner_radius_all(11)
	coin.add_theme_stylebox_override("panel", csb)
	coin.custom_minimum_size = Vector2(22, 22)
	mh.add_child(coin)
	money_label = _label("$0", 20, Config.CHARCOAL)
	mh.add_child(money_label)
	root.add_child(money_box)

	day_hud = _panel(Color(0.945, 0.894, 0.827, 0.92), 16, 12)
	day_hud.anchor_left = 0.5
	day_hud.anchor_right = 0.5
	day_hud.offset_left = -150
	day_hud.offset_right = 150
	day_hud.offset_top = 12
	day_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	day_hud.visible = false
	var dhv := VBoxContainer.new()
	dhv.add_theme_constant_override("separation", 2)
	day_hud.add_child(dhv)
	var dhh := HBoxContainer.new()
	dhh.alignment = BoxContainer.ALIGNMENT_CENTER
	dhh.add_theme_constant_override("separation", 16)
	dhv.add_child(dhh)
	day_label = _label("Day 1", 20, Config.CHARCOAL)
	dhh.add_child(day_label)
	cust_label = _label("Customer 0/4", 16, Config.MAUVE)
	dhh.add_child(cust_label)
	var phh := HBoxContainer.new()
	phh.alignment = BoxContainer.ALIGNMENT_CENTER
	phh.add_theme_constant_override("separation", 8)
	dhv.add_child(phh)
	phase_dot = Panel.new()
	phase_dot_style = StyleBoxFlat.new()
	phase_dot_style.bg_color = Color("e0b65a")
	phase_dot_style.set_corner_radius_all(6)
	phase_dot.add_theme_stylebox_override("panel", phase_dot_style)
	phase_dot.custom_minimum_size = Vector2(12, 12)
	phase_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	phh.add_child(phase_dot)
	phase_label = _label("Day · 9:00 AM", 14, Config.CHARCOAL)
	phh.add_child(phase_label)
	root.add_child(day_hud)

	order_card = _panel(Config.CREAM, 16, 18)
	order_card.anchor_left = 0.5
	order_card.anchor_right = 0.5
	order_card.offset_left = -190
	order_card.offset_right = 190
	order_card.offset_top = 92
	order_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	order_card.visible = false
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 5)
	order_card.add_child(ov)
	order_label = _label("Order", 17, Config.CHARCOAL)
	order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ov.add_child(order_label)
	order_rows = VBoxContainer.new()
	order_rows.add_theme_constant_override("separation", 3)
	ov.add_child(order_rows)
	timer_box = HBoxContainer.new()
	timer_box.add_theme_constant_override("separation", 8)
	timer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_box.visible = false
	ov.add_child(timer_box)
	timer_bar = TimerBar.new()
	timer_bar.custom_minimum_size = Vector2(250, 10)
	timer_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	timer_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_box.add_child(timer_bar)
	timer_label = _label("50s", 14, Config.CHARCOAL)
	timer_box.add_child(timer_label)
	root.add_child(order_card)

	hint = _label("", 16, Config.CREAM)
	hint.anchor_left = 0.5
	hint.anchor_right = 0.5
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.offset_left = -320
	hint.offset_right = 320
	hint.offset_top = -66
	hint.offset_bottom = -34
	hint.modulate = Color(1, 1, 1, 0.78)
	hint.add_theme_color_override("font_outline_color", Config.CHARCOAL)
	hint.add_theme_constant_override("outline_size", 4)
	root.add_child(hint)

	dlg = _panel(Config.CREAM, 16, 14)
	dlg.visible = false
	dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dsb := dlg.get_theme_stylebox("panel") as StyleBoxFlat
	dsb.border_color = Config.MAUVE
	dsb.set_border_width_all(2)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 6)
	dlg.add_child(dv)
	var dh := HBoxContainer.new()
	dv.add_child(dh)
	var pill := _panel(Config.PISTACHIO, 8, 9)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg_name = _label("", 13, Config.CREAM)
	pill.add_child(dlg_name)
	dh.add_child(pill)
	dlg_text = RichTextLabel.new()
	dlg_text.bbcode_enabled = false
	dlg_text.fit_content = true
	dlg_text.scroll_active = false
	dlg_text.custom_minimum_size = Vector2(300, 0)
	dlg_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg_text.add_theme_font_size_override("normal_font_size", 16)
	dlg_text.add_theme_color_override("default_color", Config.CHARCOAL)
	dv.add_child(dlg_text)
	root.add_child(dlg)

	dlg_tail = Panel.new()
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Config.CREAM
	tsb.border_color = Config.MAUVE
	tsb.set_border_width_all(2)
	dlg_tail.add_theme_stylebox_override("panel", tsb)
	dlg_tail.size = Vector2(14, 14)
	dlg_tail.pivot_offset = Vector2(7, 7)
	dlg_tail.rotation = PI / 4.0
	dlg_tail.visible = false
	dlg_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dlg_tail)

	speech = Panel.new()
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = Config.PINK
	ssb.border_color = Config.MAUVE
	ssb.set_border_width_all(2)
	ssb.set_corner_radius_all(12)
	ssb.shadow_color = Color(0, 0, 0, 0.14)
	ssb.shadow_size = 5
	ssb.shadow_offset = Vector2(0, 2)
	speech.add_theme_stylebox_override("panel", ssb)
	speech.size = Vector2(36, 26)
	speech.pivot_offset = Vector2(18, 13)
	speech.visible = false
	speech.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sl := _label("...", 16, Config.CHARCOAL)
	sl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speech.add_child(sl)
	root.add_child(speech)

	speech_tail = Panel.new()
	var stb := StyleBoxFlat.new()
	stb.bg_color = Config.PINK
	stb.border_color = Config.MAUVE
	stb.set_border_width_all(2)
	speech_tail.add_theme_stylebox_override("panel", stb)
	speech_tail.size = Vector2(9, 9)
	speech_tail.pivot_offset = Vector2(4.5, 4.5)
	speech_tail.rotation = PI / 4.0
	speech_tail.visible = false
	speech_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(speech_tail)

	toast = _panel(Config.PISTACHIO, 14, 16)
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.offset_left = -110
	toast.offset_right = 110
	toast.offset_top = 300
	toast.visible = false
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_child(_label("Order complete!", 16, Config.CREAM))
	root.add_child(toast)

	ring = BakeRing.new()
	ring.visible = false
	ring.size = Vector2(56, 56)
	ring.pivot_offset = Vector2(28, 28)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ring)

	pop = _label("", 24, Config.GOLD)
	pop.visible = false
	pop.add_theme_color_override("font_outline_color", Config.CHARCOAL)
	pop.add_theme_constant_override("outline_size", 5)
	root.add_child(pop)

	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)

	time_caption = _label("", 30, Config.CREAM)
	time_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	time_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_caption.visible = false
	time_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(time_caption)

	day_card = ColorRect.new()
	day_card.color = Color("3E2B33")
	day_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	day_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	day_card.visible = false
	day_card_label = _label("Day 1", 64, Config.CREAM)
	day_card_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	day_card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	day_card.add_child(day_card_label)
	root.add_child(day_card)

	complete_panel = _panel(Config.CREAM, 20, 26)
	complete_panel.anchor_left = 0.5
	complete_panel.anchor_right = 0.5
	complete_panel.anchor_top = 0.5
	complete_panel.anchor_bottom = 0.5
	complete_panel.offset_left = -190
	complete_panel.offset_right = 190
	complete_panel.offset_top = -150
	complete_panel.offset_bottom = 150
	complete_panel.visible = false
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 10)
	complete_panel.add_child(cv)
	complete_title = _label("Day 1 complete", 28, Config.CHARCOAL)
	complete_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(complete_title)
	complete_served = _label("Customers served 4/4", 18, Config.CHARCOAL)
	cv.add_child(complete_served)
	complete_earned = _label("Earned today $0", 18, Config.CHARCOAL)
	cv.add_child(complete_earned)
	complete_total = _label("Total money $0", 18, Config.MAUVE)
	cv.add_child(complete_total)
	next_btn = _button("Next day")
	next_btn.pressed.connect(_on_next_day)
	cv.add_child(next_btn)
	root.add_child(complete_panel)

func _build_menu() -> void:
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)

	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.1, 0.06, 0.04, 0.0))
	grad.set_color(1, Color(0.1, 0.06, 0.04, 0.9))
	gt.gradient = grad
	var vig := TextureRect.new()
	vig.texture = gt
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.modulate.a = 0.4
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(vig)

	var panel := _panel(Color(0.945, 0.894, 0.827, 0.95), 20, 26)
	panel.position = Vector2(88, 190)
	panel.custom_minimum_size = Vector2(370, 0)
	menu.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	vb.add_child(_label(Config.TITLE, 34, Config.CHARCOAL))
	vb.add_child(_label("A cozy first-person cookie shop", 15, Config.MAUVE))
	play_btn = _button("Play")
	play_btn.pressed.connect(_on_play)
	vb.add_child(play_btn)
	var quit_btn := _button("Quit")
	quit_btn.pressed.connect(func(): get_tree().quit())
	vb.add_child(quit_btn)

	var ids := ["caramel", "jam", "pistachio_rose"]
	var offs := [Vector3(0.9, 0.22, -1.8), Vector3(1.12, -0.02, -2.0), Vector3(0.84, -0.3, -1.7)]
	for i in 3:
		var c := Config.build_cookie(ids[i])
		c.scale = c.scale * 2.2
		c.rotation_degrees = Vector3(-90, 0, 0)
		c.position = offs[i]
		menu_cam.add_child(c)
		floaters.append(c)

# ---------------- runtime ----------------

func _process(delta: float) -> void:
	for f in floaters:
		f.visible = menu.visible
	if menu.visible:
		menu_cam.rotation.y = menu_base_y + sin(Time.get_ticks_msec() * 0.0001) * 0.2
		for i in floaters.size():
			var f: Node3D = floaters[i]
			f.rotate_y(delta * 0.5)
			f.rotate_x(delta * 0.2)
			f.position.y += sin(Time.get_ticks_msec() * 0.001 + i) * delta * 0.01

	if dlg.visible:
		dlg_timer -= delta
		if dlg_timer <= 0.0:
			dlg.visible = false
		var cam := get_viewport().get_camera_3d()
		if cam == null:
			dlg.visible = false
		else:
			var wp: Vector3 = customer.head_global() if customer.has_method("head_global") else customer.global_position + Vector3(0, 2.05, 0)
			if cam.is_position_behind(wp):
				dlg.visible = false
			else:
				var sp := cam.unproject_position(wp)
				var vs := get_viewport().get_visible_rect().size
				var w: float = max(dlg.size.x, 320.0)
				sp.x = clampf(sp.x, w * 0.5 + 12.0, vs.x - w * 0.5 - 12.0)
				sp.y = clampf(sp.y, 90.0, vs.y - 30.0)
				dlg.position = Vector2(sp.x - w * 0.5, sp.y - dlg.size.y - 12.0)
	dlg_tail.visible = dlg.visible
	if dlg.visible:
		dlg_tail.position = dlg.position + Vector2(dlg.size.x * 0.5 - 7.0, dlg.size.y - 7.0)

	var want_icon := false
	if customer != null and customer.has_method("wants_icon"):
		want_icon = customer.wants_icon() and not dlg.visible
	if want_icon:
		var icam := get_viewport().get_camera_3d()
		if icam == null:
			want_icon = false
		else:
			var iwp: Vector3 = customer.head_global() + Vector3(0, 0.34, 0)
			iwp.y += sin(Time.get_ticks_msec() * 0.004) * 0.025
			if icam.is_position_behind(iwp):
				want_icon = false
			else:
				var isp := icam.unproject_position(iwp)
				speech.position = isp - Vector2(18, 13)
				speech_tail.position = speech.position + Vector2(13.5, 20)
				var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.004) * 0.04
				speech.scale = Vector2(pulse, pulse)
	speech.visible = want_icon
	speech_tail.visible = want_icon

	if toast.visible:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast.visible = false

	if ring.visible:
		var cam2 := get_viewport().get_camera_3d()
		if cam2 != null:
			var wp2 := Vector3(2.5, 3.2, -5.55)
			if not cam2.is_position_behind(wp2):
				ring.position = cam2.unproject_position(wp2) - ring.size * 0.5

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and playing:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			menu.visible = true
			menu_cam.current = true
			player_cam.current = false
			_set_hud(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dlg.visible and dlg_text.visible_characters < dlg_text.get_total_character_count():
			dlg_text.visible_characters = -1

func _set_hud(on: bool) -> void:
	cross.visible = on
	prompt.visible = on
	hint.visible = on
	money_box.visible = on
	day_hud.visible = on
	order_card.visible = on and order_active
	if not on:
		ring.visible = false
		timer_box.visible = false

func _on_play() -> void:
	if playing:
		menu.visible = false
		menu_cam.current = false
		player_cam.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_set_hud(true)
		return
	playing = true
	play_btn.text = "Resume"
	var t := create_tween()
	t.tween_property(fade, "color:a", 1.0, 0.4)
	await t.finished
	menu.visible = false
	menu_cam.current = false
	player_cam.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_set_hud(true)
	day_node.begin()

func _on_next_day() -> void:
	next_btn.disabled = true
	var tw := create_tween()
	tw.tween_property(complete_panel, "modulate:a", 0.0, 0.25)
	await tw.finished
	await day_node.next_day()
	next_btn.disabled = false

func _on_money(value: int) -> void:
	var tw := create_tween()
	tw.tween_method(_set_money, shown_money, float(value), 0.6)

func _set_money(v: float) -> void:
	shown_money = v
	money_label.text = "$%d" % int(round(v))

func _on_order(items: Dictionary) -> void:
	order_active = true
	order_label.text = "Order"
	for c in order_rows.get_children():
		c.queue_free()
	check_styles.clear()
	for id in items.keys():
		var n: int = int(items[id])
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		var cp := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.set_corner_radius_all(4)
		sb.set_border_width_all(2)
		sb.border_color = Config.MAUVE
		cp.add_theme_stylebox_override("panel", sb)
		cp.custom_minimum_size = Vector2(15, 15)
		cp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(cp)
		row.add_child(_label("%dx %s" % [n, Config.display_name(id)], 16, Config.CHARCOAL))
		order_rows.add_child(row)
		check_styles.append({"style": sb, "id": id, "count": n})
	order_card.visible = playing
	_on_checks(0, 0)

func _on_phase(p: String) -> void:
	if p != "gathering":
		order_active = false
		order_card.visible = false
		timer_box.visible = false

func _on_checks(_baked: int, _bagged: int) -> void:
	var st := get_parent().get_node_or_null("Stations")
	var counts := {}
	if st != null:
		for it in st.bag_items:
			counts[it["id"]] = int(counts.get(it["id"], 0)) + 1
	for it in check_styles:
		var filled: bool = int(counts.get(it["id"], 0)) >= int(it["count"])
		(it["style"] as StyleBoxFlat).bg_color = Config.PISTACHIO if filled else Color(0, 0, 0, 0)

func _on_hint(text: String) -> void:
	hint.text = text

func _on_prompt(text: String) -> void:
	prompt.text = text

func _on_dialogue(speaker: String, text: String) -> void:
	dlg.visible = true
	dlg_name.text = speaker if speaker != "" else "Tip"
	dlg_text.text = text
	dlg_text.visible_characters = 0
	var total := text.length()
	var dur: float = max(float(total) / 40.0, 0.2)
	var tw := create_tween()
	tw.tween_property(dlg_text, "visible_characters", total, dur)
	dlg_timer = dur + 3.0

func _on_toast(_text: String) -> void:
	toast.visible = true
	toast_timer = 2.0

func _on_progress(v: float) -> void:
	if v >= 1.0:
		ring.set("v", 1.0)
		ring.queue_redraw()
		ring.visible = true
		var tw := create_tween()
		tw.tween_property(ring, "scale", Vector2.ONE * 1.35, 0.12)
		tw.tween_property(ring, "scale", Vector2.ONE, 0.18)
		tw.tween_callback(func(): ring.visible = false)
		return
	ring.visible = v > 0.0
	ring.set("v", v)
	ring.queue_redraw()

func _on_float(text: String, wp: Vector3) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or cam.is_position_behind(wp):
		return
	var sp := cam.unproject_position(wp)
	pop.text = text
	pop.position = sp - Vector2(30, 10)
	pop.modulate.a = 1.0
	pop.visible = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(pop, "position:y", sp.y - 70, 1.2)
	tw.tween_property(pop, "modulate:a", 0.0, 1.2)
	tw.chain().tween_callback(func(): pop.visible = false)

func _on_day_changed(day: int, index: int, total: int) -> void:
	day_label.text = "Day %d" % day
	cust_label.text = "Customer %d/%d" % [index, total]

func _on_timer(left: float, total: float) -> void:
	if left <= 0.0 or total <= 0.0:
		timer_box.visible = false
		timer_bar.modulate.a = 1.0
		return
	timer_box.visible = playing
	timer_bar.ratio = clampf(left / total, 0.0, 1.0)
	if left < 10.0:
		timer_bar.col = Config.COPPER
		timer_bar.modulate.a = 0.7 + 0.3 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012))
	elif left < 20.0:
		timer_bar.col = Config.GOLD
		timer_bar.modulate.a = 1.0
	else:
		timer_bar.col = Config.PISTACHIO
		timer_bar.modulate.a = 1.0
	timer_label.text = "%ds" % int(ceil(left))
	timer_bar.queue_redraw()

func _on_time_changed(phase: String, clock: String, color: Color) -> void:
	phase_label.text = "%s · %s" % [phase, clock]
	phase_dot_style.bg_color = color

func _on_day_complete(served: int, earned: int, total_money: int) -> void:
	await get_tree().create_timer(0.6).timeout
	complete_title.text = "Day %d complete" % day_node.day
	complete_served.text = "Customers served %d/%d" % [served, Config.CUSTOMERS_PER_DAY]
	complete_earned.text = "Earned today $%d" % earned
	complete_total.text = "Total money $%d" % total_money
	complete_panel.visible = true
	complete_panel.modulate.a = 0.0
	complete_panel.scale = Vector2(0.92, 0.92)
	complete_panel.pivot_offset = Vector2(190, 150)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(complete_panel, "modulate:a", 1.0, 0.25)
	tw.tween_property(complete_panel, "scale", Vector2.ONE, 0.25)

func hide_day_complete() -> void:
	complete_panel.visible = false
	if playing:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func show_day_card(n: int) -> void:
	day_card_label.text = "Day %d" % n
	day_card.visible = true
	day_card.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(day_card, "modulate:a", 1.0, 0.3)
	await tw.finished
	await get_tree().create_timer(2.0).timeout
	var tw2 := create_tween()
	tw2.tween_property(day_card, "modulate:a", 0.0, 0.35)
	await tw2.finished
	day_card.visible = false

func fade_black(alpha: float, duration: float) -> void:
	if duration <= 0.0:
		fade.color.a = alpha
		return
	var tw := create_tween()
	tw.tween_property(fade, "color:a", alpha, duration)
	await tw.finished

func show_time_caption(text: String) -> void:
	time_caption.text = text
	time_caption.visible = true
	time_caption.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(time_caption, "modulate:a", 1.0, 0.15)
	await tw.finished
	await get_tree().create_timer(1.0).timeout
	var tw2 := create_tween()
	tw2.tween_property(time_caption, "modulate:a", 0.0, 0.2)
	await tw2.finished
	time_caption.visible = false
