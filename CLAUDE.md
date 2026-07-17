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
- Raycasting/interaction (`scr_Raycast.gml`, called from `obj_camera`'s Step
  event): marches a ray from the camera's eye position along the actual
  look vector (`lookx`/`looky`/`lookz`, derived from `facingDir`/`zdir`)
  in fixed steps, testing each sample point against grass/sand/snow block
  bounding boxes. On a hit, `obj_ray_cast` is spawned at the last empty
  cell before the hit block — left-click breaks the nearest block to that
  reticle (`obj_ray_cast`'s own collision event, checks all 4 block types
  including `obj_tinted_cross`), right-click places a new block there
  (currently hardcoded to `obj_grass_block`).

## Code style (observed conventions)

- Script header comment: `///script_name(args)` followed by a `//`
  one-line description (see `load_model.gml`).
- Allman-style braces (opening brace on its own line).
- Locals declared with `var`; prefer `snake_case` for local variables.
- Block/grid alignment uses `move_snap(32, 32)` on create; block size is
  32 units unless stated otherwise.

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
  look-direction raycasting has been tested.

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
