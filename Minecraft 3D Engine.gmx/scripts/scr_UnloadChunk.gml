///scr_UnloadChunk(chunk_cx, chunk_cy)
//Destroys every block/decoration instance belonging to the given chunk.
//Nothing is lost -- global.block_edits/global.chunk_extra already
//capture everything needed to recreate this chunk exactly via
//scr_GenerateChunk if the player comes back.

var target_cx = argument0;
var target_cy = argument1;

with (obj_block_parent)
{
    if (chunk_cx == target_cx && chunk_cy == target_cy)
    {
        instance_destroy();
    }
}
