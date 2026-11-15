# resize_shop.md: Enlarge the Cookie Shop Interior (Godot 4.7, Compatibility renderer)

## Goal
Make the shop interior bigger so there is more walking space. Increase the room's **width (X axis)** by **+40%** and its **depth (Z axis)** by **+40%**. Keep the **ceiling height (Y axis) the same**. Do not stretch any furniture or props. Only the room shell grows, and furniture is moved to keep the same layout feel with more open space between things.

## Axis note
Godot is Y-up. X is left/right and Z is forward/back along the floor. Y is height. "Bigger shop" here means a bigger floor area (X and Z).

## Current scene (read this instead of guessing)
- Scene `main` has these nodes: Player (Collision, Mesh, Camera), Sun, ExteriorFill, Env, ShopFloor, CookieShop, Granny. A LightmapGI, lights and a ReflectionProbe may also exist after the lighting pass.
- `CookieShop` is a small single-room stylized bakery called "Golden Crumb". From outside it is a box building with a dark wooden door. Walls are two-tone: cream upper wall and orange wainscot lower wall. Thick dark red-brown wooden beams cross the ceiling.
- Left side: two small round dark wooden tables with white and red-brown chairs on a round cream rug, a pot with a pistachio-green plant in the left corner, and an orange-framed door on the back-left wall. A track of small white string lights runs along the upper left wall.
- Centre: a long wooden service counter with a cream counter top and a glass display case at the back, with a small swing door at the end of the counter.
- Back wall: a wooden shelf unit with jars, a window, and a chalkboard menu "Golden Crumb" in an orange frame.
- Right side: a wooden shelf unit with cardboard boxes, flour sacks on a pallet, and a kitchen counter with an orange cabinet, baking tray and rolling pin.
- One orange pendant lamp hangs from the ceiling near the back, and there are windows on the walls.
- `ShopFloor` is the floor node, `Granny` is an NPC outside the window, and `Player` is the controllable character.

## Rules (important)
1. **Never scale the `CookieShop` root node, or any furniture or prop.** Scale must stay `(1, 1, 1)` on tables, chairs, counters, shelves, sacks, the plant, lamps, the chalkboard and doors. Uniform or non-uniform scaling of these will distort them.
2. Only the room shell may be resized: floor, walls, ceiling, wainscot, baseboards, rug (if it is a big circle you may scale it uniformly in X and Z, a bit bigger).
3. Beams: do not stretch them if they are single long meshes. Make them longer by changing the mesh size, or add extra beams so the spacing stays the same. Add beams so the ceiling does not look empty.
4. Do not touch the Player's Camera or the Granny's mesh.
5. Back up `main.tscn` (and the shop scene if separate) before any edit.

## Step 1: Inspect first (report back before editing)
- List the full node tree of `CookieShop` and tell me whether the shell parts (floor, each wall, ceiling) are **separate meshes/nodes** or one merged mesh.
- Report the current room size: min/max X and Z extents of the floor, and the wall height.
- Report the current positions of every furniture and prop group.

## Step 2: Grow the shell
**Case A: walls, floor and ceiling are separate nodes (preferred)**
- Floor and ceiling: increase the mesh size (or collision shape size) by +40% in X and +40% in Z. If you must use node scale, apply it to the floor and ceiling only, and fix their texture/UV tiling so textures do not stretch (use triplanar or world-space UV, or increase the UV scale by the same factor).
- Walls: keep the wall height the same. Move the left/right walls outward in X and the front/back walls outward in Z so the room grows from a fixed back-left corner (pick one corner as the anchor, and keep the door and street-facing wall on the side that faces the Player's entrance). Lengthen each wall along its own length only (not its height). Tile the cream upper part and orange wainscot instead of stretching them. The wainscot height and baseboard height must stay the same.
- Doors and windows stay the same size. Re-position them along their walls so they are centred nicely on the new longer walls. If a wall is much longer, add one extra window on the long side wall so the room does not feel blank.

**Case B: the shop shell is one merged mesh**
- Do NOT stretch it. Tell me, and instead build a new shell with simple box meshes: floor, 4 walls, ceiling, with matching materials (cream upper wall, orange wainscot, wood floor, baseboard). Hide or delete the old shell only after the new one is in place and I approve. Keep the original materials and colours.

## Step 3: Re-arrange furniture (more space, same style)
- Keep the same layout style: seating area on the left, service counter and display case in the middle, shelves and kitchen counter on the right and back.
- Push each group toward its wall so the middle has more clear walking space. The walkable path from the door to the counter should be at least **2 metres wide**.
- Space the two cafe tables apart a bit and keep chairs around them. Keep the rug centred under the table area (scale it slightly bigger if needed, uniform in X and Z only).
- Move the chalkboard menu so it stays centred on the back wall.
- Do not add new furniture. I want empty space.

## Step 4: Collision, navigation and Player
- Update the collision shapes of the floor and walls to match the new size. Make sure the Player cannot walk through walls or fall out.
- Keep the Player's spawn point inside the room near the door.
- If a NavigationRegion3D exists, re-bake it for the new floor.
- Check that Granny (outside the window) still stands outside the new outer wall, not inside or in the wall. Move her outward by the same offset the wall moved.
- Check that the `ShopFloor` node (and any outside ground) still lines up with the new floor with no gaps or z-fighting.

## Step 5: Update lighting for the bigger room (Compatibility renderer)
Do not use SDFGI, SSAO, SSIL, SSR or volumetric fog. They do not work in Compatibility.
- Resize the ReflectionProbe (if it exists) so it covers the whole new interior. It must keep `interior = true` and `box_projection = true`.
- Re-position the pendant lamp over the centre of the new open floor, and **add one more pendant lamp** of the same look and the same warm OmniLight (colour `(1.0, 0.72, 0.42)`, energy `1.8`, range `5`) so the bigger room is not dark in the middle. Keep at most 3 shadow-casting lights.
- Re-position the string lights, the window fill lights and the Sun so light still enters through the windows and falls onto the floor. If a window moved, move its fill light with it.
- Resize the LightmapGI node to cover the new room, make sure the new shell meshes have lightmap UVs and GI mode `Static`, then **re-bake the lightmap**.
- If the bake is slow or fails, tell me and use a few extra weak shadowless warm OmniLights as fake bounce light.

## Step 6: Check
1. Run the game and take screenshots from the Player camera: one from the entrance looking at the counter, one looking at the left tables, one looking at the back wall.
2. Check that: nothing is stretched or distorted, no gaps or floating objects, no z-fighting, no textures stretched on walls or floor, no light leaking, no pure-white blown-out surfaces, and the room feels roomy but still cozy.
3. Adjust one thing at a time.
4. Save the scene and give me a short summary of what you changed, with the old and new room size.

## Do not
- Do not scale furniture or the root `CookieShop` node.
- Do not change the ceiling height unless I ask.
- Do not add new furniture or decorations.
- Do not change the art style, colours or materials of the shop.
- Do not switch the renderer from Compatibility.
