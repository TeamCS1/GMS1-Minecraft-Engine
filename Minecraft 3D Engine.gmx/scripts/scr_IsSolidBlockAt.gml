///scr_IsSolidBlockAt(cx, cy, cz)
//Returns true if a solid block instance sits exactly at the given grid
//position. Used only for the occasional runtime burial update when a
//block is placed or destroyed (scr_UpdateBuriedAround) -- world
//generation uses the cheaper analytical height-tier formula in
//obj_biome_gen instead, since this does a full instance scan.

var cx = argument0;
var cy = argument1;
var cz = argument2;
var found = false;

with (obj_block_parent)
{
    if (is_solid && x == cx && y == cy && z == cz)
    {
        found = true;
    }
}

return found;
