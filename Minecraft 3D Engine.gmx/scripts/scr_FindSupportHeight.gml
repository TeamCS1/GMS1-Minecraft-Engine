///scr_FindSupportHeight()
//Returns the standing height the tallest solid block under the calling
//instance's own x/y would give (that block's own top, z + 32, plus the
//player's 32-unit eye offset), or -1 if no solid block is there. Shared
//by scr_CollisionHandler.gml and obj_camera's jump landing check so both
//agree on what surface is currently underneath, at any elevation. For
//an arbitrary (not-self) x/y -- e.g. the tile ahead when checking
//horizontal push-back -- see scr_FindSupportHeightAt(check_x, check_y)
//instead; GMS1.4 requires a script's argument count to always match its
//call sites, so this can't just take optional arguments.
//
//Uses global.block_lookup for an O(1) check per layer instead of
//scanning every loaded block instance (there can be thousands). Assumes
//solid blocks are always corner-anchored (hit_x1 = hit_y1 = 0), true for
//every current type (grass/sand/snow) -- a future off-center solid block
//would need this rewritten to also account for hit_x1/hit_y1.

var tile_x = floor(x / 32);
var tile_y = floor(y / 32);

var support_h = -1;
var max_layers = 64;   //generous cap -- 2048 units tall, far beyond any realistic build

for (var h = 0; h < max_layers; h++)
{
    var key = scr_EncodeBlockKey(tile_x, tile_y, h);

    if (ds_map_exists(global.block_lookup, key))
    {
        support_h = h;
    }
}

if (support_h == -1)
{
    return -1;
}

var support_z = support_h * 32 + 32 + 32;

// Never return a standing height below the flat ground baseline (80).
// obj_biome_gen places grass/snow at z=0 (top 32), which under the plain
// top+32 formula would sink the player to 64 -- lower than intended.
// Sand's already-tuned 96 (z=32, top 64) is unaffected since it's above 80.
if (support_z < 80)
{
    support_z = 80;
}

return support_z
