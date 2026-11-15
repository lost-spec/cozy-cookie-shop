extends Node3D

var customer: Node3D
var ui: Node
var stations: Node
var day := 1
var slot := 0
var pool: Array = []
var served := 0
var earned := 0
var timer_left := 0.0
var timer_running := false
var started := false
var day_done := false

var sun: DirectionalLight3D
var env: Environment
var exterior_fill: OmniLight3D
var sky_mat: ProceduralSkyMaterial
var current_phase := "Day"

var lamp_lights: Array = []
var lamp_base: Array = []
var fill_lights: Array = []
var fill_base: Array = []
var vignette: CanvasLayer

const PHASE_COLORS := {
	"Day": Color("e0b65a"),
	"Afternoon": Color("e08a4a"),
	"Evening": Color("d98a9a"),
	"Night": Color("6f86b8"),
}

func _ready() -> void:
	customer = get_parent().get_node("Customer")
	ui = get_parent().get_node("UI")
	stations = get_parent().get_node("Stations")
	sun = get_parent().get_node("Sun")
	env = get_parent().get_node("Env").environment
	exterior_fill = get_parent().get_node_or_null("ExteriorFill")
	_setup_sky()
	_setup_environment()
	_setup_sun()
	_setup_emissive()
	_setup_lights()
	_setup_halos()
	_setup_contact_shadows()
	_setup_vignette()
	apply_phase(current_phase)
	customer.finished.connect(_on_finished)
	customer.gone.connect(_on_gone)
	customer.order_started.connect(_on_order_started)
	Game.order_timer_changed.emit(0.0, Config.ORDER_TIME)
	set_process(false)

# ---------------- environment ----------------

func _setup_sky() -> void:
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("5D8FC7")
	sky_mat.sky_horizon_color = Color("D9C3A3")
	sky_mat.sky_curve = 0.15
	sky_mat.sky_energy_multiplier = 0.85
	sky_mat.ground_horizon_color = Color("D9C3A3")
	sky_mat.ground_bottom_color = Color("6B5A4A")
	sky_mat.ground_curve = 0.05
	sky_mat.ground_energy_multiplier = 0.7
	sky_mat.sun_angle_max = 30.0
	sky_mat.sun_curve = 0.15
	var s := Sky.new()
	s.sky_material = sky_mat
	s.radiance_size = Sky.RADIANCE_SIZE_256
	env.sky = s
	env.background_mode = Environment.BG_SKY
	env.background_energy_multiplier = 1.0
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.7
	env.ambient_light_color = Color("C4D6EA")
	env.ambient_light_energy = 1.0

func _setup_environment() -> void:
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_strength = 1.0
	env.glow_bloom = 0.05
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.glow_hdr_threshold = 1.0
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.05
	env.fog_enabled = true
	env.fog_light_color = Color("F4E8D4")
	env.fog_light_energy = 1.0
	env.fog_density = 0.004
	env.fog_sky_affect = 0.0
	env.fog_aerial_perspective = 0.0
	env.fog_depth_begin = 5.0
	env.fog_depth_end = 35.0
	env.fog_depth_curve = 1.0

func _setup_sun() -> void:
	sun.light_specular = 0.25
	sun.light_angular_distance = 0.6
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.85
	sun.light_bake_mode = Light3D.BAKE_DYNAMIC
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 30.0
	sun.shadow_blur = 1.4
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.5

func _setup_emissive() -> void:
	var bulb_mat := load("res://mat_pendant_bulb_emissive.tres") as StandardMaterial3D
	if bulb_mat != null:
		bulb_mat.emission = Color("FFC98A")
		bulb_mat.emission_energy_multiplier = 1.4
		for i in range(1, 4):
			var bulb := get_parent().get_node_or_null("CookieShop/PENDANT_Bulb_%d" % i) as GeometryInstance3D
			if bulb != null:
				bulb.material_override = bulb_mat
	var bar := get_parent().get_node_or_null("CookieShop/LIGHTBAR_Baking") as GeometryInstance3D
	if bar != null:
		var bar_mat := StandardMaterial3D.new()
		bar_mat.albedo_color = Color("FFD9A8")
		bar_mat.emission_enabled = true
		bar_mat.emission = Color("FFD9A8")
		bar_mat.emission_energy_multiplier = 1.2
		bar.material_override = bar_mat

# ---------------- interior lights ----------------

