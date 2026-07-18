# GMS1 Minecraft Engine

A first-person voxel engine (Minecraft-style) built in GameMaker Studio
1.4 using its legacy `d3d_*` 3D functions. Features chunk-streamed,
effectively-infinite procedural terrain with grass/desert/snow biomes and
flat/hilly/mountain variation, block breaking/placing with edit
persistence, and frustum + buried-block draw culling. See Architecture
below for how the pieces fit together.

# Project instructions

This is a GameMaker Studio 1.4 project using the GMX project format.

## Compatibility

- Use only GameMaker Studio 1.4-compatible GML.
- Do not use GameMaker Studio 2 or modern GameMaker syntax.
- Do not use structs, constructors, methods, function declarations,
  array_push, static variables or modern accessor syntax.
- Preserve the existing project structure and naming conventions.
- Prefer ds_list, ds_map and ds_grid for complex data structures.
- Use scripts in the traditional GameMaker Studio 1.4 style.
- Do not rename resources unless explicitly requested.

## Project changes

- Inspect related scripts and objects before making changes.
- Keep changes small and focused.
- Explain which files were modified.
- Avoid changing project metadata unnecessarily.
- When adding a resource, ensure it is properly registered in the
  main .project.gmx file.
- Do not delete existing resources without permission.

## Testing

GameMaker Studio 1.4 is used locally to compile and test the project.
When compilation errors are provided, fix the underlying source files
without introducing modern GML syntax.

## Architecture

- `obj_camera` is the live camera object. `obj_camera_new` is dead code
  (not to be used or extended).
- Rendering uses two approaches depending on the asset:
  - Model-based: `load_model.gml` (`d3d_model_create` + `d3d_model_load`)
    paired with a companion texture file.
  - Primitive-based: built-in `d3d_*` functions (e.g. `d3d_draw_block`,
    `d3d_draw_wall`, `d3d_draw_floor`) for procedurally drawn blocks,
    walls, and floors. See `obj_grass_block` for the pattern: texture via
    `sprite_get_texture`, `draw_set_alpha(fade_alpha)` around the draw
    call (for the streamed-in fade), and toggle
    `texture_set_interpolation` around it too. The Draw event does *not*
    check distance/visibility itself — that's all handled by the built-in
    `visible` flag set in `obj_block_parent`'s Step event (see Draw-time
    culling below), so Draw only runs at all for on-screen blocks.
- World/chunk streaming: the world is divided into `global.chunk_tiles`
  (8) x 8-tile chunks. `obj_biome_gen`'s Step event checks the player's
  current chunk each frame (cheaply — only reacts when it actually
  changes) and calls `scr_UpdateLoadedChunks()`, which generates any
  chunk within `global.renderDistance` (+1 chunk buffer) that isn't
  loaded yet via `scr_GenerateChunk(cx, cy)`, and destroys (via
  `scr_UnloadChunk`) any loaded chunk now well outside that range (a
  1-chunk hysteresis margin on the unload distance stops chunks
  thrashing right at the boundary). Nothing about this assumes a fixed
  world size — a chunk's contents are entirely a function of its
  coordinate, so the world is effectively infinite (see the two bullets
  below).
