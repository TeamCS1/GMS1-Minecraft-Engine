///scr_GetHeightTier(tile_x, tile_y)
//Returns the natural terrain height tier (0, 1, or 2) for the given tile
//index (world position / 32), using the same smooth low-frequency
//formula everywhere so natural generation, decoration placement, and
//edit bookkeeping all agree on what the terrain "naturally" looks like
//at any position -- including chunks that haven't been generated yet.
//
//A second, much lower-frequency "plains mask" flattens whole regions:
//inside a flat region the tier is a constant 1 (the middle tier, so a
//boundary against hilly tiles at 0..2 is never more than a single block
//step -- no unclimbable cliffs at the seam). Flat and hilly areas occur
//in every biome, since the biome choice (scr_GetBiome) is independent
//of this function.
//
//Depends on global.height_seed_x/y and global.flat_seed_x/y, set once
//per session by obj_biome_gen's Create event.

var tile_x = argument0;
var tile_y = argument1;

//plains mask -- very low frequency, so flat regions span multiple chunks
var flat_raw = sin((tile_x * 32 + global.flat_seed_x) * 0.008) + cos((tile_y * 32 + global.flat_seed_y) * 0.008);

if (flat_raw > 0.6)
{
    return 1;
}

var raw = sin((tile_x * 32 + global.height_seed_x) * 0.04) + cos((tile_y * 32 + global.height_seed_y) * 0.04);
return round(clamp(raw, -1, 1) + 1);
