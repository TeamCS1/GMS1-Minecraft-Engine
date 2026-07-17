///scr_RecomputeBuriedAt(px, py, pz)
//Looks up the solid block instance at the given position via
//global.block_lookup (if any) and recomputes its is_buried from its own
//6 neighbors. Used by scr_UpdateBuriedAround for the handful of
//positions actually affected by a single placement/break -- O(1) lookups
//throughout, no instance scanning.

var px = argument0;
var py = argument1;
var pz = argument2;

var key = scr_EncodeBlockKey(px / 32, py / 32, pz / 32);

if (ds_map_exists(global.block_lookup, key))
{
    var inst = ds_map_find_value(global.block_lookup, key);

    inst.is_buried = scr_IsSolidBlockAt(px - 32, py, pz)
        && scr_IsSolidBlockAt(px + 32, py, pz)
        && scr_IsSolidBlockAt(px, py - 32, pz)
        && scr_IsSolidBlockAt(px, py + 32, pz)
        && scr_IsSolidBlockAt(px, py, pz - 32)
        && scr_IsSolidBlockAt(px, py, pz + 32);
}