- Terrain height/biome are pure functions of position, not stored state:
  `scr_GetHeightTier(tile_x, tile_y)` returns a tile's height tier (0/1/2,
  i.e. 0/32/64 z) from a smooth, low-frequency `sin`/`cos` function offset
  by a per-run random seed (`global.height_seed_x`/`y`, set once by
  `obj_biome_gen`'s Create event) — random between playthroughs, but
  neighboring tiles trend together into rolling hills rather than
  independent per-tile spikes. A second, much lower-frequency "plains
  mask" (`global.flat_seed_x`/`y`) overrides whole regions to a constant
  tier 1 — completely flat areas spanning multiple chunks, in any biome.
  Flat regions deliberately sit at the *middle* tier so their boundary
  against hilly terrain (tiers 0–2) is never more than a one-block step,
  avoiding unclimbable cliffs at the seam. A third "mountain mask"
  (`global.mountain_seed_x`/`y`) adds extra tiers on top of the base
  hills in grass and snow biomes only (never desert — the boost is
  gated on the tile's chunk biome via `scr_GetBiome`): where its
  low-frequency field exceeds a threshold, the boost ramps up smoothly
  with distance above the threshold, up to about +5 tiers (peaks around
  tier 7), so tall hills rise adjacent to normal hills a step or two per
  tile rather than as sheer walls. Plains win over mountains (the flat
  check runs first). A mountain region straddling a desert border
  produces a deliberate mesa-style cliff on the desert side. `scr_GetBiome(chunk_cx,
  chunk_cy)` picks the terrain block type per chunk — grass (most
  common), sand (desert), or snow — from a low-frequency function of
  chunk coordinates (`global.biome_seed_x`/`y`), so biomes form coherent
  multi-chunk regions rather than a per-chunk checkerboard. Biome and
  flatness are independent axes: every biome has flat and hilly
  variants. Deserts skip tall-grass decoration (gated in
  `scr_GenerateChunk`). Being pure functions (no instance lookups, same
  input always gives the same output) is what lets a chunk be generated,
  destroyed, and regenerated later with identical results, and lets
  neighbor tiles/chunks be evaluated even before their own chunk has
  been generated.
- Chunk generation (`scr_GenerateChunk(chunk_cx, chunk_cy)`): for each
  tile, fills the column solid from `z = 0` up to `scr_GetHeightTier`'s
  result (one instance per 32-unit step) so hills read as solid ground
  rather than floating platforms, and sets each block's `is_buried` (see
  Draw-time culling below) analytically from the same height formula
  applied to its 4 neighbor tiles — no instance lookups needed, even
  across a chunk boundary. Tall-grass decoration placement uses a
  deterministic position hash (`frac(sin(...) * 43758.5453)`, a
  standard "pseudo-random from position" trick) instead of `random()`,
  so the same tile always decides the same way across unload/reload; it
  sits on top of the tile's terrain surface via the same height formula.
  After natural generation, re-applies anything recorded in
  `global.block_edits`/`global.chunk_extra` (see below) so player edits
  survive a chunk unloading and reloading. Every spawned instance starts
  at `fade_alpha = 0`, ramping to 1 in `obj_block_parent`'s Step event, so
  newly streamed-in chunks fade in instead of popping into view.
- Edit persistence: breaking or placing a block needs to survive its
  chunk being unloaded and regenerated later, so `obj_ray_cast`'s
  break/place handlers record every change into `global.block_edits` — a
  `ds_map` keyed by `scr_EncodeBlockKey(tile_x, tile_y, layer_h)` (a
  single real number packing the three values via offset+multiply, since
  GML 1.4 has no `string_split` to unpack a "x,y,z"-style string key) to
  either `0` (removed) or an object index (placed/overridden type).
  `scr_GenerateChunk`'s natural-fill loop checks this map for every tile
  it would otherwise visit, so edits to naturally-generated cells are
  handled automatically. Placements *outside* the natural column (e.g.
  building upward past the hill, or floating platforms) are invisible to
  that loop, so they're also appended to `global.chunk_extra` — a
  `ds_map` keyed by `scr_EncodeChunkKey` to a `ds_list` of the affected
  position keys — which `scr_GenerateChunk` replays after the natural
  pass. Breaking a natural-column block just marks it `0`; breaking an
  "extra" placement deletes its `block_edits` entry outright, since
  there's no natural fallback to remember. Decorative blocks
  (`obj_tinted_cross`) are deliberately **not** tracked this way (they
  aren't grid-aligned, and their placement is already deterministic-by-
  position) — breaking one doesn't persist.
- Spatial lookup (`global.block_lookup`, a `ds_map` keyed by
  `scr_EncodeBlockKey`, value = instance id): with thousands of blocks
  loaded, a `with (obj_block_parent)` scan per query (the original
  approach) became the dominant per-frame cost. `block_lookup` gives O(1)
  "is there a solid block at this exact position" instead, and
  `scr_FindSupportHeight`/`scr_Raycast`/`scr_IsSolidBlockAt` all use it
  now — only decorative `obj_tinted_cross` still needs a small instance
  scan (it isn't grid-corner-aligned, and there are far fewer of them
  than solid blocks). Because it's a cache of live instance ids, not a
  data source of truth, it must be kept in sync at every creation/
  destruction site: both loops in `scr_GenerateChunk`, `scr_UnloadChunk`
  (removes entries *before* destroying, or the map would hold stale ids),
  and `obj_ray_cast`'s place/break handlers. Two hard-won sync rules:
  deletes are ownership-checked (only remove an entry if it still points
  at the exact instance being destroyed — blindly deleting by key can
  orphan a duplicate that later claimed the cell, leaving it visible but
  collisionless), and inserts are replace-or-add (a bare `ds_map_add`
  fails *silently* when the key exists, leaving the map pointing at a
  stale instance). Player-placed blocks must also get `chunk_cx`/
  `chunk_cy` set at placement — the parent default of (0,0) would make
  chunk (0,0)'s unload destroy them and their real chunk's unload miss
  them, which was the cause of a rare walk-through-block bug.
- Block object inheritance: `obj_grass_block`, `obj_sand_block`,
  `obj_snow_block`, and `obj_tinted_cross` are all children of
  `obj_block_parent` (never instantiated directly). The parent defines
  `hit_x1`/`hit_y1` — the offset of the block's hit box's near corner
  relative to its own x/y (0,0 for the cube blocks; -16,-16 for
  `obj_tinted_cross`, which is centered rather than corner-anchored) —
  and `is_solid` (true by default; `obj_tinted_cross` overrides it to
  false since it's decorative and shouldn't be stood on or collided with).
  Any code that needs to test "is this any kind of block" (raycasting,
  collision) should use a single `with (obj_block_parent)` check —
  GameMaker's `with` automatically includes child instances — instead of
  one check per block type. Child Create/Step events must call
  `event_inherited()` first so the parent's defaults/logic run. Adding a
  new block type means parenting it to `obj_block_parent` (and setting
  `hit_x1`/`hit_y1`/`is_solid` if they differ from the defaults); no other
  script needs to change.
- Draw-time culling (`obj_block_parent`'s Step event, plus `is_buried`
  set elsewhere — see below): sets the engine's own built-in `visible`
  instead of a custom flag, so GameMaker skips calling Draw entirely for
  culled instances rather than calling it to do nothing. `visible`
  combines three things, recomputed every frame in the parent's Step
  event: distance, a generous 100-degree view-cone check against the
  camera's actual 3D look vector (`lookx`/`looky`/`lookz` — the same one
  raycasting uses, not just horizontal `facingDir`; a horizontal-only
  check stays a narrow wedge even when looking straight down, wrongly
  culling blocks to the side/behind even though looking down actually
  reveals a wide disc all around the player) — this is frustum culling,
  skipping blocks well outside where the camera is pointing — and
  `!is_buried`. All of it is done in squared distances with no `sqrt`/
  division: `obj_camera`'s look vector is a true unit vector (proper
  spherical-to-cartesian conversion, not the project's older linear
  approximation), so `cos(angle) = dot / |to_block|` needs no second
  normalization, and comparing against the (obtuse, 100-degree) threshold
  angle is done by letting any non-negative dot product through
  immediately (an obtuse cone always accepts "in front of or beside",
  only "behind" needs the actual angle check) and squaring only the
  negative-dot case. This runs for every loaded block every frame, so
  avoiding `sqrt` here matters far more than in code that only runs on
  player action. `is_buried` means "fully enclosed by solid neighbors on
  all 6 sides, so it can never actually be seen" and is deliberately
  *not* recomputed every frame (checking 6 neighbors per block per frame
  would be far too slow) — instead it's maintained two ways:
  `scr_GenerateChunk` computes it analytically at world-gen time (cheap,
  since terrain height is a pure function of position — no instance
  lookups needed), and `scr_UpdateBuriedAround(cx, cy, cz)` recomputes it
  via `global.block_lookup`/`scr_RecomputeBuriedAt` for the handful of
  blocks touching a given cell whenever `obj_ray_cast` places or breaks a
  block.
