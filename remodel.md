Respond with tool calls only until finished. Do not write out reasoning or plans.

# Task: Replace the old freezer in the cookie shop scene with a better cookie display freezer, then re-export the shop

Use the **blender-modeler** skill for all Blender work. Work in the currently open cookie shop scene. This spec is the source of truth; do not look for or analyze any reference image. Stylized, cozy, low-poly game asset matching the shop (soft matte colors, small bevels).

## Why we are replacing the old one
The old freezer is a dark-framed glass fridge with glaring white light strips, flat shelves and trays with dividers. Cookies on it are tiny, washed out and hard to tell apart, and the dark frame clashes with the cozy theme. The new one must make cookies easy to see and identify.

## Efficiency rules (strict)
- Think briefly. No long planning, no alternatives, no second-guessing.
- Step 1: one small inspect call. Step 2: ONE build script (under about 250 lines, helper functions, loops for the 6 compartments), run in ONE execute call. Step 3: one export call. If something fails, patch only the failing part.
- Max 2 viewport screenshots total. Then stop.
- No asset downloads, no addons. Primitives, bmesh and flat-color materials only.
- Don't touch, move, rename or delete anything in the shop except the old freezer. Add NOTHING beyond the parts listed. Final reply: 2 lines max.
- Use `bpy.data` and `bmesh`; avoid `bpy.ops` except for saving and the glb export.

## Step 1: find and remove the old freezer
- List every object whose name contains "freezer", "fridge", "cooler" or "display" (case-insensitive), including its children. Print each one's world position, rotation, dimensions and parent.
- Use the old freezer's world position, facing direction and the wall it stands against as the placement for the new one (new back against the same wall, centered at the old position, same facing).
- Then delete the old freezer and all its children (meshes, lights, stickers, trays), and nothing else.
- If no old freezer is found, place the new one against the back wall to the left of the oven and say so in the final reply.

## Step 2: build the new freezer
- Build everything in a collection `Shop_Freezer` under a root empty named `Freezer`. Units: 1 unit = 1 m. Root origin = floor, centered on the footprint. In the freezer's own frame the **front faces -Y** (rotate the root to match the old freezer's facing).
- If the new cabinet would intersect other shop objects, shift it along the same wall until it fits. Don't resize other objects.
- Bevel all hard edges 0.008 m. Under about 5000 triangles total. No pure white anywhere (brightest color is #F6EBDD). All materials matte, roughness 0.7 or higher, except the glass.

### Design: a cozy bakery display cabinet with 6 small glass-door compartments
Overall size: 1.2 m wide, 0.6 m deep, 1.5 m tall. Layout: 3 columns x 2 rows of compartments, numbered row-major from the top-left: 1, 2, 3 (top row), 4, 5, 6 (bottom row). The 6th section is a spare.

Palette: cream #F1E4D3, pistachio green #A9B77B, dusty mauve #A38A82, copper #B8743A, warm wood #8A5A3B, interior cream #EFE3D0, ramp #D8C8BC, frost blue #CFE3EA.

Parts:
1. **Plinth**: 0.14 m high, mauve #A38A82, inset 0.03 m from the front.
2. **Shell**: side and back panels in pistachio green #A9B77B. **Top**: a warm wood slab #8A5A3B, 0.06 m thick, overhanging the front and sides by 0.02 m.
3. **Frame**: the front frame (stiles and rails) in cream #F1E4D3, with thin copper trim strips #B8743A (0.008 m) around the edge of each compartment opening.
4. **Interior**: each compartment is 0.36 m wide x 0.45 m high x 0.5 m deep, walls in soft cream #EFE3D0 (matte, not white). Dividers between compartments 0.02 m thick.
5. **Display ramp** in each compartment: a sloped matte shelf in #D8C8BC, rising from the front to the back at **30 degrees**, with a low front lip 0.02 m high, so the cookies lie tilted and face the player. The ramp must be big enough for 2 cookies across and 3 rows deep (cookie diameter 0.14 m).
6. **Label rail** under each compartment: the bottom rail of each opening is 0.17 m tall, cream, with a slightly recessed rounded plate (#E6D5BC, 0.14 x 0.14 m) in its center for the cookie sticker.
7. **Glass doors**: each compartment gets a small door (0.36 x 0.45 m), a thin cream frame (0.02 m) with a glass pane 0.006 m thick (base color alpha 0.12, roughness 0.05, alpha blend mode) and a small vertical copper handle bar (0.1 m) on the right edge. The door is a child of an empty `Hinge_<n>` placed at the left edge of the opening, so rotating the hinge around Z swings the door open. Name the doors `Door_<n>`.
8. **Freezer cue**: a frost-blue #CFE3EA band, 0.05 m tall, across the upper front frame, with a simple 6-arm snowflake (6 thin boxes, 0.09 m across) in the center.
9. **Lighting**: no lights and no emissive materials, except one thin ceiling strip per compartment in warm cream #FFF1D6 with emission strength at most 0.25 (barely glowing, never glaring).

### Markers for the game (empties, plain axes, exact names, all parented to the `Freezer` root)
- `Slot_<s>_<k>` for s = 1..6 and k = 1..6: cookie positions on the ramp of section s (2 across x 3 deep, spaced 0.16 m). Each empty sits on the ramp surface and is rotated so its **Z axis is the ramp surface normal** (rotation X = +30 degrees in the freezer's frame).
- `StickerMount_<s>`: at the center of each label plate, Y axis pointing out of the front.
- `Hinge_<s>`: the door hinge empties described above.
- `Section_<s>`: an empty with cube display, at the center of each compartment interior, with scale = half of the interior size (0.18, 0.25, 0.225), used by the game as an interaction box.
- Name every other object clearly (Plinth, Shell, Top, Frame, Ramp_<s>, Handle_<s>, SnowflakeBand, and so on).

## Step 3: check and export
- Take ONE screenshot (front view, slightly from above, showing the freezer in the shop) and check it against the spec. Only fix obvious problems: wrong proportions, ramps clipping through walls, doors that don't fit, the freezer intersecting other objects, missing markers.
- Save the .blend file.
- Export the **entire shop scene** (all meshes and empties, including the new `Freezer` hierarchy; skip cameras and lights) as glb, **overwriting the existing shop glb** (find the existing cookie_shop .glb path first and reuse the same filename; if none exists, use `./cookie_shop.glb`). Settings: +Y up, apply modifiers, export materials. Print the final file path in your reply.
- Stop after that. Don't polish or add anything.
