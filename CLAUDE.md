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
- Block object inheritance: `obj_grass_block`, `obj_sand_block`,
  `obj_snow_block`, and `obj_tinted_cross` are all children of
  `obj_block_parent` (never instantiated directly). The parent defines
  `hit_x1`/`hit_y1` — the offset of the block's hit box's near corner
  relative to its own x/y (0,0 for the cube blocks; -16,-16 for
  `obj_tinted_cross`, which is centered rather than corner-anchored).
  Any code that needs to test "is this any kind of block" (raycasting,
  eventually collision) should use a single `with (obj_block_parent)`
  check — GameMaker's `with` automatically includes child instances —
  instead of one check per block type. Child Create events must call
  `event_inherited()` first so the parent's `hit_x1`/`hit_y1` defaults run.
  Adding a new block type means parenting it to `obj_block_parent`
  (and setting `hit_x1`/`hit_y1` if it isn't corner-anchored); no other
  script needs to change.
- Raycasting/interaction (`scr_Raycast.gml`, called from `obj_camera`'s Step
  event): marches a ray from the camera's eye position along the actual
  look vector (`lookx`/`looky`/`lookz`, derived from `facingDir`/`zdir`)
  in fixed steps, testing each sample point against `obj_block_parent`'s
  hit box (see above). On a hit, `obj_ray_cast` is spawned at the last
  empty cell before the hit block, with `target_block` set to the exact
  instance that was hit — left-click destroys `target_block` directly,
  right-click places a new block there (currently hardcoded to
  `obj_grass_block`).

## Code style (observed conventions)

- Script header comment: `///script_name(args)` followed by a `//`
  one-line description (see `load_model.gml`).
- Allman-style braces (opening brace on its own line).
- Locals declared with `var`; prefer `snake_case` for local variables.
- Block/grid alignment uses `move_snap(32, 32)` on create; block size is
  32 units unless stated otherwise.
- Child objects call `event_inherited();` as the first line of any event
  they share with `obj_block_parent` (currently just Create), so the
  parent's shared initialization actually runs.

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
- Block collision (`scr_CollisionHandler.gml` only handles `obj_sand_block`
  step-up; grass/snow have none) will be picked up after the new
  look-direction raycasting has been tested — raycasting has now been
  tested and confirmed working. The `obj_block_parent` inheritance
  refactor (see Architecture) is in place so collision can use the same
  single-check pattern; the actual step-up behavior desired for
  grass/snow is still to be defined (sand's current 80/96 z thresholds
  don't obviously generalize — see Open questions).

## Open questions

- **Block placement type selection**: `obj_ray_cast`'s right-click handler
  still has `// TODO: allow selection of blocks` and always places
  `obj_grass_block`. Wire to `global.slots` once there's a real inventory?
- **Block collision behavior**: `scr_CollisionHandler.gml`'s existing
  sand-only logic uses hardcoded z thresholds (80/96) for step-up that
  don't obviously generalize — grass/snow normally sit at z=0 (already
  matching the player's baseline `player_height` of 80), and there's no
  gravity/falling system currently, so it's unclear what "collision" should
  actually do for grass/snow: same kind of step-up as sand (and if so, by
  how much), or just solid-floor blocking derived from each block's own z?
  Needs a decision before generalizing past sand.
- **Orphaned `backup` object**: `objects/backup.object.gmx` is registered
  in the project file but never instantiated anywhere (not in code, not in
  any room) — looks like an abandoned debug HUD for `buffer_getpixel`
  color-picking. Delete alongside `obj_camera_new`, or keep for reference?

## TODO

- Delete the dead `obj_camera_new` object (superseded by `obj_camera`).