func _setup_lights() -> void:
	lamp_lights.clear()
	lamp_base.clear()
	for n in get_tree().get_nodes_in_group("lamp"):
		var l := n as SpotLight3D
		if l == null:
			continue
		# Pendants get real shadows; the ceiling track spots stay unshadowed.
		l.shadow_enabled = str(l.name).contains("Pendant")
		l.light_specular = 0.3
		l.light_bake_mode = Light3D.BAKE_DYNAMIC
		lamp_lights.append(l)
		lamp_base.append(l.light_energy)

	fill_lights.clear()
	fill_base.clear()
	var fill_root := get_parent().get_node_or_null("FillLights")
	if fill_root != null:
		for n in fill_root.get_children():
			var f := n as OmniLight3D
			if f == null:
				continue
			f.shadow_enabled = false
			f.light_specular = 0.0
			f.light_bake_mode = Light3D.BAKE_DYNAMIC
			fill_lights.append(f)
			fill_base.append(f.light_energy)

	var oven := get_parent().get_node_or_null("CookieShop/OVEN_Body/OvenGlow") as OmniLight3D
	if oven != null:
		oven.light_color = Color("FF9A3C")
		oven.light_energy = 0.8
		oven.omni_range = 2.2
		oven.light_specular = 0.2
		oven.shadow_enabled = false
		oven.light_bake_mode = Light3D.BAKE_DISABLED
		oven.add_to_group("oven_glow")
	if exterior_fill != null:
		exterior_fill.light_specular = 0.0
		exterior_fill.light_bake_mode = Light3D.BAKE_DYNAMIC

# ---------------- lamp halos ----------------

func _setup_halos() -> void:
	var pendant_mat := _halo_material(Color("FFB35C"))
	var track_mat := _halo_material(Color("FFD9A8"))
	var oven_mat := _halo_material(Color("FF7A2E"))

	var shop := get_parent().get_node_or_null("CookieShop")
	if shop != null:
		for i in range(1, 4):
			var bulb := shop.get_node_or_null("PENDANT_Bulb_%d" % i) as Node3D
			if bulb != null:
				_add_halo("Glow_Pendant_%d" % i, to_local(bulb.global_position + Vector3(0, -0.08, 0)), pendant_mat, 0.5)
	var track_x := [-0.8, -0.25, 0.3]
	for i in range(3):
		_add_halo("Glow_Track_%d" % (i + 1), Vector3(track_x[i], 1.77, -5.62), track_mat, 0.32)
	_add_halo("Glow_Oven", Vector3(2.5, 1.05, -5.12), oven_mat, 0.55)

func _halo_material(col: Color) -> StandardMaterial3D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	grad.add_point(0.35, Color(1, 1, 1, 0.5))
	grad.add_point(0.7, Color(1, 1, 1, 0.1))
	var tex := GradientTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.gradient = grad
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r, col.g, col.b, 0.32)
	m.albedo_texture = tex
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return m

func _add_halo(nm: String, pos: Vector3, mat: StandardMaterial3D, size: float) -> void:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	mi.mesh = q
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.position = pos
	add_child(mi)

func _setup_contact_shadows() -> void:
	var mat := _shadow_material()
	var spots := [Vector3(-1.5, 0.055, 2.2), Vector3(-0.3, 0.055, 2.2)]
	for i in spots.size():
		_add_shadow_quad("ContactShadow_Table_%d" % (i + 1), spots[i], mat, 1.15)

func _shadow_material() -> StandardMaterial3D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.9))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	grad.add_point(0.45, Color(1, 1, 1, 0.55))
	var tex := GradientTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.gradient = grad
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.10, 0.055, 0.035, 0.42)
	m.albedo_texture = tex
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return m

func _add_shadow_quad(nm: String, pos: Vector3, mat: StandardMaterial3D, size: float) -> void:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	mi.mesh = q
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.rotation_degrees = Vector3(-90, 0, 0)
	mi.position = pos
	add_child(mi)

func _setup_vignette() -> void:
	vignette = CanvasLayer.new()
	vignette.name = "Vignette"
	vignette.layer = 0
	vignette.visible = false
	add_child(vignette)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.18, 0.10, 0.06, 0.0))
	grad.set_color(1, Color(0.18, 0.10, 0.06, 1.0))
	grad.add_point(0.55, Color(0.18, 0.10, 0.06, 0.0))
	var tex := GradientTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.gradient = grad
	var rect := TextureRect.new()
	rect.texture = tex
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate.a = 0.10
	vignette.add_child(rect)

# ---------------- phases ----------------

