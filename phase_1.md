Respond with tool calls only until finished. Do not write out reasoning or plans.

# Game Spec 01: Cozy Cookie Shop, first mechanic (order loop)

Engine: **Godot 4.x, GDScript, Compatibility renderer** (so no SSAO, SSR, SDFGI or volumetric fog; glow only if already enabled). This spec is the source of truth. Do not ask questions; when something is ambiguous, pick the simplest option.

## Efficiency rules (strict)
- Think briefly. No long planning, no alternatives, no refactors, no extra features.
- Build in the milestone order below. After each milestone, run the project headless once (`godot --headless --path . --quit`) to catch parse errors, fix only what failed, then move on.
- Max 2 full-project run checks per milestone. No screenshot loops. Don't rewrite whole files for small fixes; patch them.
- Inspect the existing main scene tree ONCE at the start (via Godot MCP or by reading the .tscn), then reuse what is there. Do not recreate nodes that already exist (Player, CookieShop, Granny, lights, environment).
- No audio, no saving, no settings menu, no extra customers, no tutorials. Keep total code under about 900 lines.
- If an asset is missing, build a simple colored primitive placeholder with the same name, print one warning, and continue.
- Final reply: 3 lines max.

## The game in one paragraph
A cozy shop game in first person. The player stands behind the counter. A granny walks in and asks for **two caramel cookies**. The player takes two frozen cookies from the **freezer**, puts them on the **tray**, puts the tray in the **oven**, waits for them to bake, takes the baked cookies out, puts them in a **paper bag**, seals it, and hands it to the granny. The granny pays and **the player's money goes up**. Then the loop restarts with a new granny order.

