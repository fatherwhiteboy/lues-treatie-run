# PLAN.md — progress tracker

Status as of **2026-08-10**, at tag **v1.5** (`30d5500`). Compared `index.html`
against `DESIGN.md`. Update this file at the end of every work session.

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
- **Living world (all 10 levels)**: doghouse/fence cat/tennis balls; couch/
  TV/bowls/lava lamp; kite/birds/butterflies; sailboats/umbrella/shells/sun;
  whale/dolphins/turtles/crabs/neon reef + scuba exhaust bubbles; palm
  oasis/camel/desert sun; clouds/soaring birds/rainbow/unicorns with rainbow
  manes; falling snow/snowmen/reindeer with red-nosed lead; dice/cards/chip
  stacks; cratered moon + neon signs. Engine support: `celestial` (fixed
  sun/moon), `weather` ambient particles, multi-color bush painter.
- **Starla** sprite (Night City obstacle) via the obstacle `sprite:` field.
- **Sound**: Web Audio synth SFX on every event; unlocks on first gesture.
- **PWA**: runtime-generated manifest + icon from Lue's sprite (installable
  over https). No service worker by design (single-file; no offline cache).
- **Art pipeline**: `tools/export-sprites.ps1`, `tools/import-sprite.ps1`
  (jitter-quantizing PNG→grid), `tools/embed-victory.ps1`; specs in
  `ART-SPEC.md`.

## Half-done / placeholder

- **Obstacle art**: all 22 obstacle types render as labeled colored blocks
  (white rim + crack on breakables). Only Starla has a real sprite. The
  `sprite:` field + import pipeline are ready; this is drawing work, not
  engineering.
- **Flyer art**: five species are palette swaps of one 10×6 bird; the
  drink/snake/fish/snowball sprites are quick placeholders. Functional,
  but a target for the same art pass.
- **Derived Lue poses**: run1/jump/swipe/pick0/pick1/eat0/eat1 are Claude-
  derived from the owner frames — usable, but the owner may want to redraw
  any of them (drop PNGs in `art/`, exact names in ART-SPEC.md).
- **Wings/pickups/accessory art**: Claude-drawn pixel art, approved so far
  but owner-redrawable through the same pipeline.

## DESIGN.md drift (doc fixes owed)

- Endless speeds say 340→700; implementation is 380→720, and the campaign
  speed gradient isn't documented.
- Architecture §4 says "seven themes" (there are 10); §3 says the dog art
  "ships as a crude placeholder" (it's owner art now); §10's state machine
  is missing HOWTO / LEVEL_SELECT, the death→level-select path, and the
  land-before-door rule.
- The Phase 4 paragraph lists as "remaining" several things now done
  (sit/pick/eat poses, victory photo, wings). Only obstacle/flyer art
  genuinely remains.
- Nothing in the doc yet about: powerup outfits, world-inhabitant layers,
  celestial/weather systems, scuba bubbles, death taunts, Christmas hat.

## What's next

1. **Art pass on obstacles + flyers** (the last placeholder tier) — owner
   draws or Claude derives; sizes per type ≈ collision box ÷ 3.
2. **Refresh DESIGN.md** per the drift list above.
3. **Host over https** to make the PWA installable on the niece's device;
   real-device playtest of the v1.5 difficulty curve.
4. Optional/backlog: mute toggle, offline service worker (would add a second
   file — needs an explicit decision), further tuning from niece feedback.
