class_name Config
extends RefCounted

const TITLE := "Cozy Cookie Shop"
const COOKIE_DIAMETER := 0.14
const BAKE_TIME := 6.0
const INTERACT_RANGE := 3.0

const ASSET_SHOP := "res://cookie_shop.glb"
const ASSET_GRANNY := "res://granny.glb"
const ASSET_BAG_OPEN := "res://bag_open.glb"
const ASSET_BAG_SEALED := "res://bag_sealed.glb"
const ASSET_OVEN_OPEN := "res://cookie_oven.glb"
const ASSET_TRAY := "res://cookie_oven_tray.glb"

const COOKIES := {
	"chocolate_chip": "res://chocolate_chip_cookie.glb",
	"jam": "res://strawberry_jam_cookie.glb",
	"smores": "res://cookies_and_cream_cookie.glb",
	"caramel": "res://caramel_cookie.glb",
	"pistachio_rose": "res://pistachio_rose_spec.glb",
}

const COOKIE_COLORS := {
	"chocolate_chip": Color("6B4A3A"),
	"jam": Color("B5403A"),
	"smores": Color("C9A27A"),
	"caramel": Color("D0A06A"),
	"pistachio_rose": Color("A9B77B"),
}

const CUSTOMERS := {
	"granny": {
		"name": "Granny",
		"asset": "res://granny.glb",
		"speed": 0.7,
		"order": {"caramel": 2},
		"lines": {
			"order": "Good morning, dear! Could I get two caramel cookies, please?",
			"repeat": "Two caramel cookies, dear.",
			"success": "Lovely, thank you dear!",
			"raw": "Oh dear, these are still frozen!",
			"count": "I asked for two cookies, dear.",
			"type": "These aren't what I asked for, dear.",
			"timeout": "Oh well, my tea is getting cold. Goodbye, dear.",
		},
	},
	"child": {
		"name": "Child",
		"asset": "res://child.glb",
		"speed": 1.1,
		"order": {"chocolate_chip": 2},
		"lines": {
			"order": "Hi! Can I have two chocolate chip cookies? Please please please!",
			"repeat": "Two chocolate chip cookies, please!",
			"success": "Yay! Thank you!!",
			"raw": "Ew, they're cold!",
			"count": "I wanted two cookies!",
			"type": "That's not chocolate chip!",
			"timeout": "I can't wait anymore... bye.",
		},
	},
	"man": {
		"name": "Man",
		"asset": "res://man.glb",
		"speed": 1.0,
		"order": {"pistachio_rose": 1, "jam": 1},
		"lines": {
			"order": "Good afternoon. One pistachio rose and one jam cookie, if you would.",
			"repeat": "One pistachio rose, one jam. Thank you.",
			"success": "Excellent. Much appreciated.",
			"raw": "I believe these haven't been baked.",
			"count": "I ordered two cookies.",
			"type": "I'm afraid that isn't my order.",
			"timeout": "I have a meeting to catch. Never mind.",
		},
	},
	"guitarist": {
		"name": "Guitarist",
		"asset": "res://guitarist.glb",
		"speed": 0.9,
		"order": {"smores": 1, "caramel": 1},
		"lines": {
			"order": "Hey, man. One smores and one caramel, whenever you're ready.",
			"repeat": "One smores, one caramel. No rush.",
			"success": "Sweet, thanks man. Rock on.",
			"raw": "Dude, these are ice cold.",
			"count": "Uh, I asked for two cookies.",
			"type": "Uh, that's not what I ordered.",
			"timeout": "Gotta catch my set. Catch you later.",
		},
	},
}

const PRICES := {}
const DEFAULT_PRICE := 4
const ORDER_TIME := 50.0
const CUSTOMERS_PER_DAY := 4
const DAY_PHASES := ["Day", "Afternoon", "Evening", "Night"]
const DAY_TIMES := ["9:00 AM", "1:00 PM", "6:00 PM", "9:00 PM"]

# -1 = off. 0..3 forces Day / Afternoon / Evening / Night at startup and skips the menu.
const DEBUG_PHASE := -1

