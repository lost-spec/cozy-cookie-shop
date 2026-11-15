# Cozy Cookie Shop — Game Context

## What the game is

A first-person 3D cozy cookie-shop game built in **Godot 4.7.2** (GL Compatibility,
Jolt physics). The player runs a small bakery: take a customer's order, pull frozen
dough from the freezer, bake the cookies, bag and seal them, hand the bag over for
money, then serve the next customer. One day = **four customers**, one per time of
day (Day → Afternoon → Evening → Night).

- Project: `E:\coookie seller\game\`
- Main scene: `res://main.tscn` (root `/Main`)
- Working directory for this doc: `E:\coookie seller\game\`
- Blender source files: `E:\coookie seller\blend_sources\`
- Specs/notes: `phase_1.md`, `lightning.md`, `resize.md`, `remodel.md`,
  `spec_2.md`, `fixes.md`, `cookie_bag.md`, `customers.md`, `customer_2.md`

## Current status

- Core order loop: **complete and verified end-to-end** (menu → freezer → raw
  cookies → tray → oven → baked → bag → seal → pick up → hand over → pay → next
  order). Must keep working unchanged.
- Lighting overhaul (Spec 04): **complete** as a dynamic, no-GI pass — sun, sky
  ambient, nine fill lights, emissives, glow, halos, ReflectionProbe, fake contact
  AO. Details in `docs/LIGHTING_CHANGES.md`.
- **Lightmap baking is impossible on this machine**: Forward+/Vulkan crashes
  (Vulkan 1.1.95 too old, `nvoglv64.dll`), and GL Compatibility cannot create a
  local RenderingDevice. No `LightmapGI` nodes or `.lmbake` files remain.
- `Config.DEBUG_PHASE = -1` (normal day flow).

## How to run / test

- Open `E:\coookie seller\game\project.godot` in Godot 4.7.2 and press **F5**.
  Editor binary:
  `C:\Users\ABDULLAH\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`
- Or drive it through the Godot MCP (`godot-ai`):
  - `project_run` / `project_manage(op="stop")` to (re)start after edits
  - `editor_manage(op="game_eval")` to inspect and drive the live game
  - `editor_screenshot` to see the game
  - `logs_read` for parser/runtime errors
- `UI._debug_start()` skips the title menu and starts Day 1 gameplay — useful for
  automated visual checks.

## Controls

| Input | Action |
|---|---|
| W / A / S / D or arrow keys | Move |
| Mouse | Look (captured while playing) |
| Space | Jump |
| E | Interact / pick up / use station |
| Q | Drop held item |

## Core gameplay loop

1. **Customer arrives** and walks to the counter (`Markers/CustomerSpot`), then
   speaks their order. The order timer starts: **50 s** (`Config.ORDER_TIME`).
2. **Freezer**: press E to take raw cookie dough. The tray/oven only accept the
   cookies the current order asks for; the station checks counts and types.
3. **Tray → oven**: put the raw cookies on the tray, slide the tray into the oven,
   and bake (`Config.BAKE_TIME = 6 s`) with an on-screen progress ring. Take the
   tray back out when done.
4. **Bag**: move the baked cookies into the paper bag, then **seal** it. Sealing
   validates that the bag matches the order (count + cookie types).
5. **Hand over**: pick up the sealed bag and press E on the customer. Correct bag →
   payment (`DEFAULT_PRICE = 4` per cookie, `PRICES` is empty) and a success line.
   Wrong bag → the customer rejects it and the order continues until the timer runs
   out.
6. **Next customer**: after the customer leaves, the clock advances to the next
   phase (Day 9:00 AM → Afternoon 1:00 PM → Evening 6:00 PM → Night 9:00 PM) with a
   fade + time caption, and the next customer spawns.
7. **Day complete** after four customers: summary panel (served / earned / total
   money), then **Next Day** starts Day N+1 with a fresh shuffled customer pool.

## Customers (`Config.CUSTOMERS`)

| id | Asset | Order | Walk speed |
|---|---|---|---|
| `granny` | `granny.glb` | 2× caramel | 0.7 |
| `child` | `child.glb` | 2× chocolate chip | 1.1 |
| `man` | `man.glb` | 1× pistachio rose + 1× jam | 1.0 |
| `guitarist` | `guitarist.glb` | 1× smores + 1× caramel | 0.9 |

Cookie types: `chocolate_chip`, `jam`, `smores` (= cookies & cream asset),
`caramel`, `pistachio_rose`. Each customer has dialogue lines for order, repeat,
success, raw/frozen, wrong count, wrong type and timeout.

## Systems

| System | Where | Notes |
|---|---|---|
| Money, order, phase, HUD signals | `Game.gd` (autoload `Game`) | 15 signals incl. `money_changed`, `order_changed`, `phase_changed`, `bake_progress`, `day_complete`, `time_changed` |
| Day flow, phases, lighting | `Day.gd` | 4 customers/day, 50 s order timer, phase apply, day card, day complete, `next_day()` |
| Customers | `Customer.gd` | Walk-in → ordering → walk-out state machine; validates bag count/type on hand-over |
| Stations | `Stations.gd` | Freezer, tray, oven, bag, seal, hand-over checks; dynamic GI for moved objects |
| Player interaction | `PlayerInteract.gd` | 3 m raycast (`Config.INTERACT_RANGE`), held item, drop, dynamic GI |
| Player controller | `player.gd` | 3 m/s, mouse look with ±80° pitch clamp, gravity, `move_and_slide()` |
| UI | `UI.gd` | Menu, HUD, order card, timer, prompts, hints, toast, fades, day/time cards, day-complete panel |
| Interactables | `Interactable.gd` | StaticBody3D on layer 2; `set_active(false)` clears collision |
| Freezer door | `freezer_door.gd` | Door open/close animation |

## Scene tree (top level of `main.tscn`)

`Main` → `Player` (Collision, Mesh, Camera, Interact), `Sun`, `Lamps`
(3 pendant + 3 track SpotLight3Ds, group `lamp`), `ExteriorFill`, `Env`
(WorldEnvironment), `ShopFloor` (floor + four wall colliders), `CookieShop`
(imported `cookie_shop.glb` + generated colliders + `OvenGlow`), `Customer`,
`ShopReflectionProbe`, `MenuCamera`, `Stations`, `UI` (CanvasLayer), `Markers`
(CustomerSpawn / CustomerSpot / CustomerExit), `Day`, `FillLights` (9 omnis).

## Assets

All runtime models are **GLB** files in the project root, loaded via
`Config.ASSET_*` / `Config.COOKIES` / `Config.CUSTOMERS`:

- `cookie_shop.glb` — shop shell, counters, furniture, lamps, windows
- `cookie_oven.glb`, `cookie_oven_tray.glb`, `bag_open.glb`, `bag_sealed.glb`
- `granny.glb`, `child.glb`, `man.glb`, `guitarist.glb`
- Cookie GLBs: `caramel_cookie.glb`, `chocolate_chip_cookie.glb`,
  `strawberry_jam_cookie.glb`, `cookies_and_cream_cookie.glb`,
  `pistachio_rose_spec.glb` (+ baked `*_BAKE_MAT_*.png` textures)

Blender sources for the shop, bags, oven and customers live in
`E:\coookie seller\blend_sources\`; re-export to GLB and copy into this folder.
Keep node names stable — scripts look nodes up by name (`PENDANT_Bulb_1`,
`TABLE_1_Top`, `ShopFloor`, …).

## Lighting (current state)

Dynamic only — **no GI, no baking**. Condensed from `Config.LIGHT_PHASES`:

| | Day | Afternoon | Evening | Night |
|---|---|---|---|---|
| Sun colour | `#FFE2B8` | `#FFD9A8` | `#FF9A5C` | `#8FA8E0` |
| Sun energy | 2.2 | 1.8 | 1.2 | 0.3 |
| Elevation / yaw | 28° / 25° | 22° / 0° | 8° / −18° | 38° / 40° |
| Exposure | 1.0 | 1.0 | 0.95 | 1.1 |
| Lamp × | 1.0 | 1.1 | 1.4 | 1.9 |
| Fill × | 0.75 | 0.8 | 1.0 | 1.25 |
| Ambient × | 1.0 | 1.0 | 0.85 | 0.55 |

