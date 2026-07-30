# Lue's Treatie Run! — Design Document

A level-based auto-runner browser game starring Lue. Chrome-dino-style movement, but seven finite themed levels that each end at a door: Backyard → Inside a House → Park → Beach → On a Mountain → In a Casino → Night City.

Per-level obstacles and flyers (flying obstacle appears from level 2 on):

| Level | Solid obstacles | Breakable (white outline) | Flyer |
|---|---|---|---|
| Backyard | tennis-ball piles, sunflowers | zombies | — (static only) |
| Inside a House | turkey legs, pancake stacks (w/ syrup + butter) | glasses of milk | parakeet |
| Park | water fountains, swingsets | hedges | blackbird |
| Beach | watermelon slices, crabs, sharks | sandcastles | seagull |
| On a Mountain | rattlesnakes, goats | cactus w/ pink flower | eagle |
| In a Casino | slot machines, claw machines | casino-chip piles | flying mixed drink |
| Night City | Starla (photo in Phase 4), alligators | T-rex | pigeon |

Breakable obstacles are drawn with a white outline so they're identifiable at a glance.

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
2. **`CONFIG`** — grouped and labeled: gravity, jumpVelocity, doubleJumpVelocity, jump input buffer + coyote time, per-level scrollSpeed / obstacle density / spawn intervals, mover speeds & amplitudes, fireball speed + cooldown + range, claw range + swing duration, i-frame duration, powerup spawn odds + min spacing, obstacle min-gap rules, hitbox forgiveness factor, score values, level lengths, level seeds.
3. **`PALETTES` + `SPRITES`** — named color palettes and 2D pixel-array constants (arrays of strings, one character per pixel indexing into the palette — compact and human-editable). Dog target: 32×32, ~12 colors, 2-frame run cycle + jump pose + swipe pose. Ships first as a crude placeholder array so the whole pipeline is exercised before real art exists. Powerup looks are palette swaps: alternate palettes applied to the same pixel arrays.
4. **`LEVELS`** — data-driven theme objects: name, sky/ground/parallax colors, allowed obstacle types, flyer type (sprite frames + palette + debris colors), decoration set. Seven themes, re-themeable by editing data only. Flyers are palette swaps of a shared bird sprite (parakeet/blackbird/seagull/eagle/pigeon) except the casino's cocktail-glass sprite.
5. **Sprite renderer** — bakes each (pixel array × palette) into an offscreen canvas once at load; draws scaled 3–4× with `imageSmoothingEnabled = false` for crisp pixels.
6. **Audio** — one `AudioContext`, created/resumed on first user gesture (iOS requirement). Each SFX is a small function of oscillators + gain envelopes: jump (square blip up), pickup (quick arpeggio), hit (noise burst), fireball (saw sweep), door (two-tone chime). No music.
7. **Input** — unified via Pointer Events. Desktop: Space = jump, X = action (F alias). Mobile: tap anywhere on canvas = jump; persistent DOM action button (bottom-right, large hit target) = action. Jump buffering + coyote time from CONFIG so touch feels fair.
8. **Entities** — plain objects with update/draw functions: player, static obstacles (destructible / solid / jump-only), movers (per-theme flyers at varying heights, levels 2–7), pickups, fireballs, particles.
9. **Level generator** — seeded PRNG (mulberry32) with a fresh random seed per attempt. Places obstacles along the level respecting min-gap rules derived from jump physics at that level's scroll speed (no unwinnable sections); places powerups with guaranteed minimum spacing so runs aren't luck-dead.
10. **Game state machine** — `TITLE → PLAYING → DOOR_ANIM → LEVEL_COMPLETE → (next level | VICTORY)`, plus `DEAD → retry`. The door animation is pure flavor, not tied to the claw powerup: control is removed, the dog stops at the door, unlocks/opens it with the claw on her paw, walks through, fade out.
11. **Main loop** — `requestAnimationFrame` render + fixed-timestep update (accumulator, ~120 Hz) with delta clamping, so physics feels identical on 60/90/120 Hz displays.
12. **Display** — fixed internal resolution 960×540 (16:9), scaled to fit any screen with letterboxing.

## Key Mechanics

- **Damage (Mario-style)**: no powerup + hit = death → death screen → restart current level, infinite retries, no lives counter. Powerup + hit = lose the powerup, brief i-frames (blinking), keep running. A powerup is effectively 1 extra hitpoint.
- **Powerups** (one held at a time; new pickup replaces current): **Fireball** (action fires a projectile that destroys destructibles at range), **Double-Jump** (second jump mid-air; action does nothing), **Claw** (action does a short-range swipe). Dog visibly changes per powerup (palette swap at minimum) plus a HUD icon.
- **Obstacles**: destructibles (killed by fireball or claw), solids, and jump-only obstacles so no powerup trivializes the game. Flyers are destructible. Level 1 is static-only; levels 2–7 add per-theme movers. Scroll speed and density escalate per level via CONFIG (all per-level arrays have 7 entries).
- **Score**: distance ticks + destruction bonuses, accumulated across the run. Score snapshots at level start and restores on death-retry. High score in localStorage.
- **HUD**: score, level indicator, held-powerup icon.
- **PWA-ready**: everything is inline in one file, so the Phase 4 manifest + service worker are purely additive — no refactor.

## Build Phases (each ends playable)

**Phase 1 — Core loop**: index.html skeleton, CONFIG, canvas scaling/letterbox + rotate overlay, fixed-timestep loop, sprite pipeline with placeholder pixel-array dog, input (keyboard + tap + action button present but inert), player physics, seeded static-obstacle generation for one test level, AABB collision, death/retry, distance score. *Playable: run, jump, die, retry.*

**Phase 2 — Damage + powerups + HUD**: three powerups with pickup/replace logic and palette swaps, fireball projectiles + cooldown, claw swipe, double jump, destructible vs solid vs jump-only obstacles, i-frames, powerup min-spacing placement, full HUD, localStorage high score.

**Phase 3 — Levels + screens** (later expanded from 3 to 7 levels): data-driven themed levels with parallax code-drawn backgrounds, per-level difficulty escalation, per-theme movers from level 2 on, door + exit animation (locksmith-paw sequence), title screen with level select, level-complete / death / victory screens, progress persistence.

**Phase 4 — Art, sound, polish**: real 32×32 dog sprite from photos (run cycle, jump, swipe, ~12-color palette + powerup palette swaps), obstacle/pickup/door sprites, Web Audio SFX wired to events, PWA manifest + service worker, particles/juice, CONFIG tuning pass.

## Verification (per phase)

- Load `index.html` in a browser; check the console for errors.
- Mobile emulation (375×812): rotate overlay appears in portrait; letterboxing correct; tap-to-jump and action button work; no page scroll or zoom during play.
- Desktop: Space/X/F keys, smooth 60 fps, death/retry loop, powerup pickup/loss, level transitions, localStorage survives reload.
- Generator fairness: stress-generate many random layouts per level and assert gap/spacing/height constraints hold on all of them; solvability spot-check at each level's max scroll speed.
- Real-device testing on an actual phone at each phase checkpoint (serve over LAN or open the file directly).
