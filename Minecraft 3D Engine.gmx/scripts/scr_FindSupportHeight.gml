///scr_FindSupportHeight()
//Returns the standing height the tallest solid block under the calling
//instance's own x/y would give (that block's own top, z + 32, plus the
//player's 48-unit eye offset), or -1 if no solid block is there. Shared
//by scr_CollisionHandler.gml and obj_camera's jump landing check so both
//agree on what surface is currently underneath, at any elevation. For
//an arbitrary (not-self) x/y -- e.g. the tile ahead when checking
//horizontal push-back -- see scr_FindSupportHeightAt(check_x, check_y)
//instead; GMS1.4 requires a script's argument count to always match its
//call sites, so this can't just take optional arguments.
//
//The 48-unit offset (rather than the more obvious-looking 32) is
//deliberate: it's what makes the formula give exactly 80 for the lowest
//layer (h=0: 0 + 32 + 48 = 80) with no separate ground-baseline clamp
//needed, so every layer above it steps up by a consistent 32 units too.
//An earlier version used a 32-unit offset plus a "clamp up to 80"
//special case for the lowest layer -- that clamp made layer 1 alone
//feel taller (an extra 16 units of eye height) than every layer above
//it, since only layer 1 got the clamped-up value while real stacked
//blocks used the plain unclamped formula. Reported as "layer 2 onward
//feels shorter than layer 1" and fixed by using the same 48-unit offset
//everywhere instead.
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

// support_h * 32 + 32 (the block's own top) + 48 (eye offset above the
// surface); h=0 always gives exactly 80, so no separate clamp is needed.
var support_z = support_h * 32 + 32 + 48;

return support_z