- Raycasting/interaction (`scr_Raycast.gml`, called from `obj_camera`'s Step
  event): marches a ray from the camera's eye position along the actual
  look vector (`lookx`/`looky`/`lookz`, derived from `facingDir`/`zdir`)
  in fixed steps. Solid cube blocks are tested via an O(1)
  `global.block_lookup` check on the sample point's tile indices;
  `obj_tinted_cross` (not grid-corner-aligned, and far less numerous)
  still uses a small instance scan. On a hit, `obj_ray_cast` is spawned
  at the last empty cell before the hit block, with `target_block` set
  to the exact instance that was hit — left-click destroys
  `target_block` directly, right-click places a new block there
  (currently hardcoded to `obj_grass_block`).
- Collision (`scr_CollisionHandler.gml`, called from `obj_camera`'s Step
  event right after raycasting): uses `scr_FindSupportHeight()` to get the
  standing height the tallest solid block under the player's x/y would
  give — its own top (`z + 32`) plus a fixed 32-unit eye offset (the same
  offset sand was already tuned to: top 64 -> standing height 96), or -1
  if nothing solid is there (collision then falls back to a flat ground
  baseline of 80). Finds it by scanning upward through `global.block_lookup`
  for that x/y column (a bounded 64-layer cap, each check O(1)) instead
  of the project's original approach of scanning every loaded block
  instance. This supports any number of stacked layers automatically: a
  block placed with its own z at or above a lower block's top just
  produces a taller support height, no per-layer code needed.
  `global.layer` is derived from the resulting height
  (`1 + (player_height - 80) / 16`) for the HUD/debug display.
  `scr_FindSupportHeight()` matches purely by x/y footprint, with no
  regard for how far below/above the player that block actually is, so
  collision reacts based on the gap to the player's current z rather than
  just "was a block found": `z < support_z` bumps (a taller block's
  side); `z - support_z > 32` means whatever matched is too far below to
  be considered underfoot, so it starts falling (`jump = true`,
  `jumpHeightModifier = 0`, handing off to the same arc a real jump uses,
  just with no initial upward boost) instead of teleporting down; anything
  closer snaps directly onto it. This is what makes walking off a tall
  stack fall naturally instead of jumping straight to the block below.
