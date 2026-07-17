///scr_GetHeightTier(tile_x, tile_y)
//Returns the natural terrain height tier (0, 1, or 2) for the given tile
//index (world position / 32), using the same smooth low-frequency
//formula everywhere so natural generation, decoration placement, and
//edit bookkeeping all agree on what the terrain "naturally" looks like
//at any position -- including chunks that haven't been generated yet.
//Depends on global.height_seed_x/y, set once per session by
//obj_biome_gen's Create event.

var tile_x = argument0;
var tile_y = argument1;

var raw = sin((tile_x * 32 + global.height_seed_x) * 0.04) + cos((tile_y * 32 + global.height_seed_y) * 0.04);
return round(clamp(raw, -1, 1) + 1);