## Assets (find them, don't hardcode absolute paths)
Search the project once for these .glb files (case-insensitive name match) and cache the paths in `Config.gd`:
- `cookie_shop` (the shop, already in the scene as `CookieShop`; reuse it, don't re-import)
- `granny` (already in the scene as `Granny`; reuse it)
- `bag_open`, `bag_sealed`
- `oven_open` (oven with its door open; the shop's own oven is the closed one)
- `tray` (may not exist: if not found, build it procedurally, see Tray)
- The 6 cookie models: every other .glb in the cookie folder. Cookie id = filename without extension, display name = capitalized with underscores turned into spaces. If a folder like `assets/cookies/` exists use it; otherwise treat every .glb that is NOT in the list above or a character (`child`, `man`, `guitarist`) as a cookie. The "caramel" cookie is the file whose name contains `caramel`; if none exists, use the first cookie as a stand-in and print a warning.
- Position stations by reading nodes inside `CookieShop` by name (case-insensitive substring: `Oven`, `WorkTable`, `Counter`, `Door`), because the shop may be resized later. Only use coordinates from `Config.gd` as a fallback.
- Coordinate note: the .glb files came from Blender (Y-forward front becomes +Z). Models face **+Z** in Godot, so to make a model face a point, rotate it so its +Z points to that point (`atan2`), not `look_at` alone.
- Normalize each cookie once on load: recenter on XZ, put the bottom at y = 0, and scale so the diameter is `COOKIE_DIAMETER = 0.14` m (readable gameplay size).

## Best way to build it (follow this)
- ONE main scene with a small state machine, no scene switching. Autoload `Game.gd` holds `money` and signals (`money_changed`, `order_changed`, `phase_changed`).
- Files: `Config.gd` (constants, prices, order data, asset paths), `Game.gd` (autoload), `Interactable.gd` (body with `kind`, `prompt`, `interact(player)`), `PlayerInteract.gd` (raycast, hold slot, input), `Stations.gd` (freezer, tray, oven, bag logic), `Granny.gd` (walk, face, order, dialogue), `UI.gd` (menu, HUD, dialogue box).
- Use `create_tween()` for every animation (walking, door, tray sliding, flying cookies, money count-up). No AnimationPlayer, no physics for items.
- Interactables are `StaticBody3D` on collision layer 2 with a `BoxShape3D` built from the node's AABB. Meta `kind` identifies them.
- Customers and orders are data: `Config.ORDERS = [{"customer": "granny", "items": {"caramel": 2}}]` and `Config.PRICES = {"caramel": 4}` with default price 4 for any other cookie. The loop reads these so more customers can be added later without code changes.

## Player and interaction (first person)
- Use the existing `Player` node and its `Camera3D`. If it has no movement controller, add a simple one: WASD, mouse look, walk speed 3 m/s, capsule collider, gravity, no jump or sprint. Mouse is captured while playing.
- Interaction: a ray from the camera center, range 2.2 m, mask = world + interactables. If an interactable is hit first, show a prompt under the crosshair like `[E] Open freezer`. Pressing **E or left mouse** interacts. **Q or right mouse** returns the held item (a held cookie goes back to the freezer, a held bag goes back to the table).
- Crosshair: small cream dot (#F1E4D3) with a thin charcoal outline, in the screen center.
- Held item: a child of the camera at the offset (0.28, -0.22, -0.55), slightly tilted, following with a small lerp sway. The player holds only ONE thing at a time.

## Stations
**Freezer** (procedural, unless a `freezer` .glb exists): an upright box 0.7 x 1.1 x 0.65 m, pale icy color #DCE8EC, matte, with a copper handle (#B8743A). Place it against the back wall next to the oven (to the oven's left, 0.9 m away; shift it if it overlaps a wall or the oven). The door is a hinged box. Interact opens or closes it (0.4 s tween). Inside: 2 shelves holding the 6 cookie types, 3 per shelf, each cookie lying flat or leaning with a small `Label3D` (billboard, cream text) of its display name. They are visible only when the door is open. Interact on a cookie gives the player one **raw (frozen)** cookie of that type. The shelf stock is infinite. Raw look = a `material_overlay` (StandardMaterial3D, color #DCE8EC, alpha 0.6, transparency alpha). Baked look = no overlay.

**Tray** (use `tray.glb` if found; otherwise build it): a flat tray 0.5 x 0.02 x 0.35 m with a 0.03 m rim, base color #9A9490, rim a little darker #7D7773, slightly metallic (metallic 0.4, roughness 0.5). On the work table. It has **4 slots** (2 x 2) with faint circular marks (flat cylinders r 0.07 m, a slightly lighter tone). Each slot is its own interactable. Holding a cookie and interacting with an empty slot places it there (0.25 s snap tween). With empty hands, interacting with a slot that holds a **raw** cookie takes it back (discarded). Interacting with a **baked** cookie picks it up (used for bagging).

**Oven**: the shop's closed oven is the normal state, and `oven_open.glb` is placed at the same transform, hidden by default. Interact on the oven when the tray has at least 1 raw cookie and the player's hands are empty:
1. Show `oven_open`, hide the closed oven. The tray slides from the table into the oven (0.8 s arc tween, tray scale stays the same).
2. Swap back to the closed oven. The oven glow light (OmniLight3D, color #FF9A3C) fades in. A world-anchored progress ring (a 2D `TextureProgressBar` or ColorRect arc, projected above the oven) fills over `BAKE_TIME = 6.0` s.
3. When done: a small "ding" visual (the ring pulses), the glow fades out, swap to `oven_open`, and the prompt `[E] Take tray out` appears.
4. Interact: the tray slides back to the table. All cookies on it crossfade from raw to **baked** (overlay alpha 0 over 0.5 s), flagged `baked = true`.
- The tray can't go in while empty or while baking.

**Bag**: `bag_open.glb` sits on the work table beside the tray. The bag has 2 baked-in cookie nodes named `Cookie_A` and `Cookie_B`; **hide them** but use their transforms as the two cookie slots. Holding a **baked** cookie and interacting with the bag flies the cookie (0.3 s arc tween) into the next free slot as a real instance of that cookie model, scaled so its diameter matches the hidden `Cookie_A` node. Raw cookies are refused with the hint "Needs baking first". With empty hands and at least 1 cookie in the bag, the prompt `[E] Seal bag` swaps to `bag_sealed.glb` with a small squash tween (scale 1 to 0.9 to 1.0). Interacting with the sealed bag with empty hands picks it up (held item). The player then walks to the granny.

## Granny (customer)
- Reuse the existing `Granny` node. Three markers (create `Marker3D` if missing): `GrannySpawn` (just inside the door, from the `Door` node), `GrannySpot` (in front of the counter on the customer side, 0.9 m from the counter), `GrannyExit` (= spawn).
- Phases: `ENTERING` (walk to the spot at 0.9 m/s with a small vertical bob and a sway on Z rotation, faces her direction of travel) → `ORDERING` (turn to face the player, dialogue appears) → `WAITING` → `RECEIVING` → `PAYING` → `LEAVING` (walk to exit, hide, wait 3 s, restart).
- She is also an interactable (`kind = granny`). With a **sealed bag** in hand the prompt is `[E] Give bag`. Otherwise the prompt is `[E] Talk` and she repeats the order.

## Order check (on handing over the bag)
Evaluate in this order and stop at the first failure (granny line in quotes):
1. Any cookie raw → "Oh dear, these are still frozen!"
2. Wrong count → "I asked for two cookies, dear."
3. Wrong type → "These aren't the caramel ones I asked for, dear."
Failure: the bag is emptied and reset (open bag back on the table), the tray is cleared, the phase returns to gathering, and no money is paid.
Success: "Lovely, thank you dear!", payment = sum of `PRICES` for the order (2 x $4 = $8), the money HUD counts up (0.6 s tween) with a floating `+$8` text popping above her head. She leaves. A small "Order complete!" toast shows for 2 s.

## UI (cozy style)
Palette: cream #F1E4D3, dusty mauve #A38A82, pistachio #A9B77B, pale pink #EFCDBB, golden #E0B65A, charcoal text #4A4543, copper #B8743A. Rounded corners (16 px), soft shadows, generous padding. Use a bundled rounded font if the project has one, otherwise the default font.
- **Main menu**: shown on start over the shop. A separate `MenuCamera` slowly sways around a nice cutaway view of the shop (very slow, about 0.02 rad/s), with a warm dark vignette (`GradientTexture2D` radial, alpha 0.25). Center-left: a title (constant `Config.TITLE = "Cozy Cookie Shop"`) in a cream panel, and two buttons: **Play** and **Quit**, with a hover scale of 1.05. On the right: 3 of the cookie models floating and slowly rotating in front of the camera. Play fades to black (0.4 s), switches to the player camera, captures the mouse and starts the first granny. **ESC** during play releases the mouse and shows the menu with **Resume** instead of Play.
- **Money HUD** (top-left): a cream pill with a golden coin circle and `$0`.
- **Order card** (top-center, only while an order is active): `Order: 2x Caramel Cookie`, with two small checkboxes that fill as cookies get baked and then handed over.
- **Dialogue box**: a cream rounded panel with a mauve border and a downward tail, anchored above the granny's head (project her head position with `unproject_position`; hide it when she is behind the camera, clamp it to the screen edges otherwise). A small pistachio name pill "Granny" sits on its top-left corner. Typewriter text at 40 chars/s, click to skip. It auto-hides 3 s after the last line, or when the phase moves on.
- **Hint line** (bottom-center, small, semi-transparent) shows the next objective: "Granny is waiting" / "Open the freezer" / "Put 2 cookies on the tray" / "Put the tray in the oven" / "Baking..." / "Take the tray out" / "Put the cookies in the bag" / "Seal the bag" / "Give the bag to Granny".

## Lighting and look
Keep the shop's existing lighting and environment. Do not add new lights except the oven glow. Items should stay readable: cookies and tray must not be darker than the surrounding surfaces.

## Milestones
1. Menu + player camera switch + money HUD + hint line.
2. Granny enters, dialogue box with the order, order card.
3. Freezer (procedural), cookies in hand, tray with 4 slots (procedural if missing).
4. Oven bake sequence with the open-oven swap, baked look.
5. Bag filling, sealing, carrying, handover, order check, payment, granny leaves, loop restarts.

Stop after milestone 5. Don't polish or add anything.
