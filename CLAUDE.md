# GMS1 Minecraft Engine

Test file to confirm write access is working.

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
    walls, and floors. See `obj_grass_block` for the pattern: render
    only `if distance_to_object(obj_camera) < global.renderDistance`,
    texture via `sprite_get_texture`, and toggle
    `texture_set_interpolation` around the draw call.
- World/chunk data storage: currently plain object instances; a chunk
  streaming system is planned — see Roadmap below.
- Terrain height (`obj_biome_gen`'s Create event): each tile's height
  tier (0/1/2, i.e. 0/32/64 z) comes from a smooth, low-frequency
  `sin`/`cos` function of its position, offset by a per-run random seed
  (`height_seed_x`/`height_seed_y`) — random between playthroughs, but
  neighboring tiles trend together into rolling hills rather than
  independent per-tile spikes. The column is filled solid from `z = 0` up
  to that tile's tier (one instance per 32-unit step) so hills read as
  solid ground rather than floating platforms; `scr_FindSupportHeight()`
  (see Collision below) needed no changes to support this, since it
  already takes the tallest matching block regardless of elevation. The
  `obj_tinted_cross` decoration clusters recompute the same height
  formula for their tile so they sit on top of the terrain surface
  instead of assuming flat `z=0` ground. Also sets each block's
  `is_buried` (see Draw-time culling below) analytically from the same
  height formula applied to its 4 neighbor tiles, so world-gen doesn't
  need any instance lookups to know which blocks are fully covered.
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
  set elsewhere — see below): each child's Draw event checks a single
  `is_visible` flag instead of re-deriving its own condition.
  `is_visible` combines three things, recomputed every frame in the
  parent's Step event: distance (`distance_to_object(obj_camera) <
  global.renderDistance`, as before), a generous 100-degree view-cone
  check against the camera's actual 3D look vector (`lookx`/`looky`/
  `lookz` — the same one raycasting uses, not just horizontal
  `facingDir`; a horizontal-only check stays a narrow wedge even when
  looking straight down, wrongly culling blocks to the side/behind even
  though looking down actually reveals a wide disc all around the
  player) — this is frustum culling, skipping blocks well outside where
  the camera is pointing — and `!is_buried`. `is_buried` means
  "fully enclosed by solid neighbors on all 6 sides, so it can never
  actually be seen" and is deliberately *not* recomputed every frame
  (checking 6 neighbors per block per frame would be far too slow) —
  instead it's maintained two ways: `obj_biome_gen` computes it
  analytically at world-gen time (cheap, since terrain height is a pure
  function of position — no instance lookups needed, just re-evaluating
  the same height formula for each neighbor tile), and
  `scr_UpdateBuriedAround(cx, cy, cz)` recomputes it via an actual
  instance scan (`scr_IsSolidBlockAt`) for the handful of blocks touching
  a given cell whenever `obj_ray_cast` places or breaks a block — cheap
  enough since that only runs on player action, not every frame.
- Raycasting/interaction (`scr_Raycast.gml`, called from `obj_camera`'s Step
  event): marches a ray from the camera's eye position along the actual
  look vector (`lookx`/`looky`/`lookz`, derived from `facingDir`/`zdir`)
  in fixed steps, testing each sample point against `obj_block_parent`'s
  hit box (see above). On a hit, `obj_ray_cast` is spawned at the last
  empty cell before the hit block, with `target_block` set to the exact
  instance that was hit — left-click destroys `target_block` directly,
  right-click places a new block there (currently hardcoded to
  `obj_grass_block`).
- Collision (`scr_CollisionHandler.gml`, called from `obj_camera`'s Step
  event right after raycasting): uses `scr_FindSupportHeight()` to get the
  standing height the tallest solid block under the player's x/y would
  give — its own top (`z + 32`) plus a fixed 32-unit eye offset (the same
  offset sand was already tuned to: top 64 -> standing height 96), or -1
  if nothing solid is there (collision then falls back to a flat ground
  baseline of 80). This supports any number of stacked layers
  automatically: a block placed with its own z at or above a lower
  block's top just produces a taller support height, no per-layer code
  needed. `global.layer` is derived from the resulting height
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

- World/chunk data model: blocks are currently plain object instances (no
  `ds_grid`/`ds_map`), located via `instance_nearest`/`with` over each
  per-block-type object. This will be replaced by an efficient chunking
  system that streams chunks in/out as the player moves through the
  world. Planned for the future — more basic issues need fixing first
  before tackling this.
- Infinite/streaming world generation is planned (depends on the chunking
  system above).
- Sand will become part of random terrain generation (`obj_biome_gen`
  currently only ever chooses grass or snow); a desert biome is planned
  for later.
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

## TODO

- Delete the dead `obj_camera_new` object (superseded by `obj_camera`).
