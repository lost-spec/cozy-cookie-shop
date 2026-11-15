Respond with tool calls only until finished. Do not write out reasoning or plans.

# Spec: Export gacha_shop.blend to .glb, import it into Godot, and light it in real time to look as close as possible to its Blender look (Compatibility renderer)

Context: a cozy first-person cookie game in Godot, **Compatibility renderer** (no SSAO, SSIL, SSR, SDFGI, VoxelGI, volumetric fog, no baked lightmaps). The gacha market shop is modeled in `gacha_shop.blend` (collection `Shop_Room`). Step 1 is exporting it as a .glb. Then import it into Godot as its own scene and light it with real-time lights only. There are no NPCs yet. This spec is the source of truth; do not look for or analyze any reference image. Don't ask questions; if unsure, pick the simplest option.

## Efficiency rules (strict)
- Think briefly. No long planning, no alternatives. Patch existing files; don't rewrite them.
- Don't change the shop's geometry. Only export settings, import settings, material overrides and lights.
- No baking, no LightmapGI, no audio, no gameplay, no NPCs. Final reply: 8 lines max.

## Order of work (strict)
1. **Part A (export) comes first and blocks everything else.** Do not start Part B until `gacha_shop.glb` exists on disk, is larger than 0 bytes and imports into Godot without errors.
2. Part A needs the Blender MCP. If you don't have it, stop and reply with the manual export settings from Part A so the user can export by hand.
3. Parts B to E use the Godot MCP.

