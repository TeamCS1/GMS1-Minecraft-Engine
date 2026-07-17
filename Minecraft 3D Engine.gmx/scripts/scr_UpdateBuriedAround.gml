///scr_UpdateBuriedAround(cx, cy, cz)
//Call right after placing or destroying a block at (cx, cy, cz):
//recomputes is_buried for whatever solid block now sits there (if any)
//and for each of its 6 neighbors, since burial can only have changed for
//blocks touching this cell. Uses scr_IsSolidBlockAt, so this is only for
//the occasional runtime update -- not called every frame or for the bulk
//of world generation (see obj_biome_gen for that).

var cx = argument0;
var cy = argument1;
var cz = argument2;

with (obj_block_parent)
{
    if (is_solid)
    {
        var is_target = (x == cx && y == cy && z == cz)
            || (x == cx - 32 && y == cy && z == cz)
            || (x == cx + 32 && y == cy && z == cz)
            || (x == cx && y == cy - 32 && z == cz)
            || (x == cx && y == cy + 32 && z == cz)
            || (x == cx && y == cy && z == cz - 32)
            || (x == cx && y == cy && z == cz + 32);

        if (is_target)
        {
            is_buried = scr_IsSolidBlockAt(x - 32, y, z)
                && scr_IsSolidBlockAt(x + 32, y, z)
                && scr_IsSolidBlockAt(x, y - 32, z)
                && scr_IsSolidBlockAt(x, y + 32, z)
                && scr_IsSolidBlockAt(x, y, z - 32)
                && scr_IsSolidBlockAt(x, y, z + 32);
        }
    }
}
