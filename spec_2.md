# Game Spec 02: Days, 4 customers, order timer, freezer sections, time of day

Patch and extend the existing Godot project (Compatibility renderer, so no SSAO, SSR, SDFGI or volumetric fog). Keep everything that already works (menu, first-person player, interaction ray, tray carrying, oven bake, bag, handover, money HUD, customer standing outside at the counter window, talking only on interact). This spec is the source of truth. Don't ask questions; pick the simplest option.

## Efficiency rules (strict)
- Think briefly. No long planning, no alternatives, no refactors beyond what is listed.
- Build in the milestone order below. After each milestone run the project headless once (`godot --headless --path . --quit`), fix only what failed, then continue. No screenshot loops.
- Patch existing files, don't rewrite them. Everything new is data-driven from `Config.gd`.
- No audio, no saving, no extra features. Final reply: 3 lines max.

## Cookies (data-driven)
Cookie types come from the cookie .glb files already in the project. Currently 5: chocolate chip, jam, smores, caramel, pistachio rose. Match names loosely (lowercase, ignore underscores and spaces: `chocolate_chip`, `choclate`, `jam`, `smores`, `caramel`, `pistachio`). Never hardcode the count; support 5 to 6 types. `Config.COOKIE_COLORS` (for stickers and fallbacks): chocolate chip #6B4A3A, jam #B5403A, smores #C9A27A, caramel #D0A06A, pistachio rose #A9B77B. Price per cookie $4 (`Config.PRICES` can override per type).

## Customers (4 characters, one per day slot)
Pool: granny, child, man (with glasses), guitarist. Load their .glb files (`granny`, `child`, `man`, `guitarist`) and spawn only ONE at a time at runtime into a single `Customer` node (generalize `Granny.gd` into `Customer.gd`; hide or remove the pre-placed Granny node). Each uses the same outside markers (`CustomerSpawn`, `CustomerSpot` at the counter window, `CustomerExit`), walks along the outside to the window, faces the player (models face +Z), idles with a small bob, and has its own walk speed (granny 0.7, child 1.1, man 1.0, guitarist 0.9 m/s). The dialogue box anchors to the top of that customer's bounding box + 0.25 m. Nameplate pill: Granny, Child, Man, Guitarist. Prompt: `[E] Talk to <Name>`.

Every day: shuffle the pool and serve 4 customers (with a pool of 4, each appears once per day in random order; if the pool grows later, pick 4 at random). Orders (max 2 cookies each, because the bag has 2 slots):

| Customer | Order | Personality |
|---|---|---|
| Granny | 2 x caramel | warm, calls you "dear" |
| Child | 2 x chocolate chip | excited, simple words |
| Man | 1 x pistachio rose, 1 x jam | polite, formal, a bit distracted |
| Guitarist | 1 x smores, 1 x caramel | laid-back, "man", "dude" |

Dialogue lines (store in `Config.CUSTOMERS`; keys: order, repeat, success, raw, count, type, timeout). The order line shows only when the player interacts. Write these:
- Granny: order "Good morning, dear! Could I get two caramel cookies, please?" / repeat "Two caramel cookies, dear." / success "Lovely, thank you dear!" / raw "Oh dear, these are still frozen!" / count "I asked for two cookies, dear." / type "These aren't what I asked for, dear." / timeout "Oh well, my tea is getting cold. Goodbye, dear."
- Child: order "Hi! Can I have two chocolate chip cookies? Please please please!" / repeat "Two chocolate chip cookies, please!" / success "Yay! Thank you!!" / raw "Ew, they're cold!" / count "I wanted two cookies!" / type "That's not chocolate chip!" / timeout "I can't wait anymore... bye."
- Man: order "Good afternoon. One pistachio rose and one jam cookie, if you would." / repeat "One pistachio rose, one jam. Thank you." / success "Excellent. Much appreciated." / raw "I believe these haven't been baked." / count "I ordered two cookies." / type "I'm afraid that isn't my order." / timeout "I have a meeting to catch. Never mind."
- Guitarist: order "Hey, man. One smores and one caramel, whenever you're ready." / repeat "One smores, one caramel. No rush." / success "Sweet, thanks man. Rock on." / raw "Dude, these are ice cold." / count "Uh, I asked for two cookies." / type "Uh, that's not what I ordered." / timeout "Gotta catch my set. Catch you later."

