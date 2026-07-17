///scr_GenerateChunk(chunk_cx, chunk_cy)
//Generates every block and decoration for one chunk (8x8 tiles) at the
//given chunk coordinate. Height/biome/decoration placement are all pure
//functions of world position (scr_GetHeightTier/scr_GetBiome and the
//deco hash below), so this works for any chunk coordinate, positive or
//negative, with no memory of what's been generated before -- that's what
//makes streaming/infinite generation possible. Player edits recorded in
//global.block_edits/global.chunk_extra are re-applied on top of the
//natural generation so breaking/placing persists across unload+reload.
//Every spawned instance starts at fade_alpha = 0 and ramps up in
//obj_block_parent's Step event, so chunks fade in instead of popping.

var chunk_cx = argument0;
var chunk_cy = argument1;

var chunk_size = global.chunk_tiles;
var biome = scr_GetBiome(chunk_cx, chunk_cy);

var origin_i = chunk_cx * chunk_size;   //tile index of this chunk's near corner
var origin_j = chunk_cy * chunk_size;

for (var di = 0; di < chunk_size; di++)
{
    var tile_x = origin_i + di;
    var xx = tile_x * 32;

    for (var dj = 0; dj < chunk_size; dj++)
    {
        var tile_y = origin_j + dj;
        var yy = tile_y * 32;

        var height_tier = scr_GetHeightTier(tile_x, tile_y);

        //neighbor tiers for the analytical burial check -- these work
        //even if the neighboring chunk hasn't been generated yet, since
        //height is a pure function of position
        var tier_w = scr_GetHeightTier(tile_x - 1, tile_y);
        var tier_e = scr_GetHeightTier(tile_x + 1, tile_y);
        var tier_n = scr_GetHeightTier(tile_x, tile_y - 1);
        var tier_s = scr_GetHeightTier(tile_x, tile_y + 1);

        for (var h = 0; h <= height_tier; h++)
        {
            var edit_key = scr_EncodeBlockKey(tile_x, tile_y, h);
            var block_type = biome;
            var skip = false;

            if (ds_map_exists(global.block_edits, edit_key))
            {
                var edit_value = ds_map_find_value(global.block_edits, edit_key);

                if (edit_value == 0)
                {
                    skip = true;
                }
                else
                {
                    block_type = edit_value;
                }
            }

            if (!skip)
            {
                var new_block = instance_create(xx, yy, block_type);
                new_block.z = h * 32;
                new_block.chunk_cx = chunk_cx;
                new_block.chunk_cy = chunk_cy;
                new_block.fade_alpha = 0;
                new_block.is_buried = (h < height_tier) && (tier_w >= h) && (tier_e >= h) && (tier_n >= h) && (tier_s >= h);

                //replace-or-add: a bare ds_map_add fails silently if a
                //stale entry exists, which would leave the lookup pointing
                //at the wrong instance -- newest always wins
                if (ds_map_exists(global.block_lookup, edit_key))
                {
                    ds_map_replace(global.block_lookup, edit_key, new_block);
                }
                else
                {
                    ds_map_add(global.block_lookup, edit_key, new_block);
                }
            }
        }

        //deterministic (not random()) tall-grass chance, so the same
        //tile always decides the same way across unload/reload -- only
        //the tile's presence is persistent, not whether a player broke
        //it (decoration edits aren't tracked, unlike solid blocks).
        //No tall grass in deserts.
        var deco_hash = frac(sin(tile_x * 127.1 + tile_y * 311.7 + global.deco_seed_x) * 43758.5453);

        if (deco_hash < 0.02 && biome != obj_sand_block)
        {
            var deco_x = xx + 16;
            var deco_y = yy + 16;
            var deco_z = height_tier * 32 + 32;

            if (instance_position(deco_x, deco_y, obj_tinted_cross) == noone)
            {
                var deco = instance_create(deco_x, deco_y, obj_tinted_cross);
                deco.z = deco_z;
                deco.chunk_cx = chunk_cx;
                deco.chunk_cy = chunk_cy;
                deco.fade_alpha = 0;
            }
        }
    }
}

//re-create any extra (above-natural, off-column) blocks the player
//placed in this chunk previously -- natural-column edits were already
//handled above via block_edits, this only covers positions the natural
//fill loop never visits
var chunk_key = scr_EncodeChunkKey(chunk_cx, chunk_cy);

if (ds_map_exists(global.chunk_extra, chunk_key))
{
    var extra_list = ds_map_find_value(global.chunk_extra, chunk_key);
    var extra_count = ds_list_size(extra_list);
    var seen = ds_map_create();

    for (var idx = 0; idx < extra_count; idx++)
    {
        var pos_key = ds_list_find_value(extra_list, idx);

        if (!ds_map_exists(seen, pos_key))
        {
            ds_map_add(seen, pos_key, 1);

            if (ds_map_exists(global.block_edits, pos_key))
            {
                var block_type = ds_map_find_value(global.block_edits, pos_key);

                if (block_type != 0)
                {
                    //decode pos_key back into tile_x/tile_y/layer_h
                    var remainder = pos_key;
                    var layer_h = remainder mod 1000;
                    remainder = (remainder - layer_h) / 1000;
                    var oy = remainder mod 200001;
                    var ox = (remainder - oy) / 200001;
                    var extra_tile_x = ox - 100000;
                    var extra_tile_y = oy - 100000;

                    var extra_block = instance_create(extra_tile_x * 32, extra_tile_y * 32, block_type);
                    extra_block.z = layer_h * 32;
                    extra_block.chunk_cx = chunk_cx;
                    extra_block.chunk_cy = chunk_cy;
                    extra_block.fade_alpha = 0;
                    extra_block.is_buried = false;   //rarely fully enclosed; scr_UpdateBuriedAround keeps this correct as the player builds around it

                    if (ds_map_exists(global.block_lookup, pos_key))
                    {
                        ds_map_replace(global.block_lookup, pos_key, extra_block);
                    }
                    else
                    {
                        ds_map_add(global.block_lookup, pos_key, extra_block);
                    }
                }
            }
        }
    }

    ds_map_destroy(seen);
}
