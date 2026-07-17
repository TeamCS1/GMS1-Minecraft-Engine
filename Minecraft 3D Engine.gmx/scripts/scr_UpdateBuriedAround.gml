///scr_UpdateBuriedAround(cx, cy, cz)
//Call right after placing or destroying a block at (cx, cy, cz):
//recomputes is_buried for whatever solid block now sits there (if any)
//and for each of its 6 neighbors, since burial can only have changed for
//blocks touching this cell. Pure O(1) lookups via
//global.block_lookup/scr_RecomputeBuriedAt -- no instance scanning, so
//this stays cheap even with thousands of blocks loaded.

var cx = argument0;
var cy = argument1;
var cz = argument2;

scr_RecomputeBuriedAt(cx, cy, cz);
scr_RecomputeBuriedAt(cx - 32, cy, cz);
scr_RecomputeBuriedAt(cx + 32, cy, cz);
scr_RecomputeBuriedAt(cx, cy - 32, cz);
scr_RecomputeBuriedAt(cx, cy + 32, cz);
scr_RecomputeBuriedAt(cx, cy, cz - 32);
scr_RecomputeBuriedAt(cx, cy, cz + 32);
