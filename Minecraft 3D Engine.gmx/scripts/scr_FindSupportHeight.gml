///scr_FindSupportHeight([check_x, check_y])
//Returns the standing height the tallest solid block under the given x/y
//would give (that block's own top, z + 32, plus the player's 32-unit eye
//offset), or -1 if no solid block is there. With no arguments, checks the
//calling instance's own x/y. Shared by scr_CollisionHandler.gml (both for
//the player's own footprint and, with explicit coordinates, for the
//single tile ahead when checking horizontal push-back) and obj_camera's
//jump landing check, so all three agree on what surface is at any x/y.
//
//Uses global.block_lookup for an O(1) check per layer instead of
//scanning every loaded block instance (there can be thousands). Assumes
//solid blocks are always corner-anchored (hit_x1 = hit_y1 = 0), true for
//every current type (grass/sand/snow) -- a future off-center solid block
//would need this rewritten to also account for hit_x1/hit_y1.

var check_x, check_y;
if (argument_count > 0)
{
    check_x = argument0;
    check_y = argument1;
}
else
{
    check_x = x;
    check_y = y;
}

var tile_x = floor(check_x / 32);
var tile_y = floor(check_y / 32);

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

return support_z;