func _sun_basis(p: Dictionary) -> Basis:
	return Basis.from_euler(Vector3(deg_to_rad(-float(p["elevation"])), deg_to_rad(float(p["yaw"])), 0.0))

func apply_phase(phase: String, _duration: float = 0.0) -> void:
	current_phase = phase
	var p: Dictionary = Config.LIGHT_PHASES.get(phase, Config.LIGHT_PHASES["Day"])
	sun.light_color = p["sun_color"]
	sun.light_energy = p["sun_energy"]
	sun.basis = _sun_basis(p)
	sun.shadow_opacity = p["shadow_opacity"]
	if sky_mat != null:
		sky_mat.sky_top_color = p["sky_top"]
		sky_mat.sky_horizon_color = p["sky_horizon"]
		sky_mat.ground_horizon_color = p["ground_horizon"]
		sky_mat.ground_bottom_color = p["ground_bottom"]
	env.tonemap_exposure = p["exposure"]
	env.fog_light_color = p["fog_color"]
	env.fog_density = p["fog_density"]
	env.ambient_light_energy = p["ambient"]
	var fill_mul: float = p.get("fill", 1.0)
	for i in fill_lights.size():
		(fill_lights[i] as Light3D).light_energy = float(fill_base[i]) * fill_mul
	var lamp_mul: float = p.get("lamp", 1.0)
	for i in lamp_lights.size():
		(lamp_lights[i] as Light3D).light_energy = float(lamp_base[i]) * lamp_mul

func begin() -> void:
	if started:
		return
	started = true
	if vignette != null:
		vignette.visible = true
	_start_day(1)

func _start_day(n: int) -> void:
	day = n
	slot = 0
	served = 0
	earned = 0
	timer_running = false
	timer_left = 0.0
	day_done = false
	pool = Config.CUSTOMERS.keys()
	pool.shuffle()
	Game.set_phase("waiting")
	Game.set_hint("")
	Game.order_timer_changed.emit(0.0, Config.ORDER_TIME)
	Game.day_changed.emit(day, 0, Config.CUSTOMERS_PER_DAY)
	var phase := "Day"
	var idx := 0
	if Config.DEBUG_PHASE >= 0:
		idx = clampi(Config.DEBUG_PHASE, 0, Config.DAY_PHASES.size() - 1)
		phase = Config.DAY_PHASES[idx]
	apply_phase(phase, 0.0)
	Game.time_changed.emit(phase, Config.DAY_TIMES[idx], PHASE_COLORS[phase])
	await ui.show_day_card(day)
	await ui.fade_black(0.0, 0.4)
	_spawn()

func _spawn() -> void:
	Game.set_phase("waiting")
	Game.day_changed.emit(day, slot + 1, Config.CUSTOMERS_PER_DAY)
	customer.begin(str(pool[slot]))

func _on_order_started() -> void:
	timer_left = Config.ORDER_TIME
	timer_running = true
	set_process(true)
	Game.order_timer_changed.emit(timer_left, Config.ORDER_TIME)

func _process(delta: float) -> void:
	if not timer_running:
		return
	timer_left = maxf(timer_left - delta, 0.0)
	Game.order_timer_changed.emit(timer_left, Config.ORDER_TIME)
	if timer_left <= 0.0:
		timer_running = false
		set_process(false)
		customer.timeout()

func _on_finished(success: bool) -> void:
	timer_running = false
	set_process(false)
	Game.order_timer_changed.emit(0.0, Config.ORDER_TIME)
	Game.set_phase("waiting")
	if success:
		served += 1
		earned += Config.order_total(Config.CUSTOMERS[customer.cust_id]["order"])
	stations.reset_full()
	Game.set_hint("")

func _on_gone() -> void:
	if slot >= Config.CUSTOMERS_PER_DAY - 1:
		day_done = true
		Game.set_phase("day_done")
		Game.day_complete.emit(served, earned, Game.money)
		return
	slot += 1
	var phase: String = Config.DAY_PHASES[slot]
	await ui.fade_black(1.0, 0.5)
	apply_phase(phase, 0.0)
	Game.time_changed.emit(phase, Config.DAY_TIMES[slot], PHASE_COLORS[phase])
	await ui.show_time_caption(Config.DAY_TIMES[slot])
	await ui.fade_black(0.0, 0.7)
	_spawn()

func next_day() -> void:
	if not day_done:
		return
	day_done = false
	await ui.fade_black(1.0, 0.4)
	ui.hide_day_complete()
	await _start_day(day + 1)
