///scr_GetBiome(chunk_cx, chunk_cy)
//Returns the block object type (obj_grass_block or obj_snow_block) a
//given chunk should use, deterministically -- so a chunk always gets the
//same biome choice no matter how many times it's unloaded and
//regenerated. Depends on global.biome_seed_x/y, set once per session by
//obj_biome_gen's Create event. Sand isn't part of natural generation yet
//(see CLAUDE.md roadmap).

var chunk_cx = argument0;
var chunk_cy = argument1;

var raw = sin((chunk_cx * 37 + global.biome_seed_x) * 0.7) + cos((chunk_cy * 53 + global.biome_seed_y) * 0.7);

var biome = obj_grass_block;
if (raw > 0)
{
    biome = obj_snow_block;
}

return biome;