- Sun: warm, one shadow caster, **Orthogonal** shadows, 30 m, angular 0.6,
  blur 1.4, bias 0.04 / normal bias 1.5.
- Ambient: sky source, **0.7 sky contribution**, cool `#C4D6EA`, energy 1.0.
- Filmic tonemap, glow 0.5 / 1.0 / 0.05 on Screen, fog follows the horizon.
- Six lamps: pendant spots (1.6 base, shadows on), track spots (0.9, shadows off).
- Nine shadowless fills in `/Main/FillLights` (warm + cool corners/window).
- Fake contact AO under the two seating tables; 7 additive light halos.
- `ShopReflectionProbe` covers the room; window glass is transparent, no emission.
- Project settings: shadow size 4096 / atlas 4096, soft filters Very High,
  **MSAA off + FXAA**, 24 lights per object.

## Key coordinates

- Room bounds: x −4..4, z −6..3; floor y 0
- Back counter top: y 0.93, x −1.55..1.05, z −5.95..−5.2
- Oven: x 1.7..3.3, z −5.95..−5.15; interaction point `(2.5, 1.0, −5.0)`
- Front window counter top: y 1.0, x 0.85..3.65, z 2.15..2.95; clear zone x 0.85..1.66
- Tray home `(1.28, 1.0, 2.55)`, bag `(1.82, 1.0, 2.28)`
- Island top: y 0.98, x −0.75..1.75, z −3.15..−2.05
- Customer spawn/exit `(−2.5, 0.03, 2.45)`, spot `(2.2, 0.03, 1.35)`
- Player spawn `(−1.6, 0.9, 0.5)` facing the freezer
- Pendant lamps `(−1.8, 2.22, 0)`, `(0.6, 2.22, 1.15)`, `(2.95, 2.22, 2.45)`
- Track lamps `(−0.8, 1.74, −5.62)`, `(−0.25, 1.74, −5.62)`, `(0.3, 1.74, −5.62)`
- Seating tables `(−1.5, 0.7, 2.2)`, `(−0.3, 0.7, 2.2)`

## Gotchas

- **Do not run a second Godot instance while the editor is open** — mixed
  OpenGL/Vulkan contexts crash the NVIDIA driver (`nvoglv64.dll`).
- GL Compatibility has **no** SSAO, SSIL, volumetric fog, VoxelGI, LightmapGI or
  SDFGI. Do not press "Bake Lightmaps" (it crashes the editor); use the fill-light
  approach in `Day.gd`.
- `game_eval` snippets are tab-indented; **never return a dictionary literal**
  (parser break → `EVAL_GAME_NOT_READY`). Return arrays/strings.
- A parser error parks the game at a break; recover with
  `project_manage(op="stop")` then `project_run`.
- `game_eval` can report "main loop not advancing" when the embedded Game view is
  unfocused — take a game screenshot (or relaunch) and retry.
- Disabled interactables must call `set_active(false)`, or they still block the ray.
- Bake/tray tests must wait for tweens (0.8 s slide, 0.6 s return).
- `Config.build_cookie()` returns a wrapper whose `scale` is the normalisation
  factor — don't scale it again.
- `display_name()` appends " Cookie" (e.g. "2x Caramel Cookie").
- Never use absolute `/Main/...` paths at runtime inside gameplay scripts — use
  `get_parent().get_node(...)`.
