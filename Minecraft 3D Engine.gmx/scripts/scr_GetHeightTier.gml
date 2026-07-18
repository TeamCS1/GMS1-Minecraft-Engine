///scr_GetHeightTier(tile_x, tile_y)
//Returns the natural terrain height tier for the given tile index
//(world position / 32), using the same smooth low-frequency formula
//everywhere so natural generation, decoration placement, and edit
//bookkeeping all agree on what the terrain "naturally" looks like at
//any position -- including chunks that haven't been generated yet.
//
//Three stacked masks, all pure functions of position:
//- Plains mask (lowest frequency): regions above the threshold are a
//  constant tier 1 (middle tier, so flat/hill seams never step more
//  than one block). Checked first -- plains stay flat even inside a
//  mountain region.
//- Base hills: tiers 0-2 from the original sin/cos rolling-hill field.
//- Mountain mask (grass/snow biomes only, never desert): where its own
//  low-frequency field exceeds a threshold, extra tiers are added on
//  top of the base hills, ramping up smoothly with how far above the
//  threshold the field is (up to about +5 tiers, so peaks reach around
//  tier 7 -- much taller terrain than the base 0-2 range). Because the
//  boost is gated on the tile's chunk biome, a mountain region that
//  straddles a desert border produces a deliberate cliff on the desert
//  side (mesa-style) rather than boosted sand.
//
//Depends on global.height_seed_x/y, global.flat_seed_x/y, and
//global.mountain_seed_x/y, set once per session by obj_biome_gen's
//Create event.

var tile_x = argument0;
var tile_y = argument1;

//plains mask -- very low frequency, so flat regions span multiple chunks
var flat_raw = sin((tile_x * 32 + global.flat_seed_x) * 0.008) + cos((tile_y * 32 + global.flat_seed_y) * 0.008);

if (flat_raw > 0.6)
{
    return 1;
}

//base rolling hills, tiers 0-2
var raw = sin((tile_x * 32 + global.height_seed_x) * 0.04) + cos((tile_y * 32 + global.height_seed_y) * 0.04);
var tier = round(clamp(raw, -1, 1) + 1);

//mountain mask -- grass and snow only, never desert
var chunk_cx = floor(tile_x / global.chunk_tiles);
var chunk_cy = floor(tile_y / global.chunk_tiles);

if (scr_GetBiome(chunk_cx, chunk_cy) != obj_sand_block)
{
    var mountain_raw = sin((tile_x * 32 + global.mountain_seed_x) * 0.015) + cos((tile_y * 32 + global.mountain_seed_y) * 0.015);

    if (mountain_raw > 1.0)
    {
        //smooth ramp: the further above the threshold, the taller the
        //boost, so mountains rise out of the hills a step or two per
        //tile instead of appearing as a sheer wall
        tier += round((mountain_raw - 1.0) * 5);
    }
}

return tier;
