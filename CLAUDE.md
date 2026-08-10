# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

"Lue's Treatie Run!" — a level-based auto-runner starring the owner's dog. The
entire game is **one file, `index.html`** (~340KB): vanilla JS + canvas, no
frameworks, no build step, no external runtime files. Images are inlined as
data URIs; the PWA manifest + icon are generated at runtime; all SFX are Web
Audio synth. **Preserve the single-file constraint** — never add a runtime
asset file or CDN reference.

`DESIGN.md` is the living design doc (keep it updated when gameplay/scope
changes). `ART-SPEC.md` documents sprite sizes/format for the owner, who draws
art themselves. The owner also hand-edits `index.html` directly (phrase lists,
art tweaks) — if an Edit anchor fails, Grep for the current text instead of
assuming your remembered version.

- **Read DESIGN.md and ART-SPEC.md before starting work.**
- **Track progress in PLAN.md — update it at the end of every work session.**

## Commands

There is no build, lint, or test framework. Run the game by opening
`index.html` in a browser.

Art pipeline (PowerShell, run from repo root):

```bash
pwsh tools/export-sprites.ps1                 # all sprites -> art/export/*.png + lue-sheet.png (gitignored)
pwsh tools/import-sprite.ps1 art/foo.png      # PNG -> palette + row-string grid (prints to stdout)
pwsh tools/embed-victory.ps1 -CropShift 250   # re-embed art/victory.jpg into index.html as a data URI
```

`import-sprite.ps1` quantizes ±6/channel color jitter from pixel editors.
`embed-victory.ps1` **modifies index.html on disk** — Read the file again
before making anchored edits after running it.

Versioning: work is committed on the owner's request and tagged `v1.x`
(currently v1.5). Owner-provided source art lives in `art/` and is committed;
`art/export/` is generated and gitignored.

## Verification pattern (no test framework)

The established workflow: drive the live page in the browser pane via
`javascript_exec` — call `generateLevel()`, `startLevel()`, `update(STEP)`,
`render()` directly, then assert with `ctx.getImageData` pixel counts.
Hard-learned rules:

- **The pane only reliably reloads when a file edit fires the hook.**
  `navigate`/`location.reload()` often leave a stale JS realm. Start every
  test exec with a freshness probe (check a symbol you just added exists;
  return `"STALE REALM"` otherwise).
- **Never overwrite `window.update` without keeping a reference**
  (`window.__hold = update; update = () => {}; ... update = window.__hold`).
  Global function declarations are non-configurable — `delete` cannot restore
  them, and only a file edit gets you a fresh realm.
- **Save and restore localStorage around any test that plays/dies/wins.**
  Keys: `dogRunner.highScore`, `.unlocked`, `.endless`, `.endlessBest`.
  Death/finish paths write them (guarded by `> current` checks — set
  `game.highScore = 999999999` to shield during sims).
- Sprite edits: validate that every row string has exactly the grid width and
  every non-`.` char exists in the palette (for dog sprites: in **all four**
  `DOG_PALETTES`). Hand-counted row strings are the #1 source of bugs here.
- Never hand-copy base64 or long generated strings into files — generate and
  splice programmatically (see `embed-victory.ps1`).

## Architecture of index.html (top to bottom)

Everything hand-editable is at the top of the `<script>`; engine code below.

- **`CONFIG`** — every gameplay number. Per-level values are 10-entry arrays
  (index = level). **Gaps/spacings are in seconds of travel**, so layout
  fairness survives speed changes automatically; speeds gradient 380→720 px/s
  with level 10 == endless top speed. The `endless*` group interpolates
  difficulty by elapsed time.
- **`PALETTES` + `SPRITES`** — pixel art as row strings ('.' = transparent,
  chars index into a named palette). Baked once to offscreen canvases by
  `bakeSprites()`: names starting `dog` bake one variant per `DOG_PALETTES`
  entry (powerup recolors: fire/double/claw); names starting `bird` bake per
  `bird*` palette (per-level flyer species). Optional `outline: "#000"` bakes
  a 1px rim onto a canvas padded 1 cell per side, so edge-touching pixels
  keep their rim (no hand margins needed; the padded size only matters to
  code that positions a sprite by its top-left corner — see the victory
  bone); 8-digit hex palette entries give translucency (wings, visor).
  Lue is 32×32 @ scale 3 (96px): **`dogRun0` and `dogSit` are owner-drawn**
  (canonical PNGs in `art/`; import pipeline is pixel-exact) — other poses are
  derived from them. Ground poses must have paws on the bottom row; all poses
  share the same head position (overlays depend on it).
