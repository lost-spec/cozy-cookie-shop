Respond with tool calls only until finished. Do not write out reasoning or plans.

# Task: Model two small kraft paper bakery cookie bags in Blender

Use the **blender_modeling** skill for all Blender work. This is a new chat with no context, so this spec is the only source of truth. Do not look for or analyze any reference image; everything is described below. Stylized, soft, hand-painted-looking low-poly game asset.

## Efficiency rules (strict)
- Think briefly. No long planning, no alternatives, no second-guessing.
- Write the whole scene as ONE Python script (under about 250 lines, using helper functions) and run it in ONE execute call. Fix errors only if the script fails, and only patch the failing part.
- Max 2 viewport screenshots total (one after the first run, one after a fix pass if needed). Then stop.
- No asset downloads, no addons. Use only primitives, bmesh, curves and procedural materials.
- Add NOTHING beyond the objects listed. No table, no props, no extra decoration.
- Don't ask questions; if unsure, pick the simplest option. Final reply: 2 lines max.

## Best way to build it (follow this, don't explore other methods)
1. Use the `bpy.data` API and `bmesh` for geometry. Avoid `bpy.ops` except `bpy.ops.export_scene.gltf` and the render setup, because ops fail on missing context.
2. Write these helpers first and reuse them for everything:
   - `mat(name, color_hex, rough)` creates a Principled material
   - `make_bag_body(open_top)` builds the bag body mesh
   - `make_cookie()` builds one cookie, then `copy()` it for the second one with a different rotation (do not rebuild it)
   - `make_tag_and_twine()` builds the tag and bow, then copy it for the second bag
3. **Bag body:** create a cube with bmesh, scale it to 0.14 x 0.09 x 0.17 m and subdivide it with 6 cuts. Then move the vertices with simple formulas based on height `t = z / 0.17`:
   - taper: multiply the X and Y of each vertex by `1.0 - 0.08 * t`
   - puff: push the front and back faces out by `0.008 * sin(pi * t)`
   - gusset: on the two side faces, pull the vertices near the vertical center line inward by 0.012 m
   - Add a Subdivision Surface modifier (level 1) and a Displace modifier with a clouds texture (strength 0.003) for the wobbly hand-made look. Smooth shading.
