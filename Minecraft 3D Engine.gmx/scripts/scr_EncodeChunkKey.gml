///scr_EncodeChunkKey(chunk_cx, chunk_cy)
//Packs a chunk coordinate into a single real number, used as the key
//into global.loaded_chunks and global.chunk_extra. Same offset scheme as
//scr_EncodeBlockKey -- supports chunk coordinates roughly +-100000
//(world positions of roughly +-25 million units at 8-tile chunks).

var chunk_cx = argument0;
var chunk_cy = argument1;

return (chunk_cx + 100000) * 200001 + (chunk_cy + 100000);
