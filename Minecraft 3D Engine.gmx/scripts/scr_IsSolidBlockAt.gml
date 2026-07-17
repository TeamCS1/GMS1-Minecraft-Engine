///scr_IsSolidBlockAt(cx, cy, cz)
//Returns true if a solid block instance sits exactly at the given grid
//position. Used for the occasional runtime burial update when a block
//is placed or destroyed (scr_UpdateBuriedAround) -- world generation
//uses the cheaper analytical height-tier formula in scr_GenerateChunk
//instead. O(1) via global.block_lookup rather than an instance scan.

var cx = argument0;
var cy = argument1;
var cz = argument2;

var key = scr_EncodeBlockKey(cx / 32, cy / 32, cz / 32);

return ds_map_exists(global.block_lookup, key);
