# Godot Lighting / Shadows / Environment Overhaul

**Audience:** OpenCode (coding agent) working inside this Godot project.
**Goal:** Make the game look dramatically better: warm, cozy, stylized-but-polished interior lighting with soft, believable shadows, depth, contrast and a pleasant sky through the windows.

Read this whole file before touching anything. Work in the phases below, in order. Commit (or copy the project) before you start so changes can be reverted.

---

## 0. What the game looks like right now (diagnosis from screenshots)

The game is a first-person, warm-toned interior (a bakery/cafe: counter, ovens, shelves, round tables, chalkboard menu, pendant lamps, string lights, big windows). The problems visible in the screenshots:

1. **Flat, uniform lighting.** Everything is the same orange-brown wash. There is no light falloff, no light pools under the pendant lamps, no bounced light. This is what a scene looks like with only constant ambient light and no global illumination (GI).
2. **Large near-black surfaces.** Whole walls, a shelf unit and a back counter render almost pure black while their neighbours are lit. That is not "dark wood". It points to one or more of: black or very dark albedo, missing or inverted normals, unlit-by-GI surfaces with no ambient, wrong cull mode or back-faces, or missing UV2/material. **Investigate and fix; do not assume it is intentional.**
3. **No contact shadows / ambient occlusion.** Chairs, tables and counters look like they float. No darkening in corners, under tables, behind shelves.
4. **Blown-out, flat windows.** Windows show a pale grey-white nothing. No sky colour, no sun, no exposure control, no tonemapping curve to roll off the highlights.
5. **Lights do not read as lights.** Pendant lamps and string lights glow as meshes but do not visibly light their surroundings. Nothing blooms.
6. **Shadows are absent, harsh or low-res** (check this in-engine; see Phase 3).
7. **No colour grading / contrast.** The image is low contrast and muddy.

All of this is fixable with settings and a few nodes. No art changes are required, except fixing broken materials or meshes in item 2.

---

## 1. Discovery (do this first, report findings before changing things)

Inspect the project and answer these. Write the answers as a short list in your reply.

1. **Godot version.** Read `config/features` in `project.godot`. Features below marked *(4.4+)* need that version or later. Do not use APIs that do not exist in this version.
2. **Renderer.** Read `rendering/renderer/rendering_method` in `project.godot` (`forward_plus`, `mobile`, or `gl_compatibility`).
   - **Forward+** supports everything in this document.
   - **Mobile** has no SDFGI, VoxelGI-realtime features are limited, no SSAO/SSIL. Use LightmapGI and fake fills.
   - **Compatibility** has no SDFGI, VoxelGI, SSAO, SSIL, SSR or volumetric fog. If the game is on Compatibility and does not need to run on weak hardware or the web, **recommend switching to Forward+**, because it is the single biggest quality jump. Ask the user before switching. If they refuse, use the "No-GI fallback" in Phase 5.
3. **Scene inventory.** Find the main scene(s). List every `WorldEnvironment`, `DirectionalLight3D`, `OmniLight3D`, `SpotLight3D`, `VoxelGI`, `LightmapGI`, `ReflectionProbe`, `CameraAttributes*` resource, and any scripts that create or change lights at runtime.
4. **Is the interior sealed?** Are the walls real thick geometry, or paper-thin planes / single quads? (Matters for VoxelGI/SDFGI light leaking.)
5. **Black surfaces.** Find the meshes/materials that render black (the dark walls, the dark shelving, the back counter). For each, report its material: `albedo_color`, `albedo_texture`, `shading_mode`, `cull_mode`, `emission`, `metallic`/`roughness`, whether it is a `StandardMaterial3D` or `ShaderMaterial`. Common culprits:
   - `albedo_color` near black.
   - `metallic = 1.0` with no reflection source (a fully metallic surface with nothing to reflect is black). Fix: lower metallic, and add a `ReflectionProbe` / sky reflections (Phase 4).
   - Normals flipped (mesh imported from Blender with inverted faces). Fix in the mesh, or set `cull_mode = Disabled` temporarily to confirm.
   - Normal map applied with wrong green channel convention or strength.
   - A shader that outputs black because an expected texture/uniform is unset.
