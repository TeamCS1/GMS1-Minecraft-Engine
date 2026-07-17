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
- World/chunk data storage: TBD — **open question for the project owner**,
  see below.

## Code style (observed conventions)

- Script header comment: `///script_name(args)` followed by a `//`
  one-line description (see `load_model.gml`).
- Allman-style braces (opening brace on its own line).
- Locals declared with `var`; prefer `snake_case` for local variables.
- Block/grid alignment uses `move_snap(32, 32)` on create; block size is
  32 units unless stated otherwise.

## Open questions

- **World/chunk data model**: how is block data actually stored? The
  raycasting script (`scr_Raycast.gml`) currently locates nearby blocks
  via `instance_nearest` on per-block-type object instances (e.g.
  `obj_grass_block`, `obj_sand_block`), not a `ds_grid`/`ds_map`. Confirm
  whether this instance-based approach is the intended long-term model,
  or whether a chunk/grid data structure is planned. (Owner to answer.)

## TODO

- Delete the dead `obj_camera_new` object (superseded by `obj_camera`).