- **`LEVELS`** — 10 data-driven themes (Night City must stay last). Each has
  `obstacles` (keys into `OBSTACLE_TYPES`), `flyer` (sprite frames + palette +
  debris colors; null = level 1 static-only), parallax `layers`, and optional
  `dogGear` ("scuba"/"snowHat" costume overlays), `celestial` (fixed sun/moon,
  drawn without parallax), `weather` ("snow" → ambient particles).
- **`OBSTACLE_TYPES`** — every type declares `sprite:` (named after its key,
  with a same-named palette; drawn at ≈ collision box ÷ 3, scale 3, baked
  black outline). Breakables get a white rim. The colored-block renderer
  (`color`/`edge` + crack) survives as the fallback for spriteless types.
  Each level keeps exactly one breakable type.
- **`LAYER_PAINTERS`** — procedural parallax painters into wrap-safe tiles,
  480px wide unless the layer sets `tileW` for a longer repeat (backyard
  yardStuff uses 1920 so every 4th fence cat is a UFO abduction); elements
  crossing edges drawn at x−w/x/x+w. Baked lazily
  per theme (`theme._tiles`). **Layer array order = draw order and `factor`
  must increase toward the foreground** — recurring bug class: critters placed
  behind foliage (crabs/coral, reindeer/drifts) vanish. Mountain unicorns
  are drawn by the `peaks` painter itself (`unicorns: true` on the layer)
  so they stay glued to their summits.
- **Generation** — `generateLevel()` rolls a fresh seed per attempt
  (mulberry32; seed kept on the level for repro). Fairness rules: min gaps
  derived from jump physics, pickup min-spacing + guaranteed early pickup,
  flyers never share a gap with a pickup. ~70% of pickups sit at run-through
  height; ~30% ride the jump arc above an obstacle (taller grab box so any
  clean clearing jump collects). Endless mode (`startEndless`/`extendEndless`)
  generates ahead of the camera, cycles all 10 themes every 30s, drops
  entities behind the camera, and keeps a separate best score.
- **State machine** — TITLE → HOWTO → LEVEL_SELECT → PLAYING → DOOR_ANIM →
  LEVEL_COMPLETE/VICTORY, plus DEAD (retry or ESC/button to level select).
  The door animation is a phase timeline (`doorPhases()`); if the level ends
  mid-jump, `doorT` holds at 0 until she lands. Completing level 10 →
  VICTORY (embedded photo backdrop + eating animation) and unlocks endless.
- **drawPlayer layering** (order matters): wings/fire-aura behind → dog sprite
  (palette by powerup) → claw glam overlay (`clawFit` + per-pose `PAW_HEELS`
  heel stamps — heels must track paw positions per pose) → theme gear on top.
  The fire aura has run (horizontal trail) and sit (rising flames) variants
  chosen by pose. Blink-skip during i-frames hides everything together.
- **Particles** — one array, three behaviors: debris (gravity), `bubble`
  (rises; scuba exhaust), `snow` (falls, culled at ground line).
- **Persistence/audio/PWA** — localStorage helpers near the top of the engine;
  `ensureAudio()` unlocks on first gesture (iOS); `setupPWA()` at the bottom
  builds the manifest/icon from Lue's sprite at runtime.

## Gameplay invariants to protect

- A hit with a powerup costs only the powerup (+i-frames); without one it's
  death → retry same level. Score snapshots at level start and restores on
  retry; returning to level select zeroes the run score.
- Level 1 has no flyers. Every level must keep at least one breakable
  obstacle or the fire/claw powerups become useless there.
- Jump arc is fixed (no variable height): apex ≈ jumpVelocity²/2·gravity
  (~174px feet height). Anything that must be jumped over or grabbed
  mid-arc has to respect that number (see `pickupJumpHeight` comment).
