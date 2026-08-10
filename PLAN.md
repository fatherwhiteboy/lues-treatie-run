# PLAN.md — progress tracker

Status as of **2026-08-10**, at tag **v1.6** (obstacle + flyer art pass,
outline-bake fix, UFO cats, park/mountain background touches).
Update this file at the end of every work session.

## Built (done and verified)

- **Core game, complete**: physics (fixed timestep, buffered jumps, coyote
  time), 10 themed levels ending at Night City, Mario-style damage
  (powerup = armor), randomized fair layouts (seconds-of-travel gap rules,
  pickup spacing + guaranteed early pickup), score/high-score/unlock
  persistence, 380→720 px/s difficulty gradient with level 10 == endless top
  speed.
- **Endless mode**: on-the-fly generation, 30s theme cycling through all 10
  levels, separate persisted best, unlocked by beating the campaign.
- **Screen flow**: splash → how-to-play (device-adaptive) → level select
  (2×5 cards + endless button) → game; death screen with random taunts,
  retry, and a Level Select escape (button + ESC); level-complete random
  phrases; victory screen over the real embedded photo of Lue with the
  pixel eating-a-bone animation.
- **Door exit animation**: land-first-if-airborne, trot up, sit, lock-pick
  paw jiggle with claws, click sparkle, door opens, walk through.
- **Lue's art**: owner-drawn `dogRun0` and `dogSit` (pixel-exact import);
  the other 7 poses derived from them. Fire/double/claw palette recolors.
- **Powerup outfits**: claw = pink leopard mohawk + lipstick + heels that
  track her paws per pose; double = sheer red butterfly wings (flap rates
  differ ground/air); fire = flickering flame aura with a horizontal trail
  while running and a rising-flame variant while sitting.
- **Costumes**: scuba visor + tank (Underwater), Christmas hat with silver
  pompom and twinkling lights (Snow Day) — pixel sprites on Lue's canvas.
- **Living world (all 10 levels)**: doghouse/fence cats/tennis balls (every
  4th cat mid-UFO-abduction, on a 4-wide tile via the new per-layer `tileW`
  parallax option, 2026-08-10); couch/
  TV/bowls/lava lamp; kite/clouds/butterflies; sailboats/umbrella/shells/sun;
  whale/dolphins/turtles/crabs/neon reef + scuba exhaust bubbles; palm
  oasis/camel/desert sun; clouds/soaring birds/cloud-anchored
  rainbows/unicorns perched on the background peaks (moved off the
  foreground 2026-08-10); falling snow/snowmen/reindeer with red-nosed
  lead; dice/cards/chip
  stacks; cratered moon + neon signs. Engine support: `celestial` (fixed
  sun/moon), `weather` ambient particles, multi-color bush painter.
- **Starla** sprite (Night City obstacle) via the obstacle `sprite:` field.
- **Obstacle art (2026-08-10)**: all 30 remaining obstacle types drawn as
  pixel sprites (Claude-drawn; owner may redraw any via the usual pipeline).
  One palette per sprite, named after its type key; every sprite bakes with
  a 1px black outline; sizes ≈ collision box ÷ 3 at scale 3; collision boxes
  untouched. Verified in-game across all 10 themes (ground contact, breakable
  white rim, background contrast). Contrast fixes made along the way: gold
  slot machine (was magenta-on-magenta), blue-rimmed milk glass with a straw,
  vertical-stream fountain, and reworked crab/rattlesnake/goat silhouettes.
- **Flyer art (2026-08-10)**: all five flyer species redrawn with 2-frame
  animation. The shared bird is now 13×8 with head/beak/eye, a flapping
  wing, and belly/wing/tail palette slots — so parakeet, blackbird,
  seagull, eagle, and pigeon each get real per-species coloring. New
  martini-with-olive cocktail (splash droplets alternate sides), gliding
  hooded cobra (wave humps shift between frames), orange fish with
  white eye and forked tail (fins alternate), and a spinning blue-shaded
  snowball. Hitboxes unchanged (fixed 32×18 in `update`).
- **Outline edge-clip fix (engine)**: art pixels touching the rows-grid
  edge used to lose their baked outline on that side (snowball "bracket"
  artifact; shark/zombie/etc. had no top rim). `bakeVariant` now pads
  outlined sprites by 1 transparent cell on every side before baking, so
  every sprite gets a full rim with no hand margins needed. All sprite
  draw sites are centered or bottom-aligned so the +2-cell canvas is
  position-neutral — except the victory bone (top-left anchored), whose
  offsets were shifted −4px each to compensate.
- **Tooling fix**: `tools/export-sprites.ps1` palette hashtables are now
  case-SENSITIVE — PowerShell's default case-insensitive keys silently merged
  palette slots like `p`/`P`, exporting wrong colors for any palette that
  uses both cases of a letter.
- **Sound**: Web Audio synth SFX on every event; unlocks on first gesture.
- **PWA**: runtime-generated manifest + icon from Lue's sprite (installable
  over https). No service worker by design (single-file; no offline cache).
- **Art pipeline**: `tools/export-sprites.ps1`, `tools/import-sprite.ps1`
  (jitter-quantizing PNG→grid), `tools/embed-victory.ps1`; specs in
  `ART-SPEC.md`.

## Half-done / placeholder

- **Obstacle + flyer sprites are Claude-drawn** (art pass complete
  2026-08-10): owner may redraw any of them — drop a PNG in `art/`
  (obstacles ≈ collision box ÷ 3; flyer frames at their grid sizes)
  and import as usual.
- **Derived Lue poses**: run1/jump/swipe/pick0/pick1/eat0/eat1 are Claude-
  derived from the owner frames — usable, but the owner may want to redraw
  any of them (drop PNGs in `art/`, exact names in ART-SPEC.md).
- **Wings/pickups/accessory art**: Claude-drawn pixel art, approved so far
  but owner-redrawable through the same pipeline.

## DESIGN.md drift

**Resolved 2026-08-10** — DESIGN.md refreshed: speeds corrected to 380→720
with the campaign gradient documented, ten themes, owner-art status, full
state machine (HOWTO / LEVEL_SELECT / death→select / land-before-door), a
new "Presentation & Flair" section (powerup outfits, living-world layers,
celestial/weather/bubbles, phrase lists, victory photo), and the Phase 4
paragraph now lists only the obstacle/flyer art pass as remaining.

## What's next

1. **Host over https** to make the PWA installable on the niece's device;
   real-device playtest of the v1.5 difficulty curve.
2. Optional/backlog: mute toggle, offline service worker (would add a second
   file — needs an explicit decision), further tuning from niece feedback.