## What the shop looks like (the look to match)
A dark, moody neon-lounge interior. Almost no ambient light: the room is near black with saturated colored accents, and light arrives in pools.
- **Gacha counter area (back wall):** seven padded crimson wall panels (#8E2F42), a large round gold vault-door disc in front of them, a raised red-carpet platform with five tall dark pedestal machines with gold arc handles and pale glass tops, gold rope posts with dark ropes, and a dark counter with gold trim in front.
- **Green counter and booth (foreground left):** teal-green counter, mint-green chair backs, a mint-white glowing rectangular window outline, and a cash register block.
- **Stage (right):** a large dark platform with magenta edge neon, a giant gacha machine (glass globe full of colorful capsules on a dark purple base) under a tall lavender neon arch (`stage_ring`), and a dark purple round pedestal table with a glowing pale ring on top (the pack-opening table).
- **Ceiling:** two black track-light rails with black spot fixtures with pink lenses. Strings of tiny warm-white bulbs droop along the walls.
- **Neon strips:** long straight emissive strips along the walls and floor edges: mint-cyan (#A8F5E6) on the back wall, pink-lavender (#F2B8D8) on the left wall and along the floor edges.
- **Floor:** black and charcoal checker tiles with a subtle glossy reflection. In the seating area, a soft round spotlight pool lights a lighter gray checker patch with three crimson velvet booth sofas (gold armrests) and round gold pedestal tables, with small soft shadows under the tables.
- **Bar:** a back wall with three shelves of mint-green jars and bottles, each shelf lit by a mint strip underneath, a crimson wall behind, a green bar counter with a mint glowing panel, and round red-seat gold stools.
- **Lighting character:** deep dark base, glowing neon, warm brass highlights, soft elliptical spotlight pools with smooth falloff, soft shadows, a bloom on the neon. The grain in the Blender viewport is render noise, not part of the look.

## Part A: export from Blender (Blender MCP), do this first
- Open `gacha_shop.blend`. Keep the viewport in **Solid** mode, never Rendered (the Rendered view crashed the GPU driver with a timeout). If any baking is needed, use the Cycles **CPU** device at 1024 px.
- Audit every material once. Find the ones with procedural nodes (Checker, Noise, Voronoi, Wave, Gradient, Color Ramp) feeding Base Color, because glTF can't export procedural nodes (the checker floor is the likely one). For each, bake the Base Color to an image texture (diffuse color only, 1024 or 2048 px, CPU) and relink it as an Image Texture. If that fails, leave a flat Base Color and list the material in the final reply.
- Export the whole `Shop_Room` collection (all meshes, empties and lights, no cameras) as **`gacha_shop.glb`**. Settings: format GLB, +Y up, apply modifiers, export materials, export lights (punctual), keep the emission export on (default), no cameras, no animations, texcoords and normals on. If a parameter name isn't recognized by this Blender version, use the closest equivalent and continue.
- Destination: if you can find the Godot project (a folder with `project.godot`, near the .blend), export to `res://assets/gacha_shop/gacha_shop.glb` there. Otherwise export next to the .blend and print the absolute path so the user can copy it into the project.
- Print the file path and size, then continue with Part B only if the file exists.

## Part B: import into Godot
- Create `res://scenes/GachaShop.tscn`: root `Node3D` `GachaShop` with children `Shop` (instance of the glb), `WorldEnvironment`, `Lights` (Node3D), `Player` (instance of the existing first-person player scene, or a simple WASD + mouse look controller if none exists) and `PlayerStart` (`Marker3D` at the entrance, facing into the room; if no door is found, on the floor near the front edge).
- Collision: an import post-script (or a one-time editor script) adds static trimesh collision to every mesh whose longest side is at least 0.3 m, and skips names containing `bulb`, `string`, `neon`, `led`, `strip`, `capsule`, `light`, `glow`, `rope`. Floor, walls, counters, platforms, sofas and tables must block the player.
- Print the imported scene tree once (names only) and use the real node names for everything below; don't assume names.
- Don't change the project's main scene. Add `Config.DEBUG_GACHA = false`; when true, the game loads `GachaShop.tscn` at startup instead of the menu. Use the MCP's run-scene tool if it has one; otherwise use the flag, and set it back to false at the end.

## Part C: how the look is achieved in Compatibility (apply all of it)
Compatibility has no global illumination, so each part of the look gets a real-time technique:

| Part of the look | Technique in Compatibility |
|---|---|
| Near-black moody base | Dark background color, low colored ambient, never pure black |
| Glowing neon | Emissive materials plus Environment glow |
| Neon color tinting nearby walls and floor (normally GI) | Weak colored `OmniLight3D`s along each strip, no shadows |
| Soft round spotlight pools | `SpotLight3D` with a soft angle falloff and soft shadows |
| Soft dark shadows | Soft shadow filter on a few shadow-casting spots |
| Lifted shadow areas (normally bounced light) | A few very soft plum-colored fill omnis |
| Glossy floor, brass highlights, glass reflections | Low roughness, specular from the lights, one `ReflectionProbe` |
| Velvet sofas and panels | High roughness plus a rim sheen |
| Depth | Light dark-violet depth fog |

### C1. Project settings
- `rendering/limits/opengl/max_lights_per_object` = 16, `max_renderable_lights` = 64.
- Positional shadow atlas size 4096, positional soft shadow filter quality Soft High.
- MSAA 3D = 4x, anisotropic filtering = 8x.
- Default clear color #050407. If Project Settings has a 3D HDR option for the Compatibility renderer, enable it; otherwise keep all glow thresholds below 1.0.

### C2. Environment (unique resource on `WorldEnvironment`)
- Background: Custom Color #050407. No sky.
- Ambient light: source Color, color #231A2E, energy 0.5. (Raise energy to 0.7 if the darkest furniture is not readable, never below 0.3.)
- Reflected light source: Background.
- Tonemap: Filmic, exposure 1.0, white 4.0.
- Adjustments on: brightness 1.0, contrast 1.12, saturation 1.15.
- Glow on: levels 3, 4 and 5 enabled (the rest 0), intensity 0.8, strength 1.0, mix 0.05, bloom 0.1, blend mode Screen, HDR threshold 0.8. If the neon doesn't bloom in the screenshots, lower the threshold step by step down to 0.6.
- Fog on: light color #120C18, density 0.006, sky affect 0, aerial perspective 0.

### C3. Lights (all under `Lights`, in groups; cap total positional lights at 24)
- Use the lights exported from Blender only for positions, rotations and colors, because the glTF energy scale doesn't match Godot. Retune them to the values below. Delete extras beyond the cap. If Blender exported none, create them at the track fixtures.
- **Key spots** (group `key_spot`): `SpotLight3D`, color #FFE9D6, energy 8, range 9, spot angle 32, spot attenuation 1.0, **spot angle attenuation 1.5** (soft edge), `light_specular` 0.6, aimed at the gacha counter, the stage, the pack table and the seating area.
- **Seating pool spot:** one wider spot above the sofas: color #FFF4EA, energy 6, angle 38, angle attenuation 1.8, so it makes the soft round pool on the checker floor.
- **Shadows:** only 3 or 4 lights cast shadows (the seating spot, the stage spot, the counter spot, optionally the pack table spot): shadow on, bias 0.03, normal bias 1.0, blur 1.2, shadow opacity 0.85. Everything else has shadows off.
- **Arch spot:** a pink-white spot (#F5D0E8, energy 5, angle 28) from the neon arch pointing down at the giant gacha machine.
- **Neon fills** (group `neon_fill`, no shadows): for every emissive strip longer than 1.5 m, place `OmniLight3D`s along it every 3 m, 0.3 m out from the strip into the room. Color = the strip's color: mint #7FF0D8, pink #F5A8D0, lavender #D9B4F0 (arch). Energy 0.5 (arch 0.8), range 3.2, `light_specular` 0.3.
- **Bounce fills** (group `bounce_fill`, no shadows): 4 very soft omnis near the ceiling, one per zone (counter, stage, seating, bar): color #5A3A5E, energy 0.2, range 7, `light_specular` 0.
- **String lights** (group `string_fill`): the bulb meshes are emissive warm white (#FFE2B0, emission energy 2.0), no light per bulb. Add 4 weak warm omnis (#FFD9A0, energy 0.25, range 2) along the strings.

### C4. Materials (set by script, matched by keyword in material or mesh names, print what you changed)
- **Neon and LED strips, glowing panels, lamp shades:** emission on, emission color = base color, `emission_energy_multiplier` 2.5, cast shadow off.
- **Floor tiles:** roughness 0.35, metallic specular 0.7.
- **Gold and brass:** metallic 0.7, roughness 0.3.
- **Velvet (sofas, wall panels, stool seats, carpet):** roughness 0.95, rim enabled (rim 0.3, rim tint 0.5).
- **Wood and dark trim:** roughness 0.6.
- **Glass (capsule machines, pedestal tops, display panes):** alpha transparency, alpha 0.15, roughness 0.05, cast shadow off, so it isn't blown out.
- **Capsules, jars, bottles:** roughness 0.4.
- Cast shadow off for string bulbs, neon strips, ropes and glass.

### C5. Reflections
- One `ReflectionProbe` covering the room: interior on, box projection on, intensity 0.8, update mode Once, ambient mode Environment. Trigger its update once after all lights and materials are in place.

## Part D: verify and tune
- Run through the MCP and read the errors. Take screenshots from 5 fixed spots: the entrance looking in, the gacha counter, the stage and pack table, the seating area, the bar. Max 8 screenshots in total (5 plus up to 3 for fixes). Always stop the running project at the end.
- Check against the look above: near-black base with readable shapes, glowing neon with a soft bloom, pink and mint tints on nearby surfaces, soft elliptical spotlight pools, soft shadows, warm brass highlights, glossy floor reflections, crimson panels still red (not brown), nothing clipped to pure white, no pure-black silhouettes. Fix only what the screenshots show (light energies, glow threshold, ambient energy, exposure).
- If glow shows no bloom at all even at threshold 0.6, add soft additive halo billboards (radial `GradientTexture2D`, unshaded, alpha at most 0.35) at the neon arch, the bulbs and the longest strips as a fallback, and mention it in the final reply.
- Set `Config.DEBUG_GACHA` back to false and stop the project.

## Final reply
Max 8 lines: the .glb path and size, the scene path, any material left flat (not baked), anything that still doesn't match the look, and any fallback used.

Stop after that. Don't polish or add anything.
