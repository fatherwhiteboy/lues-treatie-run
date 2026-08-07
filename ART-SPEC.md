# Lue's Treatie Run! — Art Spec

How to draw sprites for the game. Deliver **PNG files** (details at the
bottom) and Claude converts them into the game's pixel-array format
automatically — or edit the text arrays in `index.html` directly.

## The golden rules (apply to everything)

- **Pixel-exact canvases** — a 32×32 sprite is a 32×32 px image. The game
  scales it up 3× with crisp edges (no smoothing).
- **No anti-aliasing, no soft brushes, no partial transparency.** Every
  pixel is either a flat color or fully transparent. Use a *pencil* tool,
  not a brush. (Aseprite, Piskel [free, in-browser], or GIMP's pencil all
  work.)
- **Transparent background** — not white.
- **Facing RIGHT** — the direction Lue runs.
- **Flat colors only, limited count** — see per-sprite budgets below. Each
  distinct color becomes a palette "slot" the game can recolor.

## Lue — 32×32 px (shows as 96×96 in game)

### Poses (one PNG each)

| File | Pose | Notes |
|---|---|---|
| `dogRun0.png` | gallop, legs extended | 2-frame run cycle, swaps every 0.09s |
| `dogRun1.png` | gallop, legs gathered | pair with dogRun0 |
| `dogJump.png` | airborne, legs tucked | |
| `dogSwipe.png` | front paw raised, claw swipe | claw marks are drawn by the game — just the pose |
| `dogSit.png` | sitting upright | used at the door |
| `dogPick0.png` | sitting, paw raised to the lock | lock-picking jiggle frame A |
| `dogPick1.png` | same, paw shifted down a few px | jiggle frame B |
| `dogEat0.png` | lying/leaning down over a bone | victory screen chew frame A (bone itself is a separate sprite — don't draw it) |
| `dogEat1.png` | same, head lowered a bit more | chew frame B |

### Placement rules

- **Ground poses** (run, swipe, sit, pick, eat): paws/body must touch the
  **bottom row** of the canvas — that edge sits on the ground line. If the
  feet stop a few rows short, she floats.
- **Jump**: free placement, roughly centered.
- **Head in the upper-right area if possible** — the scuba visor and snow
  hat overlays currently expect the eyes around pixel columns 19–29,
  rows 7–10. If your drawing differs, that's fine; the overlay positions
  are two numbers each and get re-tuned to your art.
- **Hitbox**: the game trims 22% off each side of the 96×96 box for
  collisions. Keep her body mass in the middle ~56px; thin bits sticking
  out (ears, nub) are fine and don't affect gameplay.

### Color budget: ~12 colors max, shared across ALL Lue poses

Use the same palette in every pose. Suggested slots (from the photos):
outline, tan coat, tan shading, cream muzzle/belly, dark saddle, saddle
grizzle, white chest/paws, black (nose/eyes), inner ear, tongue pink.

**Why it matters**: holding a powerup recolors Lue (fire = red, double
jump = blue, claw = purple) by swapping the palette. Every color you use
gets a counterpart in those palettes — so 12 tidy slots recolor cleanly,
while stray one-off colors won't.

Don't draw the powerup gear into the poses: butterfly wings, scuba visor
+ tank, and the snow hat are separate overlays the game layers on.

## Starla — 20×18 px (shows as 60×54 in game)

- One PNG: `starla.png`, lying down, facing right (she's a Night City
  obstacle Lue jumps over).
- Bottom row = ground. Size can go up to ~24×20 if needed; the collision
  box stays 60×52 regardless.
- Own palette, ~6–8 colors (black fluff, grizzle highlight, white blaze
  and chest, tan points, nose). No recoloring, so no slot discipline needed.

## Butterfly wings (double-jump powerup)

- Two PNGs: `wings0.png` (flap up), `wings1.png` (flap down), **16×16 px**
  (shown at 4× = 64×64).
- Sheer translucent red with darker red edges and silver sparkles (the
  game supports semi-transparent pixels for these — soft alpha is OK
  *here only*, unlike the dog sprites). Drawn BEHIND Lue at her
  shoulders, so the right side of the wing canvas is covered by her body.

## Costume overlays (scuba gear, snow hat)

- `gearScuba.png` and `gearSnowHat.png`, **32×32 px** — the SAME canvas
  as Lue, drawn directly over her sprite at the same position.
- To redraw: open a Lue pose in Piskel, add the gear on a layer above
  her, then export ONLY the gear layer as the 32×32 PNG. Perfect
  alignment guaranteed.
- Semi-transparent pixels allowed (the scuba visor glass uses them).

## Other sprites, if you get ambitious (each has its own palette)

| File | Size | What |
|---|---|---|
| `bone.png` | 12×4 | the victory treat |
| `bird0/1.png` | 10×6 | flyer, recolored per level (parakeet/blackbird/seagull/eagle/pigeon) — keep body one slot |
| `drink0/1.png` | 10×10 | casino flying cocktail |
| `snake0/1.png` | 12×6 | desert flyer |
| `fish0/1.png` | 12×6 | underwater flyer |
| `snowball0/1.png` | 8×6 | snow day flyer |
| pickups `puFire/puDouble/puClaw.png` | 12×12 | powerup icons (also shown in HUD) |
| obstacles | ~11×8 up to ~32×30 px | any of the 22 obstacle types; sizes should roughly match each type's collision box ÷ 3 (ask and Claude will list exact sizes per obstacle) |

## Delivering

1. Save PNGs into `C:\Drew\Runner\art\` with the exact names above.
2. Tell Claude — a script reads the pixels and regenerates the game's
   palette + arrays exactly (no eyeballing).
3. Also still needed: the victory photo — save the barking picture as
   `C:\Drew\Runner\victory.jpg` and it gets inlined into the game.

Checklist per file before handing off:
- [ ] exact canvas size (e.g. 32×32), not scaled up
- [ ] transparent background
- [ ] no anti-aliasing / soft edges / semi-transparent pixels
- [ ] Lue faces right; ground poses touch the bottom row
- [ ] same ≤12-color palette across all Lue poses