## Day flow
1. **Play** (or Next day) shows a full-screen "Day N" card: fades from black, big cream text on a dark mauve screen, held 2 s, then fades out. N starts at 1.
2. Customer 1 walks in. When a customer finishes (success, fail-by-timeout) they walk out, then 3 s later the next one walks in. A customer is "finished" only on a correct handover or on timeout (wrong bags just reset the bag and the order stays open).
3. After customer 4 leaves: a "Day N complete" card (cream panel): customers served X/4, earned today $Y, total money $Z, and a **Next day** button. Next day fades through black, shows "Day N+1", resets the time to Day, reshuffles customers. Money carries over.
4. HUD adds: top-center `Day N` and `Customer k/4`.

## 50 second order timer
- The timer starts when the player talks to the customer and the order line shows (first interact). Before that the customer waits with no timer.
- HUD: a bar under the order card (cream track, pistachio fill, turns golden under 20 s and copper under 10 s with a small pulse) plus the seconds as a number.
- At 0: the customer says their timeout line, no payment, the order fails, and they leave unhappy. Then fully reset the stations: drop the held item, clear the tray and bag, cancel any bake in progress, reset the oven to closed. Wrong bags don't stop or reset the timer.
- Success pays the sum of the prices (floating `+$` text over the customer, HUD count-up), then the stations reset the same way.
- Order card: lists every item with a checkbox, for example `1x Pistachio Rose`, `1x Jam`.
- Order check (stop at the first failure): any cookie raw (raw line) / wrong total count (count line) / wrong types (type line). On failure the bag resets and the tray clears, with no payment, and the timer keeps running.

## Freezer sections and stickers
- The freezer keeps its current look. Divide it into **one section per cookie type** (5 now). Use its existing shelves or doors; if they don't match the count, group shelf levels into sections or add thin divider panels. Compute the sections from the number of cookie types.
- Each section holds **only its own cookie type**: fill it with a few display cookies (about 6, flat on a tray or leaning), all of the same type, using the real cookie models (frosty raw overlay like before).
- Interact on a section's cookies gives the player one raw cookie of that type. Keep the current freezer door behavior if it already exists; each section has its own collider and the prompt `[E] Take <Cookie name>`.
- **Sticker outside each section**: a small rounded square, cream #F1E4D3, about 0.12 x 0.14 m, with a thin mauve border, slightly rotated (random between -3 and 3 degrees) and stuck on the glass or the frame next to that section. It shows a picture of the cookie on top and the name below in small charcoal text (`Label3D`, a rounded font if the project has one). The picture is made once at startup: render each cookie model top-down with a small `SubViewport` (128 x 128, transparent background, orthographic camera, `UPDATE_ONCE`), use the result as a texture on the sticker quad, then free the viewport. If that fails, fall back to a flat disc in `COOKIE_COLORS`.
- Stickers must be readable from the player's normal standing spot in front of the freezer.

## Time of day (4 phases tied to the 4 customers)
- Phase 1 Day (customer 1, 9:00 AM), Phase 2 Afternoon (customer 2, 1:00 PM), Phase 3 Evening (customer 3, 6:00 PM), Phase 4 Night (customer 4, 9:00 PM). The phase changes when the previous customer leaves, tweened over 4 s while the next customer walks in. Each new day starts again at Day.
- HUD chip (top-center under the day label): a small colored circle (golden day, orange afternoon, pink evening, blue night) plus the phase name and time.
- **The Day preset is the current lighting of the game, unchanged.** At startup, read the existing lighting from the scene (the `Sun` DirectionalLight, `ExteriorFill`, the `Env` WorldEnvironment, interior lamps such as the pendant lamp, the oven glow and the window glass emission) and store the values as `PRESETS.day`. Never change how the Day preset looks. The other phases are derived from it:
  - **Afternoon**: sun color 50% toward #FFD9A0, sun energy x0.9, sun elevation 15 degrees lower, ambient 30% toward warm #FFC987.
  - **Evening**: sun color #FF9A5C, energy x0.5, elevation about 8 degrees, ambient 40% toward dusky pink-purple #B07A9A with energy x0.7, background and sky color toward #E0906A, interior lamp energy x1.3.
  - **Night**: sun becomes a cool moon: color #8FA4D8, energy x0.12, elevation about 35 degrees, ambient toward #2A3350 with energy x0.45, background #141A33, interior lamps x1.8 (warm, kept cozy), window glass emission slightly warm. The oven glow stays the same.
- Implement one `LightingPresets` dictionary and one `apply_phase(phase, duration)` that tweens light color, energy, rotation (elevation), ambient color and energy, background color, and the interior lamps' energies. Don't create new lights, except that you may add one soft cool `OmniLight3D` window fill at night if the interior becomes unreadable. Keep it light for the Compatibility renderer (no extra shadow-casting lights).
- Game items (cookies, tray, bag, stickers) must stay readable in every phase.

## Optional paste: current lighting values
If this block is filled in, treat it as the truth for `PRESETS.day`; if it's empty, read from the scene as described above.
