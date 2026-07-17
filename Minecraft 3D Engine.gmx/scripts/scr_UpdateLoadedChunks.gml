///scr_UpdateLoadedChunks()
//Called whenever the player crosses into a new chunk (see obj_biome_gen's
//Step event) -- loads any chunk within range that isn't loaded yet, and
//unloads any chunk that's now well out of range. This is the mechanism
//that makes the world stream in/out instead of being generated all at
//once, and that makes it effectively infinite (no fixed area is ever
//assumed -- chunks generate for whatever coordinate is reached).

var chunk_size_units = global.chunk_tiles * 32;
var player_cx = floor(obj_camera.x / chunk_size_units);
var player_cy = floor(obj_camera.y / chunk_size_units);

var load_radius = ceil(global.renderDistance / chunk_size_units) + 1;
var unload_radius = load_radius + 1;   //hysteresis so chunks don't thrash right at the load edge

for (var dx = -load_radius; dx <= load_radius; dx++)
{
    for (var dy = -load_radius; dy <= load_radius; dy++)
    {
        var cx = player_cx + dx;
        var cy = player_cy + dy;
        var key = scr_EncodeChunkKey(cx, cy);

        if (!ds_map_exists(global.loaded_chunks, key))
        {
            scr_GenerateChunk(cx, cy);
            ds_map_add(global.loaded_chunks, key, 1);
        }
    }
}

//collect out-of-range chunks first, then unload in a second pass --
//deleting from global.loaded_chunks while iterating it with
//find_first/find_next is not safe
var to_unload = ds_list_create();
var chunk_count = ds_map_size(global.loaded_chunks);
var check_key = ds_map_find_first(global.loaded_chunks);

for (var n = 0; n < chunk_count; n++)
{
    var oy = check_key mod 200001;
    var ox = (check_key - oy) / 200001;
    var loaded_cx = ox - 100000;
    var loaded_cy = oy - 100000;

    if (abs(loaded_cx - player_cx) > unload_radius || abs(loaded_cy - player_cy) > unload_radius)
    {
        ds_list_add(to_unload, check_key);
    }

    check_key = ds_map_find_next(global.loaded_chunks, check_key);
}

var unload_count = ds_list_size(to_unload);
for (var idx = 0; idx < unload_count; idx++)
{
    var key = ds_list_find_value(to_unload, idx);
    var oy = key mod 200001;
    var ox = (key - oy) / 200001;
    var loaded_cx = ox - 100000;
    var loaded_cy = oy - 100000;

    scr_UnloadChunk(loaded_cx, loaded_cy);
    ds_map_delete(global.loaded_chunks, key);
}

ds_list_destroy(to_unload);
