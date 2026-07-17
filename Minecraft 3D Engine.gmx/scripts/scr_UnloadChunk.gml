///scr_UnloadChunk(chunk_cx, chunk_cy)
//Destroys every block/decoration instance belonging to the given chunk.
//Nothing is lost -- global.block_edits/global.chunk_extra already
//capture everything needed to recreate this chunk exactly via
//scr_GenerateChunk if the player comes back. Solid blocks are also
//removed from global.block_lookup first -- leaving a stale entry
//pointing at a destroyed instance would break scr_FindSupportHeight/
//scr_Raycast's O(1) lookups.

var target_cx = argument0;
var target_cy = argument1;

with (obj_block_parent)
{
    if (chunk_cx == target_cx && chunk_cy == target_cy)
    {
        if (is_solid)
        {
            var lookup_key = scr_EncodeBlockKey(x / 32, y / 32, z / 32);

            // Ownership check: only delete the entry if it still points
            // at this exact instance. If a duplicate ever ended up
            // sharing this cell, blindly deleting would orphan the
            // survivor (visible but collisionless).
            if (ds_map_exists(global.block_lookup, lookup_key))
            {
                if (ds_map_find_value(global.block_lookup, lookup_key) == id)
                {
                    ds_map_delete(global.block_lookup, lookup_key);
                }
            }
        }

        instance_destroy();
    }
}
