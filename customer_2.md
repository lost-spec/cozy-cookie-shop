Respond with tool calls only until finished. Do not write out reasoning or plans.

# Task: Model two more separate low-poly customer characters in Blender: a man with glasses and a guitarist

Use the **blender_modeling** skill for all Blender work. This spec is the only source of truth; do not look for or analyze any reference image. These are customers for a cozy cookie shop game, and they must match two characters already made (a granny and a child): clean, stylized, chunky low-poly with flat-shaded facets, simple readable shapes, soft matte colors, consistent proportions. They must not look like generic AI-generated models.

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
   - `part(kind, name, loc, scale, material, parent, rot=(0,0,0))` creates a UV sphere (8 segments, 6 rings), a cylinder (8 vertices), a cone, a torus or a box. It applies the scale, sets flat shading, adds a Bevel modifier (width 0.01, 1 segment), links it to the collection and parents it.
   - `limb(name, top_loc, length, r_top, r_bottom, material, parent)` makes a tapered 8-sided cylinder whose **origin is at the top joint** (shoulder or hip), so it can be rotated and animated later.
   - `build_person(root_name, height, skin, shirt, pants, shoes)` builds the common body (head, neck, torso, 2 arms, 2 legs, hands, shoes, eyes, nose, cheeks), and returns the root empty. Both characters use it, then add their own extras.
3. Build everything from simple parts only. Head is a slightly squashed sphere, torso is a tapered cylinder, limbs come from `limb()`. No subdivision surface and no realistic anatomy.
4. Faces are tiny: 2 small dark sphere eyes (r 0.012 m), a tiny sphere nose, 2 flat pink cheek discs, and a small thin dark curve for the mouth. This avoids uncanny faces.
5. Each character's origin is on the floor between the feet, facing -Y (front), standing upright in a relaxed A-pose (arms slightly away from the body, about 10°).
6. Camera, lights, background and export go at the end of the same script, then run once.

## Setup
- Delete the default cube, light and camera only. If other characters (Granny, Child) already exist in the scene, don't touch them. Place the new characters at Y = -3 so they don't overlap them, and aim the camera at the new ones.
- Units: 1 Blender unit = 1 meter. Place `Man` at X = -0.7 and `Guitarist` at X = +0.7, both at Z = 0, facing the camera.
- Each character is its own empty hierarchy and its own collection, so they can be exported separately.

## Character 1: Man with glasses (about 1.75 m tall)
Proportions: slightly stylized, head about 1/6 of the total height, average build, relaxed and friendly stance.
- Skin: warm light-olive #D8A77E. Rosy cheeks #DE9488.
- Head: squashed sphere, width 0.2 m, height 0.23 m, with a slightly squarish jaw (scale the lower half in X a bit). Small nose.
- Hair: short neat dark-brown #3E2B22, a dome cap over the skull with a slightly swept side part (one flattened box on top).
- Glasses: two rectangular rounded frames (flattened boxes with a hole look, or thin box outlines made from 4 thin boxes each), about 0.045 x 0.032 m, in dark charcoal #4A4543, with a small bridge and two thin temple arms going back to the ears. Put a very slightly transparent pale blue lens plane inside each frame (alpha 0.25).
- Torso: a tapered cylinder wearing a cream button-up shirt #F1E4D3, a small collar (two small flattened boxes), 4 tiny round buttons down the front, and sleeves rolled up to the elbow (the forearms are skin color).
- Vest: a sweater vest over the shirt in dusty pistachio green #A9B77B (a slightly larger tapered cylinder over the torso with a V-neck notch, no sleeves).
- Pants: straight-leg trousers in charcoal #4A4543 (two tapered cylinders), thin brown belt #6B4A3A at the waist with a tiny copper buckle #B8743A.
- Shoes: simple brown leather shoes #6B4A3A (boxes with rounded bevels).
- Prop: a small briefcase, 0.32 x 0.09 x 0.24 m, in kraft brown #B07A4A with a thin handle (half torus) and two copper clasps, held in the right hand, hanging down. The left arm hangs relaxed.

## Character 2: Guitarist (about 1.8 m tall)
Proportions: slim, slightly lanky, relaxed, with a slight slouch (tilt the upper torso about 4° forward). Head about 1/6.5 of the total height.
- Skin: warm brown #B67F5B. Rosy cheeks #C9776A.
- Head: squashed sphere, width 0.19 m, height 0.22 m. Light stubble: a darker (#8A5A44) half-sphere shell on the lower face, very subtle.
- Hair: shoulder-length wavy hair, dark-brown #3A2A24: a dome cap over the skull plus a back mass of 3 stacked flattened spheres down to the shoulders, and 2 side pieces that cover the ears. Tied half-up with a tiny copper bead #B8743A.
- Beanie: a slouchy knit beanie in dusty mauve #A38A82 (a squashed dome over the top of the head, with a folded cuff ring in cream #F1E4D3 around the base).
- Torso: a tapered cylinder with a band t-shirt in warm cream #F1E4D3, a simple blocky circle print on the chest in pistachio green #A9B77B (flat disc, no text). Over it an open jacket in charcoal #4A4543: two front panels (flattened boxes) and sleeves from `limb()`, with a copper zipper strip #B8743A along each front edge.
- Pants: slim jeans in washed dusty blue #7C8FA3 (two tapered cylinders), with a small frayed-knee patch on the left leg in cream (a small flat box).
- Shoes: worn high-top sneakers in dark charcoal #4A4543 with cream soles #F1E4D3 and a cream toe cap.
- Guitar: an acoustic guitar slung on the back at an angle of about 25° (the neck points up and to the right):
  - Body: two overlapping squashed cylinders (a smaller upper bout and a bigger lower bout, 12 vertices each), 0.34 m long total, 0.09 m thick, warm honey wood #D9A15C, with a dark circle sound hole #3A2A24 and a thin cream rim ring.
  - Neck: a thin box 0.38 m long in dark wood #6B4A3A, with a headstock (small box, slightly angled) in the same wood and 6 tiny copper tuning pegs #B8743A.
  - Strap: two thin flat boxes in mauve #A38A82 crossing the chest diagonally from the right shoulder to the left hip.
- Arms hang relaxed. The right hand rests on the strap.

## Materials and finish
- Flat-shaded polygons with Bevel modifiers only. All materials matte (roughness 0.8), no shiny parts except the glasses lenses.
- Name the parts clearly (Head, Hair, Glasses, Torso, Arm_L, Arm_R, Leg_L, Leg_R, Guitar, Briefcase, and so on) and parent them to the root empties named `Man` and `Guitarist`.

## Lighting and camera
- One soft large area light from the upper left in front, plus a low warm-white world light. EEVEE, AgX tone mapping, no heavy bloom.
- Background: a large flat matte mauve plane #A5806C behind the characters.
- Camera: orthographic, front view, at chest height, framing both characters side by side with a small margin. Render 1920x1080.
- Take ONE screenshot and compare it to the spec. Only fix obvious problems (missing parts, floating parts, wrong colors, wrong scale, limbs disconnected from the body, guitar passing through the body).

## Export
- Export each character as its own file: `./man.glb` and `./guitarist.glb` (select only that character's hierarchy, +Y up, apply modifiers).
- Stop after that. Don't polish or add anything.
