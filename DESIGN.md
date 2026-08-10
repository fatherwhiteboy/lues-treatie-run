# Lue's Treatie Run! — Design Document

A level-based auto-runner browser game starring Lue. Chrome-dino-style movement, but ten finite themed levels that each end at a door: Backyard → Inside a House → Park → Beach → Underwater → Egyptian Desert → On a Mountain → Snow Day → In a Casino → Night City (always last).

Per-level obstacles and flyers (flying obstacle appears from level 2 on):

| Level | Solid obstacles | Breakable (white outline) | Flyer | Costume |
|---|---|---|---|---|
| Backyard | tennis-ball piles, sunflowers | zombies | — (static only) | |
| Inside a House | turkey legs, pancake stacks (w/ syrup + butter) | glasses of milk | parakeet | |
| Park | water fountains, swingsets | hedges | blackbird | |
| Beach | watermelon slices, crabs, sharks | sandcastles | seagull | |
| Underwater | coral, wrecked ships | old-school divers (bubble helmet) | fish | scuba gear |
| Egyptian Desert (pyramids behind) | ankhs, sarcophagi | mummies | snakes | |
| On a Mountain | rattlesnakes, goats | cactus w/ pink flower | eagle | |
| Snow Day | snow shovels, snowmen | yeti | snowballs | christmas hat |
| In a Casino | slot machines, claw machines | casino-chip piles | flying mixed drink | |
| Night City | Starla (photo in Phase 4), alligators | T-rex | pigeon | |

Costumes are per-theme pixel-sprite overlays (`dogGear`) on Lue's own 32×32 canvas, drawn over her in any powerup palette: a scuba visor + air tank (Underwater) and a christmas hat with a silver pompom and a twinkling string of lights (Snow Day).

Breakable obstacles are drawn with a white outline so they're identifiable at a glance.

