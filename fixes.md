# Fix pass: tray handling, granny position, dialogue trigger

Patch the existing project only. Don't rewrite files or add features. Think briefly. Run the project headless once at the end, fix only what fails, then stop. Final reply: 2 lines max.

## 1. Tray: the player carries it (no teleporting)
- Remove every automatic tray slide between the table and the oven.
- With empty hands, interacting with the tray on the table **picks it up** as the held item (cookies stay on it, riding along with it). Hold position: in front of the camera, slightly lower and centered (about (0, -0.3, -0.6)), kept level. Only the tray can be picked up when it has cookies on it. Q or right mouse puts it back on the table where it was.
- A tray can only be picked up if it holds at least 1 cookie, and only the player can move it.
- Interacting with the oven while holding a tray that has **raw** cookies: swap to `oven_open`, then tween the tray from the player's hands into the oven rack (0.6 s), swap to the closed oven, and start the bake (same timer, glow and progress ring as before). The player's hands are now empty.
- When baking is done, swap to `oven_open` and show `[E] Take tray out`. Interacting puts the tray (with the baked cookies) back **into the player's hands** (0.5 s tween from the rack to the hold position). Then the player must walk to the table and interact with the tray spot (`[E] Put tray down`) to place it there. Only after that can baked cookies be picked up for the bag.
- Don't allow loading a tray with no cookies, a tray with only baked cookies, or while baking.

## 2. Granny stands outside the shop at the counter window
- She never enters the shop. Move `GrannySpawn`, `GrannySpot` and `GrannyExit` outside: `GrannySpot` is on the street side of the counter window, about 0.8 m from the window, facing the shop (rotate so her +Z front faces the player side). `GrannySpawn` and `GrannyExit` are about 6 m away along the outside, to the left of the spot, so she walks along the outside of the shop to the window and back.
- Find the window by the node named `Window` or `Counter` in `CookieShop` (case-insensitive). Place the markers relative to it so they follow if the shop is resized. Use the shop's outward direction (away from the room center).
- Make sure walls, window glass and frames don't block the interaction ray to her: raise her interaction range to 3 m and keep window and wall colliders off the interaction ray's mask (or let the ray pass through them). The bag handover happens through the window, and the player doesn't need to leave the shop.

## 3. Granny only speaks when interacted with
- When she arrives at the window she **says nothing**. Show a small floating pale-pink speech icon (a rounded bubble with "..." or "!") above her head instead. The dialogue box and the order card stay hidden.
- Prompt on her: `[E] Talk`. Interacting shows the dialogue with the order ("Good morning, dear! Could I get two caramel cookies, please?"), then the order card and the hint line update. The hint line before that says "Talk to Granny".
- Interacting with her again before the bag is ready repeats the order line. Her reactions to the bag handover (success, frozen, wrong count, wrong type) still play automatically, since they answer the player's action.
- Remove any other automatic dialogue.

Stop after these three fixes.