# Lighting phase presets (Spec 04). GL Compatibility has no GI or lightmap
# baking, so these drive a dynamic-only look: sun + sky ambient + lamp spots +
# unshadowed fill lights. "ambient" scales the sky/ambient contribution and
# "fill" scales the FillLights rig energy.
const LIGHT_PHASES := {
	"Day": {
		"sun_color": Color("FFE2B8"), "sun_energy": 2.2, "elevation": 28.0, "yaw": 25.0,
		"shadow_opacity": 0.85,
		"sky_top": Color("5D8FC7"), "sky_horizon": Color("D9C3A3"),
		"ground_horizon": Color("D9C3A3"), "ground_bottom": Color("6B5A4A"),
		"fog_color": Color("D9C3A3"), "fog_density": 0.0035,
		"exposure": 1.0,
		"lamp": 1.0, "fill": 0.75, "ambient": 1.0,
	},
	"Afternoon": {
		"sun_color": Color("FFD9A8"), "sun_energy": 1.8, "elevation": 22.0, "yaw": 0.0,
		"shadow_opacity": 0.85,
		"sky_top": Color("5D86BA"), "sky_horizon": Color("E8C89B"),
		"ground_horizon": Color("C9A87E"), "ground_bottom": Color("8A6B52"),
		"fog_color": Color("E8C89B"), "fog_density": 0.0038,
		"exposure": 1.0,
		"lamp": 1.1, "fill": 0.8, "ambient": 1.0,
	},
	"Evening": {
		"sun_color": Color("FF9A5C"), "sun_energy": 1.2, "elevation": 8.0, "yaw": -18.0,
		"shadow_opacity": 0.9,
		"sky_top": Color("4B4F86"), "sky_horizon": Color("F09A6C"),
		"ground_horizon": Color("B87F7A"), "ground_bottom": Color("5A3E4A"),
		"fog_color": Color("F2A57A"), "fog_density": 0.0045,
		"exposure": 0.95,
		"lamp": 1.4, "fill": 1.0, "ambient": 0.85,
	},
	"Night": {
		"sun_color": Color("8FA8E0"), "sun_energy": 0.3, "elevation": 38.0, "yaw": 40.0,
		"shadow_opacity": 0.9,
		"sky_top": Color("0A1030"), "sky_horizon": Color("1F2850"),
		"ground_horizon": Color("1A2040"), "ground_bottom": Color("080C1A"),
		"fog_color": Color("1F2850"), "fog_density": 0.005,
		"exposure": 1.1,
		"lamp": 1.9, "fill": 1.25, "ambient": 0.55,
	},
}

const CREAM := Color("f1e4d3")
const MAUVE := Color("a38a82")
const PISTACHIO := Color("a9b77b")
const PINK := Color("efcdbb")
const GOLD := Color("e0b65a")
const CHARCOAL := Color("4a4543")
const COPPER := Color("b8743a")
const ICE := Color("dce8ec")

static func display_name(id: String) -> String:
	var names := {
		"chocolate_chip": "Chocolate Chip",
		"jam": "Jam",
		"smores": "Smores",
		"caramel": "Caramel",
		"pistachio_rose": "Pistachio Rose",
	}
	return names.get(id, id.capitalize())

static func price(id: String) -> int:
	return int(PRICES.get(id, DEFAULT_PRICE))

static func order_total(items: Dictionary) -> int:
	var total := 0
	for id in items:
		total += int(items[id]) * price(id)
	return total

static func order_count(items: Dictionary) -> int:
	var total := 0
	for id in items:
		total += int(items[id])
	return total

static func order_text(items: Dictionary) -> String:
	var parts: Array = []
	for id in items:
		parts.append("%dx %s" % [int(items[id]), display_name(id)])
	return ", ".join(parts)

static func order_speech(items: Dictionary) -> String:
	var words := {1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six"}
	var parts: Array = []
	for id in items:
		var n := int(items[id])
		var name := display_name(id).to_lower()
		if n != 1:
			name += "s"
		parts.append("%s %s" % [words.get(n, str(n)), name])
	return " and ".join(parts)

static func _collect(n: Node, xf: Transform3D, boxes: Array) -> void:
	if n is MeshInstance3D:
		boxes.append(xf * (n as MeshInstance3D).get_aabb())
	for c in n.get_children():
		var cxf := xf
		if c is Node3D:
			cxf = xf * (c as Node3D).transform
		_collect(c, cxf, boxes)

static func aabb_of(root: Node) -> AABB:
	var boxes: Array = []
	_collect(root, Transform3D.IDENTITY, boxes)
	if boxes.is_empty():
		return AABB()
	var out: AABB = boxes[0]
	for i in range(1, boxes.size()):
		out = out.merge(boxes[i])
	return out

static func fit(src: Node3D, diameter: float) -> Node3D:
	var w := Node3D.new()
	w.add_child(src)
	var b := aabb_of(src)
	var d: float = max(b.size.x, b.size.z)
	if d <= 0.0001:
		d = 1.0
	src.position = Vector3(
		-(b.position.x + b.size.x * 0.5),
		-b.position.y,
		-(b.position.z + b.size.z * 0.5)
	)
	w.scale = Vector3.ONE * (diameter / d)
	return w

static func set_gi_dynamic(root: Node) -> void:
	for n in root.find_children("*", "MeshInstance3D", true, false):
		(n as MeshInstance3D).gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC

static func build_cookie(id: String) -> Node3D:
	var path: String = COOKIES.get(id, "")
	var src: Node3D
	if path == "" or not ResourceLoader.exists(path):
		push_warning("Cookie model missing for " + id + ", using placeholder")
		var mi := MeshInstance3D.new()
		var m := CylinderMesh.new()
		m.top_radius = 0.07
		m.bottom_radius = 0.07
		m.height = 0.02
		mi.mesh = m
		src = mi
	else:
		src = (load(path) as PackedScene).instantiate()
	var out := fit(src, COOKIE_DIAMETER)
	set_gi_dynamic(out)
	return out

static func raw_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.93, 0.96, 0.97, 0.16)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.9
	m.metallic = 0.0
	return m

static func set_overlay(root: Node, mat: Material) -> void:
	for n in root.find_children("*", "MeshInstance3D", true, false):
		(n as MeshInstance3D).material_overlay = mat