**Endless mode** (unlocked permanently by beating all 10 levels; own localStorage flag): terrain generates on the fly a few screens ahead of the camera using the same fairness rules, difficulty ramps over time (speed 380→720 px/s — starting at level-1 speed and capping at level-10 speed; tightening gaps, more/faster flyers — all in the CONFIG `endless*` group), and the theme cycles through all ten levels every 30 s (each segment uses its theme's obstacles, flyer, and costume). No door — the run ends only on death. Keeps a separate persisted best score (`ENDLESS BEST`) so it doesn't swamp the campaign high score. Launched from a dedicated button under the level-select cards; retry after death restarts the endless run.

## Hard Constraints

- **One file**: `index.html`. Vanilla HTML/CSS/JS with canvas. No frameworks, no build step, no external files or dependencies.
- All graphics are **code-drawn pixel arrays**; all sound is **Web Audio synth**. No asset files.
- Runs well on desktop and mobile (Android + iOS) from day one.
- Every gameplay-feel number lives in one clearly labeled `CONFIG` object at the top of the script, for hand-tuning.

## Confirmed Design Decisions

- **Randomized layouts** (revised from the original fixed-seed decision, at the user's request for replayability): every attempt — including a retry after death — rolls a fresh random seed and generates a new layout. The seeded PRNG pipeline is unchanged, and the rolled seed is kept on the level object so a specific layout can be reproduced for debugging. Fairness comes from generator rules (jump-clearable obstacle gaps, pickup min-spacing, guaranteed early pickup), which hold for any seed.
- **Progress persists**: highest unlocked level and high score are saved to localStorage. The title screen offers a level select of unlocked levels.
- **Portrait handling**: CSS rotate-prompt overlay (`@media (orientation: portrait)`) rather than orientation lock — `screen.orientation.lock()` requires fullscreen and is unsupported on iOS Safari. An opportunistic lock attempt on user gesture is fine where supported, silently ignoring failure.

## Architecture (top-to-bottom order inside `index.html`)

Everything hand-editable sits at the top of the `<script>`.

1. **HTML/CSS head** — viewport meta (`width=device-width, initial-scale=1, viewport-fit=cover, user-scalable=no`); full-viewport black page; centered letterboxed canvas; `touch-action: none` and `overscroll-behavior: none` on html/body/canvas (kills pinch-zoom, pull-to-refresh, overscroll bounce); `image-rendering: pixelated`; styles for the on-screen action button and the rotate-device overlay.
2. **`CONFIG`** — grouped and labeled: gravity, jumpVelocity, doubleJumpVelocity, jump input buffer + coyote time, per-level scrollSpeed / obstacle density / spawn intervals, mover speeds & amplitudes, fireball speed + cooldown + range, claw range + swing duration, i-frame duration, powerup spawn odds + min spacing, obstacle min-gap rules, hitbox forgiveness factor, score values, level lengths, door-animation timings, the `endless*` group.
3. **`PALETTES` + `SPRITES`** — named color palettes and 2D pixel-array constants (arrays of strings, one character per pixel indexing into the palette — compact and human-editable). Lue is 32×32 at scale 3, ~12 colors; **`dogRun0` and `dogSit` are owner-drawn** (canonical PNGs in `art/`, imported pixel-exact via `tools/import-sprite.ps1`) and the remaining poses are derived from them. Powerup looks are palette swaps (fire/double/claw recolors of every slot) plus outfit overlays.
4. **`LEVELS`** — data-driven theme objects: name, sky/ground/parallax colors, allowed obstacle types, flyer type (sprite frames + palette + debris colors), parallax layer list. Ten themes, re-themeable by editing data only. Flyers are palette swaps of a shared bird sprite (parakeet/blackbird/seagull/eagle/pigeon) except the casino cocktail, desert snake, underwater fish, and snow-day snowball sprites. Themes may also declare `dogGear` (costume overlay), `celestial` (fixed sun/moon), and `weather` (ambient particles).
5. **Sprite renderer** — bakes each (pixel array × palette) into an offscreen canvas once at load; draws scaled 3–4× with `imageSmoothingEnabled = false` for crisp pixels.
6. **Audio** — one `AudioContext`, created/resumed on first user gesture (iOS requirement). Each SFX is a small function of oscillators + gain envelopes: jump / double-jump blips, pickup arpeggio, hit and death, fireball sweep, claw slash, destruction, the door lock's click, and level-complete / victory fanfares. No music.
7. **Input** — unified via Pointer Events. Desktop: Space = jump, X = action (F alias). Mobile: tap anywhere on canvas = jump; persistent DOM action button (bottom-right, large hit target) = action. Jump buffering + coyote time from CONFIG so touch feels fair.
8. **Entities** — plain objects with update/draw functions: player, static obstacles (destructible / solid / jump-only), movers (per-theme flyers at varying heights, levels 2–10), pickups, fireballs, particles.
9. **Level generator** — seeded PRNG (mulberry32) with a fresh random seed per attempt. Places obstacles along the level respecting min-gap rules derived from jump physics at that level's scroll speed (no unwinnable sections); places powerups with guaranteed minimum spacing so runs aren't luck-dead.
10. **Game state machine** — `TITLE (splash) → HOWTO → LEVEL_SELECT → PLAYING → DOOR_ANIM → LEVEL_COMPLETE → (next level | VICTORY)`, plus `DEAD → retry` (or back to level select via button / ESC). If the level ends mid-jump, the door sequence holds until she lands. The door animation is pure flavor, not tied to the claw powerup: she trots up, sits, picks the lock with a raised claw (paw jiggle + click sparkle), the door swings open, she walks through, fade out.
11. **Main loop** — `requestAnimationFrame` render + fixed-timestep update (accumulator, ~120 Hz) with delta clamping, so physics feels identical on 60/90/120 Hz displays.
12. **Display** — fixed internal resolution 960×540 (16:9), scaled to fit any screen with letterboxing.

## Key Mechanics

- **Damage (Mario-style)**: no powerup + hit = death → death screen → restart current level, infinite retries, no lives counter. Powerup + hit = lose the powerup, brief i-frames (blinking), keep running. A powerup is effectively 1 extra hitpoint.
- **Powerups** (one held at a time; new pickup replaces current): **Fireball** (action fires a projectile that destroys destructibles at range), **Double-Jump** (second jump mid-air; action does nothing), **Claw** (action does a short-range swipe). Dog visibly changes per powerup (palette swap at minimum) plus a HUD icon.
- **Obstacles**: destructibles (killed by fireball or claw), solids, and jump-only obstacles so no powerup trivializes the game. Flyers are destructible. Level 1 is static-only; levels 2–10 add per-theme movers. Scroll speed gradients 380→720 px/s across the campaign (level 10 matches endless mode's cap) with density escalating via CONFIG (all per-level arrays have 10 entries).
- **Score**: distance ticks + destruction bonuses, accumulated across the run. Score snapshots at level start and restores on death-retry. High score in localStorage.
- **HUD**: score, level indicator, held-powerup icon.
- **PWA-ready**: everything is inline in one file; the manifest + icon are generated at runtime from Lue's sprite (installable over https; no service worker, so no offline cache — adding one would mean a second file and needs an explicit decision).

## Presentation & Flair

- **Powerup outfits**, drawn as overlays around the palette swap:
  - **Fire**: a flickering flame aura engulfing her — horizontal fire trail streaming behind while running, a rising-flame variant while sitting at the door.
  - **Double-jump**: sheer translucent red butterfly wings with silver sparkles (per the reference photo), drawn behind her; slow flap on the ground, fast in the air.
  - **Claw**: pink leopard-print mohawk, red lipstick, and pink stiletto heels that follow her paws in every pose (per-pose anchor table `PAW_HEELS`).
- **Living world**: every level's parallax includes inhabitants and props via procedural painters — doghouse/fence cat/tennis balls; couch/TV/food bowls/lava lamp; kite/birds/butterflies; sailboats/umbrella/seashells; whale/dolphins/sea turtles/floor crabs and a vibrant green–neon-yellow–coral reef; palm oasis and a camel; clouds/soaring birds/rainbow/unicorns with rainbow manes; snowmen and reindeer (red-nosed lead); dice/cards/chip stacks; cratered moon and neon signs. Foreground critters must be layered after (in front of) foliage or they vanish behind it.
- **Atmosphere**: `celestial` draws a fixed sun/moon without parallax; `weather: "snow"` spawns ambient falling snowflakes; scuba levels emit rising exhaust bubbles from Lue's regulator.
- **Screens & words**: splash → how-to-play (device-adaptive controls + powerup guide with real icons) → level select (2×5 cards + endless button). Death titles and level-complete lines are random picks from hand-editable lists (`DEATH_PHRASES`, `LEVEL_COMPLETE_PHRASES`). The victory screen shows the real photo of Lue mid-bark (inlined data URI, embedded via `tools/embed-victory.ps1`) behind the champion text, with pixel Lue chewing a bone in the corner.

## Build Phases (each ends playable)

**Phase 1 — Core loop**: index.html skeleton, CONFIG, canvas scaling/letterbox + rotate overlay, fixed-timestep loop, sprite pipeline with placeholder pixel-array dog, input (keyboard + tap + action button present but inert), player physics, seeded static-obstacle generation for one test level, AABB collision, death/retry, distance score. *Playable: run, jump, die, retry.*

**Phase 2 — Damage + powerups + HUD**: three powerups with pickup/replace logic and palette swaps, fireball projectiles + cooldown, claw swipe, double jump, destructible vs solid vs jump-only obstacles, i-frames, powerup min-spacing placement, full HUD, localStorage high score.

**Phase 3 — Levels + screens** (later expanded from 3 to 7 levels): data-driven themed levels with parallax code-drawn backgrounds, per-level difficulty escalation, per-theme movers from level 2 on, door + exit animation (locksmith-paw sequence), title screen with level select, level-complete / death / victory screens, progress persistence.

**Phase 4 — Art, sound, polish** (complete except the obstacle/flyer art pass): owner-drawn Lue (`dogRun0` + `dogSit` canonical, remaining poses derived) with powerup recolors and outfits; Starla sprite (obstacle types can declare `sprite:` for real art instead of placeholder blocks); accessories as pixel sprites (wings matched to the reference photo, scuba gear, christmas hat); Web Audio synth SFX wired to every event; runtime PWA manifest + icon; victory photo embedded; difficulty curve tuned (380→720 px/s). **Remaining**: real art for the 22 obstacle types and the flyer sprites — placeholder colored blocks / simple sprites today; the pipeline is ready (sizes and workflow in ART-SPEC.md, status in PLAN.md).

## Verification (per phase)

- Load `index.html` in a browser; check the console for errors.
- Mobile emulation (375×812): rotate overlay appears in portrait; letterboxing correct; tap-to-jump and action button work; no page scroll or zoom during play.
- Desktop: Space/X/F keys, smooth 60 fps, death/retry loop, powerup pickup/loss, level transitions, localStorage survives reload.
- Generator fairness: stress-generate many random layouts per level and assert gap/spacing/height constraints hold on all of them; solvability spot-check at each level's max scroll speed.
- Real-device testing on an actual phone at each phase checkpoint (serve over LAN or open the file directly).
