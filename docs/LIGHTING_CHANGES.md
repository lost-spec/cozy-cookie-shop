# Lighting changes — Spec 04 (GL Compatibility, no-GI fallback)

Machine constraint: the Quadro K1000M cannot run Forward+/Vulkan (Vulkan 1.1.95
is too old; the editor crashes in `nvoglv64.dll`) and GL Compatibility cannot
create a local RenderingDevice, so **LightmapGI baking is impossible here**.
The project therefore uses Spec 04 **Phase C, Option C (no-GI fallback)** plus
Phases A, B, D, E and F. No `.lmbake` resources are used anymore.

## Phase A — Project settings (`project.godot`)

| Key | Old | New |
|---|---|---|
| `rendering/lights_and_shadows/directional_shadow/size` | default (4096) | **4096** (explicit) |
| `rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality` | 4 | 4 (Soft Very High) |
| `rendering/lights_and_shadows/positional_shadow/atlas_size` | default | **4096** |
| `rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality` | 4 | 4 |
| `rendering/anti_aliasing/quality/msaa_3d` | 4x (2) | **Off (0)** — FXAA is used instead; MSAA is too expensive on this GPU |
| `rendering/anti_aliasing/quality/screen_space_aa` | Off | **FXAA (1)** |
| `rendering/textures/default_filters/anisotropic_filtering_level` | 3 | 3 (8x) |
| `rendering/limits/opengl/max_lights_per_object` | 12 | **24** — the room now has 9 fills + 6 lamps + sun + oven |

## Phase B — Sun, sky, environment

### `Config.gd` — `LIGHT_PHASES`
All four phases rewritten with warmer sun, darker low-angle evening, proper
night sky, per-phase `ambient` multiplier, `fill` multiplier and `lamp`
multiplier. Values:

| | Day | Afternoon | Evening | Night |
|---|---|---|---|---|
| Sun color | `#FFE2B8` | `#FFD9A8` | `#FF9A5C` | `#8FA8E0` |
| Sun energy | 2.2 | 1.8 | 1.2 | 0.3 |
| Elevation / yaw | 28° / 25° | 22° / 0° | 8° / −18° | 38° / 40° |
| Shadow opacity | 0.85 | 0.85 | 0.9 | 0.9 |
| Exposure | 1.0 | 1.0 | 0.95 | 1.1 |
| Lamp × | 1.0 | 1.1 | 1.4 | 1.9 |
| Fill × | 0.75 | 0.8 | 1.0 | 1.25 |
| Ambient × | 1.0 | 1.0 | 0.85 | 0.55 |

Sky: top `#5D8FC7`, horizon `#D9C3A3`, ground horizon `#D9C3A3`, ground bottom
`#6B5A4A`, sky energy 0.85, ground energy 0.7, `sun_angle_max` 30, `sun_curve`
0.15. Fog colour follows the horizon; densities 0.0035 / 0.0038 / 0.0045 / 0.005.

### `Day.gd` — `_setup_sky()`, `_setup_environment()`, `_setup_sun()`
- Ambient: sky source, `sky_contribution` **0.7** (no-GI fallback), cool
  `ambient_light_color` `#C4D6EA`, energy 1.0 (scaled per phase).
- Tonemap: Filmic, white 6.0, exposure 1.0. No Linear.
- Glow: 0.5 intensity, 1.0 strength, 0.05 bloom, **Screen** blend, threshold 1.0.
- Sun: **Orthogonal** shadows (single cascade), max distance **30 m**,
  angular distance 0.6 (contact-hardening), blur 1.4, bias 0.04, normal bias 1.5.
- `_ready()` used to call `_set_lightmap_phase("Day")`; it now calls
  `apply_phase(current_phase)`. The whole `_set_lightmap_phase()` function and
  its call in `apply_phase()` were removed.

### `env_cookieshop.tres`
Default environment synced to the Day phase: new sky colours, ambient
contribution 0.7 / cool ambient colour, glow 0.5 / 1.0 / 0.05 / Screen, fog
`#D9C3A3` at 0.0035.

## Phase C — No-GI fallback (no LightmapGI, VoxelGI or SDFGI)

- Deleted all four `LightmapGI` nodes (`Lightmap_Day/Afternoon/Evening/Night`).
- Deleted `tools/set_bake_phase.gd` and `res://lightmaps/` (unused).
- Added `/Main/FillLights` with nine shadowless, low-energy OmniLight3Ds:
  `Fill_FloorBounce`, `Fill_Room`, `Fill_BackCounter`, `Fill_FrontCounter`,
  `Fill_CornerNW/NE/SW/SE`, `Fill_Window`. Warm except the corner/window fills,
  which are cool (`#C9D8EA` / `#BFD4F2`) for hue contrast. Energies 0.25–0.55,
  ranges 4.5–9 m, specular 0, no shadows. `Day.gd::_setup_lights()` caches their
  base energy and `apply_phase()` scales them with the phase `fill` multiplier.
- Fake contact AO: `Day.gd::_setup_contact_shadows()` adds a soft radial
  shadow quad (unshadowed, depth-write off, alpha ≈ 0.42) under each of the two
  seating tables at y = 0.055, just above the rug.

## Phase D — Interior lights

- **Fixed a real bug:** all six lamp SpotLight3Ds were rotated **+90° (aimed at
  the ceiling)**. Rotation.x is now **−90°** for all six; they light the room.
- Pendant spots: range 5.5 m, angle 1.15 rad (~66°), attenuation 1.2,
  base energy **1.6** (`main.tscn`), shadows **on** (0.04 bias, 1.5 normal bias,
  opacity 0.9).
- Track spots: range 4.5 m, angle 1.1 rad, base energy **0.9**, shadows off.
- `Day.gd` now caches each lamp's base energy (`lamp_base`) and scales it by the
  phase `lamp` multiplier instead of forcing one flat energy on every lamp.
- Emissive bulb material: emission energy 0.8 → **1.4**; `LIGHTBAR_Baking`
  0.8 → **1.2** (glow threshold is 1.0).
- Oven glow unchanged (real-time `#FF9A3C`, 0.8, range 2.2, no shadows).
- Window fill: `Fill_Window` cool omni near the front windows (0.5 base).

## Phase E — Reflections / materials

- `ShopReflectionProbe`: position `(0, 1.5, −1.5)`, size `(8.4, 3.2, 9.4)`
  (whole room), `interior = true`, `box_projection = true`,
  `update_mode = Once`, intensity 1.0.
- Window glass (`mat_window_glass_emissive.tres`): removed emission (the
  "flat grey-white sheet" cause), albedo `(0.78, 0.86, 0.95, 0.12)`, roughness
  0.3, specular 0.0, `cast_shadow = Off`. The sky and the exterior sidewalk now
  read through the glass; the east window still rolls off softly toward the sun.

## Phase F — Verification

Verified in the running game (Godot MCP):
- Day screen: sun patch on the floor/counter by the east window, warm pendant
  pools, cool window light, no pure-black surfaces.
- Evening: orange sun through the east window, lamp warmth stronger.
- Night: deep blue windows, warm readable interior, oven glow.
- Shadow acne/peter-panning checked at 4096 with orthogonal sun shadows: clean.
- Game runs with no parser/runtime errors (`project_run` reports `live`).

Not possible under GL Compatibility (documented deviations): SSAO, SSIL,
volumetric fog/god rays, VoxelGI, LightmapGI and SDFGI. The no-GI fallback is
the intended path for this renderer.
