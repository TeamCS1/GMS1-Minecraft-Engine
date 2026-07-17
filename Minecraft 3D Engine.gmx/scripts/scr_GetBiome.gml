///scr_GetBiome(chunk_cx, chunk_cy)
//Returns the block object type a given chunk's terrain is made of --
//obj_grass_block (most common), obj_sand_block (desert), or
//obj_snow_block -- deterministically, so a chunk always gets the same
//biome no matter how many times it's unloaded and regenerated.
//
//The frequency is low relative to chunk coordinates, so biomes form
//coherent multi-chunk regions (a desert is an area you walk through,
//not a per-chunk checkerboard). Flat/hilly variation is independent of
//this (see scr_GetHeightTier's plains mask), so every biome naturally
//has both flat and hilly areas.
//
//Depends on global.biome_seed_x/y, set once per session by
//obj_biome_gen's Create event.

var chunk_cx = argument0;
var chunk_cy = argument1;

var raw = sin((chunk_cx + global.biome_seed_x) * 0.3) + cos((chunk_cy + global.biome_seed_y) * 0.3);

if (raw > 0.8)
{
    return obj_snow_block;
}

if (raw < -0.8)
{
    return obj_sand_block;
}

return obj_grass_block;
