///scr_FindSupportHeightAt(check_x, check_y)
//Same as scr_FindSupportHeight(), but for an arbitrary x/y instead of the
//calling instance's own -- used by scr_CollisionHandler.gml's horizontal
//push-back to check the single tile the player is about to step into,
//without moving the player there first. Kept as a separate script (with
//a required 2-argument signature) rather than an optional argument on
//scr_FindSupportHeight() because GMS1.4 requires a script's argument
//count to always match its call sites, regardless of any runtime
//argument_count branching inside it.

var check_x = argument0;
var check_y = argument1;

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

if (support_z < 80)
{
    support_z = 80;
}

return support_z