- Jumping (`obj_camera`'s Step event): a simple arc — `jumpHeightModifier`
  starts at 5.0 on takeoff and decrements by 0.5 every step, added to `z`
  each frame, so it rises then falls on its own. Once `jumpHeightModifier`
  goes negative (falling), each frame re-calls `scr_FindSupportHeight()`
  and lands as soon as `z` reaches that height — the *current* surface
  underneath, not necessarily the one the jump started from. This is what
  lets a jump land on a new, taller layer reached mid-arc instead of
  always falling back to the takeoff height.

## Code style (observed conventions)

- Script header comment: `///script_name(args)` followed by a `//`
  one-line description (see `load_model.gml`).
- Allman-style braces (opening brace on its own line).
- Locals declared with `var`; prefer `snake_case` for local variables.
- Block/grid alignment uses `move_snap(32, 32)` on create; block size is
  32 units unless stated otherwise.
- Child objects call `event_inherited();` as the first line of any event
  they share with `obj_block_parent` (currently Create and Step), so the
  parent's shared initialization/logic actually runs.

## Roadmap (confirmed by project owner)

- Biomes are done (grass/desert/snow regions, each with flat and hilly
  variants — see Architecture). Possible later polish: desert-specific
  decoration (e.g. cacti) to replace the tall grass deserts now skip,
  and biome-aware terrain shapes (e.g. dunes).
- `obj_torch` is a deliberate lighting test, not a finished feature: a
  physical torch mesh is planned for later, but the current toggleable
  point-light-only version works fine for testing lighting as-is. No work
  needed on it for now.
- `rm_gen` is reserved for world-gen seeds and starting parameters for
  future terrain generation. Leave it empty/untouched for now.
- Hotbar/inventory (`global.slots` currently only drives the HUD
  highlight, nothing consumes it) is planned but not being worked on yet
  — leave as-is.
- Block collision now generalizes to every solid block type (grass/sand/
  snow) via `obj_block_parent`, with support for stacked multi-elevation
  layers derived from each block's own z — see Architecture. Owner
  confirmed: sand was the test bed (80 = ground, 96 = standing on one
  block); a third layer was attempted by hand and had trouble, which is
  what this generalization is meant to fix. Player gravity/landing is
  handled by the existing jump code in `obj_camera`, not a separate
  system.

## Open questions

- **Block placement type selection**: `obj_ray_cast`'s right-click handler
  still has `// TODO: allow selection of blocks` and always places
  `obj_grass_block`. Wire to `global.slots` once there's a real inventory?
- **Orphaned `backup` object**: `objects/backup.object.gmx` is registered
  in the project file but never instantiated anywhere (not in code, not in
  any room) — looks like an abandoned debug HUD for `buffer_getpixel`
  color-picking. Delete alongside `obj_camera_new`, or keep for reference?
- **Chunk streaming known limitations** (flagging for testing, not asking
  a design question): the very first `scr_UpdateLoadedChunks()` call (at
  game start) loads every chunk within render distance synchronously in
  one event — roughly 80 chunks at the default settings — which may cause
  a noticeable startup hitch; spreading initial loads across several
  frames would fix this if it's a problem in practice. `load_radius`/
  `unload_radius` (in `scr_UpdateLoadedChunks.gml`) are directly tunable
  if the instance count turns out too heavy. "Infinite" is a practical
  bound, not literal — `scr_EncodeBlockKey`/`scr_EncodeChunkKey` support
  positions roughly ±3.2 million units before their packed-key encoding
  would need larger offset constants, far beyond any realistic play
  session.

## TODO

- Delete the dead `obj_camera_new` object (superseded by `obj_camera`).
- Add a crosshair (screen-center HUD marker; `obj_hud`'s Draw GUI event
  is the natural home, alongside the hotbar drawing).
- Update the crosshair texture once the crosshair exists (replace
  whatever placeholder it starts with).