4. **Sealed top:** pinch the top face (scale the top ring's Y to about 0.2 of its depth so it is nearly flat). Then add the flap as a separate bevelled box (0.14 x 0.012 x 0.035 m) laid over the front top and tilted about 3° on Z. Don't simulate any cloth or folding.
5. **Open top:** delete the top face, extrude the top edge ring up by 0.015 m and scale it out by 1.05 for the rolled cuff, then add a Solidify modifier (0.002 m). Use a second material slot for the inside.
6. **Painted color look:** one material with a ColorRamp driven by the object's generated coordinates (Texture Coordinate > Generated > Separate XYZ, then X added to Z). Left or top is light #E3B77A, middle is #D0A06A, right or bottom is dark #A9774A. Mix a little low-contrast Noise texture into the color. Do not paint textures by hand.
7. **Tag and twine:** the tag is a bevelled flat box. The twine is Bezier curves with `bevel_depth` 0.0015 (two loops, a tiny knot, two tails). Parent both to the bag.
8. **Cookie icing:** 3 Bezier curves with a bevel depth of 0.001 m. Shards are small icospheres with random non-uniform scale in a loop (about 12, seeded random). One flattened UV sphere for the petal.
9. **Materials, lights, camera, render settings and export:** all in the same script, at the end. Place the bags first, then the cookies, then the camera, and run it once.
10. After the script runs, take the one screenshot, check against the spec, and only patch real problems (missing parts, parts floating or clipping, wrong colors).

## Setup
- Delete the default cube, light and camera. Units: 1 Blender unit = 1 meter.
- Make TWO bags side by side, 0.35 m apart: `Bag_Sealed` on the left, `Bag_Open` on the right. Both stand upright at Z = 0.
- Bevel hard edges slightly (0.004 m). Matte and soft everywhere.

## What the bag looks like (shared by both)
A classic brown paper bakery bag, a plump, slightly puffy, hand-made-looking bag.
- Size: about 0.14 m wide, 0.09 m deep, 0.17 m tall (roughly 5:6 width to height). Flat rectangular bottom.
- Shape: slightly wider at the bottom and gently narrower at the top, with softly rounded vertical edges and a slightly wobbly outline. The sides bulge out a little, as if filled.
- Side gusset: the side faces have a soft V crease down the middle (inset about 0.012 m), with a diagonal fold at the bottom corners.
- Material: warm kraft paper, roughness 0.9.
  - Main front color: warm tan-golden #D0A06A.
  - Upper-left of the front is lighter golden #E3B77A, fading softly toward the right.
  - Right gusset side and bottom edge are darker and shaded, #A9774A.
  - Very faint pinkish-mauve smudges (#B58A7A) for a painted feel. Very subtle paper-grain bump only.
- The light comes from the upper left, so the left of the front is the brightest.

## Version 1: Bag_Sealed
- The top is folded over once as a single thick rounded flap, about 0.035 m tall, laid forward over the front. Slightly puffy, about 0.005 m thick, a little tilted (the right end slightly higher than the left).
- Cream paper tag: flat rectangle 0.045 x 0.03 m, color #EFE4C8, matte, at the center of the fold, half on the flap and half on the bag front, rotated about 5°.
- Twine bow: thin twisted baker's twine (color #8F8570) tied in a small bow at the top center of the tag. Two loops (about 0.03 m wide in total), a tiny knot, and two short tails hanging down over the tag, one longer than the other.
- Nothing is visible inside.

## Version 2: Bag_Open
- Same body, but open: no folded flap. A soft rolled cuff about 0.015 m tall around a wide, slightly uneven opening. Wall thickness 0.002 m. The inside is darker kraft #B08B5E.
- 2 cookies lean against each other inside, sticking out by about 1/3 of their height, with the icing faces turned toward the front.
- The same tag and twine bow hang loosely over the front just below the cuff, with a small knot (not tied around the bag).
- Optional: a small crumpled sheet of #F6EBDD parchment paper peeking out between the cookies and the bag wall.

## Cookie (Bag_Open only)
Round pistachio-rose cookie, about 0.07 m across and 0.012 m thick:
- Cylinder with 48 segments, softly bevelled top edge, slightly wobbly outline.
- Color: matte chalky sage pistachio green #A9B77B on top, warm golden-yellow #E0B65A on the upper-left, thin toasted golden-brown #C0893C edge ring. Roughness 0.75.
- Icing: 3 thin parallel diagonal ribbons of pale pink-peach #EFCDBB, slightly glossy (roughness 0.25), lying on the top surface.
- Toppings: about 12 tiny angular pistachio shards (#B9C62C) clustered at the center, plus 1 dried rose petal bud (#B8456E) on one cookie.
- Tilt the cookies about 15° and -20°. Make sure they sit inside the bag and don't pass through the walls.

## Lighting and camera
- One soft large area light from the upper left, plus a low warm-white world light. EEVEE, AgX tone mapping, no heavy bloom.
- Background: a large flat matte mauve-brown plane #A5806C under and behind the bags.
- Camera: perspective, about 50 mm, at the height of the bag's upper half, slightly in front, with a 3/4 view from the front-left (you see the front face and a bit of the right gusset), framing both bags with a small margin. Render 1920x1080.

## Finish
- Name the objects: Bag_Sealed, Bag_Open, Cookie_A, Cookie_B, Tag, Twine. Parent each bag's parts to an empty with the bag's name.
- Export each bag as its own file: `./bag_sealed.glb` and `./bag_open.glb` (+Y up).
- Stop after that. Don't polish or add anything.