6. **Imported meshes and UV2.** For any mesh that will be lightmapped, check import setting `Meshes > Light Baking` and `Generate Lightmap UV2`. Only needed if you choose LightmapGI.
7. **Do the windows have glass meshes?** If glass is an opaque mesh it blocks the sun. Windows must let light in: either a hole in the wall, or a transparent material that does not cast shadows (`GeometryInstance3D.cast_shadow = Off` on the glass mesh).

---

## 2. Target look (art direction)

- Warm, cozy, slightly stylized interior. Think: late-morning sun through windows, warm pendant lamps, soft shadows, gentle bloom on lamps, cool-ish blue shadows against warm light for colour contrast.
- **Do not go photorealistic.** Use Filmic (or AgX if available) tonemapping, not harsh ACES.
- Keep the existing orange/brown palette, but add **contrast** (dark corners, bright light pools) and **hue variation** (cool sky through windows, warm lamps, slightly cool ambient fill).
- Time of day in the UI says **9:00 AM**. The sun should be low-ish and golden, coming through the windows. If the game has a day/night cycle, make every value here a function of time of day. Otherwise, hardcode the morning look.

---

## 3. Phase A: Project Settings (the quality floor)

Edit `project.godot` (or via the editor's Project Settings). Verify each key exists in this Godot version before setting it.

### Shadows

| Setting | Value | Why |
|---|---|---|
| `rendering/lights_and_shadows/directional_shadow/size` | `4096` (or `8192` if the user's GPU is decent) | Resolution of the sun shadow map. Default shadows look blocky. |
| `rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality` | `Soft High` (or `Soft Very High`) | Smooths shadow edges. |
| `rendering/lights_and_shadows/positional_shadow/atlas_size` | `4096` | Shared atlas for omni/spot shadows. Many shadowed lights share it, so keep shadow-casting lights few. |
| `rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality` | `Soft High` | Same, for lamps. |

Note: do not blindly crank atlas size to 16384; some GPUs fail above 4096/8192. Reduce the number of shadow-casting lights instead.

### Anti-aliasing (jagged edges are a big part of "ugly")

| Setting | Value |
|---|---|
| `rendering/anti_aliasing/quality/msaa_3d` | `4x` (Forward+/Mobile) |
| `rendering/anti_aliasing/quality/screen_space_aa` | `FXAA` (cheap, fills in shader aliasing) |
| `rendering/anti_aliasing/quality/use_taa` | optional; `true` smooths shadow dithering but can ghost on moving objects. Try it, judge visually. |

### Other

- `rendering/textures/default_filters/anisotropic_filtering_level` = `8x` or `16x` (floors and tables at grazing angles look muddy without it).
- `rendering/textures/canvas_textures/default_texture_filter`: leave alone (2D).
- Make sure `rendering/viewport/hdr_2d` is not changed; irrelevant to 3D.
- Add the **Light Baking** denoiser only if LightmapGI is used (Phase 5, option B).

---

## 4. Phase B: Sun, sky and WorldEnvironment

If there is no `WorldEnvironment` in the main scene, add one. If there is more than one active, remove duplicates (only one is used per viewport).

### 4.1 Sky

- `Environment.background_mode = Sky`
- `Environment.sky = Sky` with `ProceduralSkyMaterial` (or `PanoramaSkyMaterial` if the user has an HDRI; an HDRI gives much better reflections and ambient light).
- `ProceduralSkyMaterial` starting values for a morning sky:
  - `sky_top_color` ≈ `#5d8fc7` (soft blue)
  - `sky_horizon_color` ≈ `#d9c3a3` (warm haze)
  - `ground_horizon_color` ≈ `#d9c3a3`, `ground_bottom_color` ≈ `#6b5a4a`
  - `sun_angle_max` ≈ `30`, `sun_curve` ≈ `0.15`
  - `energy_multiplier` ≈ `0.75` to `1.0`

### 4.2 Ambient light and reflections

- `ambient_light_source = Sky` (not Disabled, not a flat colour). This makes the ambient follow the sky and prevents the dead-flat look.
- `ambient_light_sky_contribution` ≈ `0.3` to `0.6` indoors. (Lower than outdoors, because GI from Phase C does the heavy lifting. If GI is not available, go higher, ~`0.7`, and add fill lights.)
- `ambient_light_energy` ≈ `0.6` to `1.0`.
- `reflected_light_source = Sky`.

### 4.3 Tonemapping (fixes blown-out windows and muddy contrast)

- `tonemap_mode = Filmic` (stylized, soft highlight roll-off). Try `AgX` *(4.4+)* if hues shift too much. `ACES` is more contrasty and desaturates highlights; use it only if the user wants a more realistic look.
- `tonemap_exposure` ≈ `1.0` to `1.2` as a start.
- `tonemap_white` ≈ `6.0` to `16.0` for Filmic/Reinhard. (A white of 1.0 with Reinhard equals Linear and clips highlights.)
- **Linear tonemapping clips bright values and blows things out. Never leave it on Linear.**

### 4.4 Auto-exposure or manual exposure for the windows

Interiors with bright windows are the hardest case. Add a `CameraAttributesPractical` resource to the `WorldEnvironment` (or the `Camera3D`):
- Option 1 (simple): leave auto-exposure off, lower `tonemap_exposure` slightly and let Filmic roll off the windows.
- Option 2 (nicer): `auto_exposure_enabled = true`, `auto_exposure_min_sensitivity`/`max_sensitivity` set to a narrow range, `auto_exposure_speed` ≈ `1.5` so stepping outside/inside adapts gently.

### 4.5 Post effects (subtle! do not overdo)

- **Glow/Bloom:** `glow_enabled = true`, `glow_intensity` ≈ `0.4`, `glow_strength` ≈ `0.9`, `glow_bloom` ≈ `0.05`, `glow_blend_mode = Softlight` (or Screen). `glow_hdr_threshold` ≈ `1.0` so only bright things (lamps, windows) bloom. Lamp meshes need an emissive material with `emission_energy_multiplier` > 1 to bloom.
- **SSAO:** `ssao_enabled = true`, `ssao_radius` ≈ `1.0` to `2.0`, `ssao_intensity` ≈ `2.0`, `ssao_power` ≈ `1.5`, `ssao_detail` ≈ `0.5`, `ssao_light_affect` ≈ `0.2` to `0.5` (so AO also darkens areas under direct light, not only ambient), `ssao_ao_channel_affect` ≈ `0.5`.
- **SSIL** (screen-space indirect light): `ssil_enabled = true`, `ssil_radius` ≈ `4`, `ssil_intensity` ≈ `1.0`. Cheap small-scale bounce light; works best on top of a GI method from Phase C.
- **Colour adjustments:** `adjustment_enabled = true`, `adjustment_contrast` ≈ `1.05` to `1.15`, `adjustment_saturation` ≈ `1.05` to `1.15`, `adjustment_brightness` = `1.0`. Add a colour-correction LUT only if the user asks.
- **Volumetric fog (god rays through windows):** `volumetric_fog_enabled = true`, `volumetric_fog_density` ≈ `0.01` to `0.03`, `volumetric_fog_albedo` warm white, `volumetric_fog_gi_inject` ≈ `1.0`. The sun's `light_volumetric_fog_energy` ≈ `1.0` to `2.0`. This makes sunbeams visible through windows. Keep density low or the room looks smoky. Skip in Compatibility.
- **Depth fog (optional):** very light `fog_enabled` for depth separation. Colour matched to the horizon.

### 4.6 The sun (`DirectionalLight3D`)

- Exactly **one** shadow-casting directional light (extra ones divide shadow resolution).
- `light_color` ≈ warm `#ffe2b8` for morning.
- `light_energy` ≈ `1.2` to `2.5`. Raise until the floor patch under the window is clearly brighter than the rest of the room.
- Rotation: sun must reach inside through the windows. Typical: `rotation_degrees.x` ≈ `-30` to `-50`, and a Y rotation that points into the windows. Verify by looking for sun patches on the floor.
- `shadow_enabled = true`
- `directional_shadow_mode`:
  - **Small indoor scene:** `Orthogonal` (one cascade; the highest resolution per area; also works best with the soft filter settings) **and** `directional_shadow_max_distance` as small as possible, e.g. `25` to `40` (cover the room only, not the horizon). A small max distance is the #1 shadow-quality trick: the smaller the covered area, the sharper the shadows.
  - **Big outdoor areas in view:** `PSSM 2 Splits` or `4 Splits`, tune `directional_shadow_split_1` etc.
- `shadow_bias` ≈ `0.03` to `0.1`, `shadow_normal_bias` ≈ `1.0` to `2.0`. Raise if you see acne (stripy self-shadowing); lower if shadows detach from objects (peter-panning). Tune per scene.
- `shadow_blur` ≈ `1.0` to `1.5`.
- `light_angular_distance` ≈ `0.5` to `2.0`. This gives contact-hardening soft shadows (sharp near the object, blurry far away). Too high produces dithering; use TAA or lower the value if it looks noisy.
- `directional_shadow_blend_splits = true` if using PSSM.
- `light_volumetric_fog_energy` as above, `light_indirect_energy` = `1.0`.
- **Light leaking:** if sun leaks through walls, the walls are too thin. Give walls real thickness (a few cm to 20 cm) or add a thick hidden box behind them. Check that `cast_shadow` on wall meshes is `On` (not `Off`/`Double-sided` mishaps).

---

## 5. Phase C: Global Illumination (the biggest quality jump for interiors)

GI is what produces bounced light: the warm glow from the floor lighting the walls, the sun patch brightening the room, soft dark corners. Pick **one** main method.

### Which one

| Method | Pick it when | Notes |
|---|---|---|
| **VoxelGI** (recommended default for this game) | Small/medium interior, Forward+, objects may move | Baked in the editor. Good indirect light + reflections. Beware light leaking through thin walls. |
| **LightmapGI** | Static scene, best quality, or Mobile renderer | Highest quality, cheapest at runtime. Needs UV2 on meshes and a bake. Moving objects use light probes. |
| **SDFGI** | Large open worlds | Real-time, no bake, but cascade shifts and leaks; usually overkill for one room. |

Do **not** enable multiple GI methods at the same time.

### Option A: VoxelGI (do this by default)

1. Add a `VoxelGI` node covering the **interior only**. Fit `size` (this is the box extents) tightly to the room. Do not make it bigger than needed; precision and leaking get worse.
2. `subdiv`: start at `128` (higher = more detail but slower and more memory; 256 only if the room is small).
3. Make the static meshes (walls, floor, ceiling, counters, shelves, big furniture) contribute: `GeometryInstance3D.gi_mode = Static`. Dynamic things (customers, carried items, anything that moves) should be `Dynamic`/`Disabled` so they do not bake into the GI.
4. **Bake** it from the editor (select VoxelGI, click *Bake VoxelGI*). Save the resulting `VoxelGIData` resource (`.res`) into the project. If the agent cannot click the editor button, write an `@tool` helper script or a `--headless --script` run that calls `bake()`, and tell the user clearly if the bake must be done manually.
5. Tuning: `energy` ≈ `1.0`, `bias` ≈ `1.5`, `normal_bias` ≈ `0.0` to `1.0`, `propagation` ≈ `0.5` to `0.7`, `interior = true` (tells it not to sample the sky from outside; makes interiors look cleaner), `use_two_bounces = true` for nicer bounce.
6. Leaks (bright streaks through walls): thicken walls, shrink the VoxelGI to the room, split into one VoxelGI per room, or adjust `bias`/`normal_bias`.
7. Each time static geometry or lights change, re-bake.

### Option B: LightmapGI

1. Ensure every static mesh has UV2. For imported scenes set `Generate Lightmap UV2` in the mesh import settings and reimport.
2. Add a `LightmapGI` node. `quality = High`, `bounces = 3`, `denoiser` = OIDN (or JNLM). In the editor settings, enable the denoiser.
3. Set `bake_mode` on lights: use `Static` for lights that never change (bakes their direct + indirect), `Dynamic` for lights that must move or toggle, `Disabled` to skip.
4. Static meshes `gi_mode = Static`. Add a `LightmapProbe` or two for dynamic objects (customers, held items).
5. Bake. Check for seams, bleeding, and splotches; increase texel density on bad meshes.

### Option C: No-GI fallback (Compatibility renderer or no budget)

- Raise ambient (`ambient_light_sky_contribution` ~0.7).
- Add shadowless, low-energy `OmniLight3D` fill lights in corners and under counters/tables (`light_energy` 0.2 to 0.5, large `omni_range`, no shadows, warm colour). Keep to ~20 to 30 fill lights max.
- Add a very soft upward-facing fill near the floor to fake floor bounce (a dim, warm omni just above the floor in the middle of the room).
- Fake AO with darker baked vertex colours or contact-shadow decals (`Decal` nodes with a soft dark gradient) under tables and along wall bases.

---

## 6. Phase D: Interior lights (pendant lamps, string lights, oven glow)

- **Pendant lamps:** each gets a `SpotLight3D` (pointing down) or `OmniLight3D` at the bulb. Warm colour (`#ffb866`), `light_energy` ≈ `1.5` to `4` (tune visually), `spot_angle` ≈ `55` to `75`, `spot_range` ≈ `6` to `10`, `spot_attenuation` ≈ `1.0` to `2.0`. This creates visible light pools on tables. Shadows on only the 2 to 4 most important lamps, off on the rest.
- **String lights:** a tiny `OmniLight3D` per few bulbs, or a single `OmniLight3D` per cluster, no shadows, low energy. The bulb meshes need an emissive material (emission energy ~3 to 6) so glow/bloom picks them up.
- **Oven:** its opening glows orange in the screenshot but lights nothing. Add a flickering `OmniLight3D` (`#ff8a3d`, energy ~1 to 3, range ~3) just in front of the oven door, with a subtle noise-driven flicker script (energy jitter ±10% via `FastNoiseLite`). Shadow on if the budget allows.
- **Window fill:** if the sun alone does not light the room enough, add a large cool-white `SpotLight3D` or `OmniLight3D` (no shadows, low energy) near each window as "skylight fill". With GI baked, this is often unnecessary.
- **Budgets (Forward+):** ~1 shadowed directional, ~3 to 5 shadowed omni/spot, 20 to 30 unshadowed omni, 15 to 20 unshadowed spot. Shadowed positional lights share one atlas, so more of them means blurrier shadows for all.
- Set `distance_fade_enabled` on lights that are far from the player in big scenes.
- Re-bake GI after changing static lights (if their `bake_mode`/GI participation applies).

---

## 7. Phase E: Reflections and materials

- Add a `ReflectionProbe` covering the room (`size` to fit the room, `interior = true` so it does not render the outside sky into the room; `update_mode = Once`; `intensity` ~1; `box_projection = true`). This stops shiny surfaces (counters, metal oven hood, tabletops) from looking black or flat.
- Material pass on the interior:
  - Wood/counters: `roughness` 0.5 to 0.85, `metallic` 0.0.
  - Metal (oven hood): `metallic` 0.8 to 1.0 only with a ReflectionProbe/sky present; `roughness` 0.3 to 0.5.
  - Never leave large surfaces at pure black albedo. Min albedo around `#1a1410` for "dark wood", never `#000000`.
  - Textures: set `texture_filter` to a mipmapped + anisotropic option.
  - Enable `Specular` normally; avoid `shading_mode = Unshaded` on anything meant to be lit.
- Fix the black walls/shelves found in Discovery step 5 here.
- Windows: make sure glass is transparent, `cast_shadow = Off`, and has a subtle `Roughness 0.0`, `Metallic 0.0`, `Alpha 0.1 to 0.3` material. Outside the window, make sure there is something to see: the sky from the WorldEnvironment, plus optionally a simple backdrop plane (street, trees) with an emissive/unshaded texture so it is not a void.

---

## 8. Phase F: Verification (do not skip)

Run the game (`godot --path . ` with the project's main scene, not `--headless`, since headless does not render) or open the scene in the editor and take screenshots from the same viewpoints as the originals (the counter-facing-ovens view, the seating-area-facing-display-case view, the windows-and-register view). Compare before/after.

Checklist (every box should be true):

- [ ] No large surface is pure black. Dark corners are dark brown, not black.
- [ ] A visible sun patch (bright, warm, soft-edged) lands on the floor or tables through the windows.
- [ ] Shadows have soft edges, no stair-stepping, no striping (acne), no floating gaps between objects and their shadows.
- [ ] Contact shadows/AO under tables, chairs, along counters and in corners.
- [ ] Pendant lamps visibly pool warm light on tables.
- [ ] Windows show sky colour with a soft highlight roll-off, not a flat grey-white sheet.
- [ ] Lamps and bright windows have a subtle glow, nothing is glowing like a nuclear reactor.
- [ ] Colours: warm lights, slightly cooler shadows, overall contrast better than before.
- [ ] No light leaking through walls (bright streaks near wall seams).
- [ ] Frame rate is still acceptable on the user's machine. If not, reduce in this order: SSIL off, volumetric fog density/quality down, VoxelGI `subdiv` down, shadow-casting omni/spot count down, shadow size down.

---

## 9. Rules for you, the agent

1. **Make changes in the scene/resources/project files, not by hacking one-off runtime scripts**, unless a value genuinely has to change at runtime (time of day, flicker). Prefer saved `Environment`, `Sky`, `CameraAttributes` resources and node properties so the user can tweak them in the editor.
2. **Work phase by phase.** After each phase, tell the user what you changed (file, node, property, old value to new value) and what to look at.
3. **Check property names against the installed Godot version** before editing `.tscn`/`.tres` files by hand. Prefer editing in a way that the editor will accept (open and re-save if possible). A wrong property name in a `.tscn` is silently dropped.
4. **Do not delete existing lights or nodes** without saying so. Disable first, ask if unsure.
5. **GI baking may require the editor.** If you cannot bake, set everything else up, leave clear instructions for the one-click bake, and say so up front.
6. **Be honest about uncertainty.** If you could not see the result (no way to render screenshots), say that visuals are unverified and list what the user should check.
7. **Do not over-process the image.** Bloom, SSAO, fog and contrast should be felt, not noticed. If in doubt, halve the value.
8. **Keep a changelog** at `docs/LIGHTING_CHANGES.md`: every property changed, old to new, and why.
9. **Ask the user** (once, up front) about: target hardware / platforms (PC only? web? mobile?), whether a day/night cycle exists or is planned, and whether switching renderer to Forward+ is acceptable.

---

## 10. Quick reference: the 8 highest-impact changes (if you only do a few)

1. Use **Forward+** (not Compatibility).
2. Add **VoxelGI** (interior, `interior = true`) and **bake** it.
3. `WorldEnvironment`: ambient from **Sky**, **Filmic** tonemap, **SSAO** + **glow** on.
4. One good **DirectionalLight3D** with soft shadows, small `directional_shadow_max_distance`, Orthogonal mode, bias tuned.
5. Directional shadow **size 4096+**, soft filter **High**, **MSAA 4x + FXAA**.
6. Real **lights at the pendant lamps and oven** (warm, with a few shadows).
7. **Fix black materials** (albedo, metallic, normals/back-faces).
8. Add a **ReflectionProbe** for the interior.

---

## Sources consulted

- Godot docs: Introduction to global illumination (VoxelGI, SDFGI, LightmapGI, SSIL comparison and performance), Lights and Shadows (shadow bias, clustering limits, shared directional shadow atlas), `Environment` class reference (tonemap modes, glow, SSAO, SSIL, adjustments).
- Godot forum threads on directional shadow quality (max distance, shadow size, orthogonal vs PSSM, soft filter, TAA), pixelated omni shadows (shared atlas), and a "realistic lighting in Godot 4" tutorial (sky contribution, SSAO/SSIL settings).
- Community Godot 3D lighting guidance (light budgets, thin-wall leaking with VoxelGI, denoising lightmaps).

Exact property names and defaults can differ between Godot 4.x releases. Verify against the installed version.
