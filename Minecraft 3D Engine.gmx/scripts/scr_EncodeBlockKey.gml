///scr_EncodeBlockKey(tile_x, tile_y, layer_h)
//Packs a tile position + stack layer into a single real number, used as
//the key into global.block_edits. Avoids GML 1.4's lack of string
//splitting -- decoding is plain arithmetic (mod/div) instead of string
//parsing. Supports tile indices roughly +-100000 (world positions of
//roughly +-3.2 million units) and up to 999 stacked layers, which is
//effectively unlimited for actual play.

var tile_x = argument0;
var tile_y = argument1;
var layer_h = argument2;

var ox = tile_x + 100000;
var oy = tile_y + 100000;

return (ox * 200001 + oy) * 1000 + layer_h;
