Respond with tool calls only until finished. Do not write out reasoning or plans.

# Task: Model two separate low-poly customer characters in Blender: a granny and a child

Use the **blender_modeling** skill for all Blender work. This is a new chat with no context, so this spec is the only source of truth. Do not look for or analyze any reference image. These are customers for a cozy cookie shop game. Style: clean, stylized, chunky low-poly with flat-shaded facets, simple readable shapes, soft matte colors, consistent proportions. Both characters must share the same art style so they look like they belong in the same game.

## Efficiency rules (strict)
- Think briefly. No long planning, no alternatives, no second-guessing.
- Write the whole scene as ONE Python script (under about 300 lines, using helper functions) and run it in ONE execute call. If it fails, patch only the failing part.
- Max 2 viewport screenshots total (one after the first run, one after a fix pass if needed). Then stop.
- No asset downloads, no addons, no sculpting, no rigging, no animation, no textures from files. Only primitives, bmesh and flat-color materials.
- Add NOTHING beyond the parts listed. No scenery, no extra props.
- Don't ask questions; if unsure, pick the simplest option. Final reply: 2 lines max.

## Best way to build it (follow this, don't explore other methods)
1. Use `bpy.data` and `bmesh`. Avoid `bpy.ops` except for the glb export and the render setup.
2. Write these helpers first and reuse them for every part:
   - `mat(name, hex, rough=0.8)` creates a Principled material (flat color, no textures)
   - `part(kind, name, loc, scale, material, parent, rot=(0,0,0))` creates a UV sphere (kind "sphere", 8 segments and 6 rings), a cylinder (kind "cyl", 8 vertices), a cone, or a box. It applies the scale, sets flat shading, adds a Bevel modifier (width 0.01, 1 segment), links it to the collection and parents it.
   - `limb(name, top_loc, length, r_top, r_bottom, material, parent)` makes a tapered 8-sided cylinder whose **origin is at the top joint** (shoulder or hip), so it can be rotated and animated later.
   - `build_granny()` and `build_child()` call these helpers and return the root empty.
3. Build each character from simple parts only (below). Make the head a slightly squashed sphere, the torso a tapered cylinder, and the limbs from `limb()`. Do not use subdivision surface and do not build realistic anatomy.
4. Build the child by calling a shared `build_person(params)` with different size and color parameters wherever possible, then add the unique extras (hair, glasses, bag, cap and so on) after the common body.
5. Faces are tiny: eyes are 2 small dark spheres (r 0.012), nose is a tiny sphere, cheeks are 2 flat pink discs, and no mouth for the child, a small thin dark curve for the granny. This avoids uncanny faces.
6. Set each character's origin at the floor between the feet, facing -Y (front), standing upright in a relaxed A-pose (arms slightly away from the body, about 10°).
7. Finally, set up the camera, lights, background and export, all in the same script, then run once.

## Setup
- Delete the default cube, light and camera. Units: 1 Blender unit = 1 meter.
- Place `Granny` at X = -0.7 and `Child` at X = +0.7 (so you can preview both), both standing at Z = 0 and facing the camera.
- Keep each character as its own empty hierarchy and its own collection, so they can be exported separately.

## Character 1: Granny (about 1.55 m tall)
Proportions: slightly stylized, head about 1/5.5 of the total height, a soft rounded body, a slight forward hunch (tilt the upper torso about 5° forward).
- Skin: warm light tone #E8B896.
- Head: squashed sphere, width 0.2 m, height 0.22 m. Small round nose. Rosy cheeks #E39A94.
- Hair: silver-gray #C9C6C4. A bun on the top back (one sphere, r 0.07 m) and a cap of hair over the top of the head (a sphere scaled to a half-dome sitting on the skull) with a few side tufts. Make the bun slightly lumpy with 2 small spheres attached.
- Glasses: two thin round rings (torus, major radius 0.035 m, minor radius 0.004 m) in dark brown #4A3B35, joined by a tiny bridge, sitting in front of the eyes.
- Neck: short cylinder in the skin color.
- Torso: a tapered cylinder (wider at the hips), a cardigan in dusty mauve #A38A82, with a cream collar piece #F1E4D3 (flattened torus or small boxes) and 3 tiny round buttons in cream down the front.
- Skirt: a long cone/cylinder from the waist to the mid-calf, in soft pistachio green #A9B77B, slightly flared.
- Arms: `limb()` in cardigan mauve for the upper arms and skin-colored hands (small spheres, r 0.035 m). The right arm hangs holding a handbag.
- Handbag: a small box 0.14 x 0.05 x 0.11 m in kraft brown #B07A4A, with a thin half-torus handle, hanging from the right hand.
- Legs: short skin-colored lower legs below the skirt, and chunky sensible shoes in warm brown #6B4A3A (boxes with rounded bevels).

## Character 2: Child (about 1.0 m tall)
Proportions: cute and chunky, head about 1/3.5 of the total height (big head), short stubby limbs.
- Skin: warm medium tone #D9A27E. Rosy cheeks #E08A7E.
- Head: slightly squashed sphere, width 0.24 m, height 0.23 m. Round nose. Big, simple dark eyes (r 0.016 m), with a tiny white highlight sphere on each. No mouth.
- Hair: short messy dark-brown #4A3226. A dome cap over the skull plus 4 or 5 small cone tufts sticking out on the top and sides.
- Torso: a short chunky cylinder wearing a t-shirt with horizontal stripes in pistachio green #A9B77B and cream #F1E4D3 (build the stripes as 4 stacked cylinder rings of alternating color, each with a slightly different radius to follow the taper). A short round neck collar in cream.
- Shorts: dusty mauve #A38A82, two short wide cylinders hanging from the waist.
- Arms: short `limb()` in skin color, with small round hands. The left arm is raised slightly (about 35°) as if pointing at the cookies.
- Legs: short chunky skin-colored `limb()`, with white socks #F6EBDD (short cylinders) and chunky sneakers in pale pink #EFCDBB with cream soles #F1E4D3.
- Small backpack: a rounded box 0.14 x 0.07 x 0.16 m in warm golden #E0B65A on the back, with two thin strap boxes over the shoulders.

## Materials and finish
- Flat-shaded polygons with Bevel modifiers only. All materials matte (roughness 0.8). No textures, no shiny parts.
- Name the parts clearly (Head, Hair, Torso, Arm_L, Arm_R, Leg_L, Leg_R, and so on) and parent them to the root empties named `Granny` and `Child`.

## Lighting and camera
- One soft large area light from the upper left in front, plus a low warm-white world light. EEVEE, AgX tone mapping, no heavy bloom.
- Background: a large flat matte mauve plane #A5806C behind the characters.
- Camera: orthographic, front view, at chest height, framing both characters side by side with a small margin. Render 1920x1080.
- Take ONE screenshot and compare it to the spec. Only fix obvious problems (missing parts, parts floating, wrong colors, wrong scale, limbs disconnected from the body).

## Export
- Export each character as its own file: `./granny.glb` and `./child.glb` (select only that character's hierarchy, +Y up, apply modifiers).
- Stop after that. Don't polish or add anything.
