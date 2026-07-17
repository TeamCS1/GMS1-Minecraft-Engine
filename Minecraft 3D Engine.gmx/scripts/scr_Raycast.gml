with obj_camera
{
    if instance_number(obj_ray_cast) < 1
    {
        // March a ray from the eye along the actual look vector (lookx/looky/lookz,
        // computed each step from facingDir/zdir) instead of guessing a cardinal
        // direction from movement heading.
        var reach = 160;  // max interaction distance (5 blocks)
        var step = 8;     // smaller than block size (32) so hits aren't skipped

        var ray_x = x;
        var ray_y = y;
        var ray_z = z;

        var prev_x = ray_x;
        var prev_y = ray_y;
        var prev_z = ray_z;

        var hit_block = noone;
        var dist = 0;

        while (dist < reach && hit_block == noone)
        {
            prev_x = ray_x;
            prev_y = ray_y;
            prev_z = ray_z;

            ray_x += lookx * step;
            ray_y += looky * step;
            ray_z += lookz * step;
            dist += step;

            // Solid cube blocks: O(1) lookup instead of scanning every loaded
            // instance (there can be thousands) -- see global.block_lookup.
            if (hit_block == noone)
            {
                var sample_key = scr_EncodeBlockKey(floor(ray_x / 32), floor(ray_y / 32), floor(ray_z / 32));

                if (ds_map_exists(global.block_lookup, sample_key))
                {
                    hit_block = ds_map_find_value(global.block_lookup, sample_key);
                }
            }

            // obj_tinted_cross isn't grid-corner-aligned (hit_x1/hit_y1 = -16,
            // centered) so it can't share the tile-indexed lookup above -- but
            // there are far fewer of them than solid blocks, so a small scan
            // here is cheap.
            if (hit_block == noone)
            with (obj_tinted_cross)
            {
                if (ray_x >= x - 16 && ray_x < x + 16 && ray_y >= y - 16 && ray_y < y + 16 && ray_z >= z && ray_z < z + 32)
                {
                    hit_block = id;
                }
            }
        }

        if (hit_block != noone)
        {
            // Place the reticle at the last empty cell before the hit, so
            // breaking targets hit_block and placing adds an adjacent block.
            var place_z = floor(prev_z / 32) * 32;
            var new_ray = instance_create(prev_x, prev_y, obj_ray_cast);
            new_ray.z_offset = (place_z - 32) + z_scroll_offset;
            new_ray.target_block = hit_block;

            directionText = object_get_name(hit_block.object_index);
        }
    }

    raycastDelay++;

    if raycastDelay >= 8
    {
        instance_destroy(obj_ray_cast, 1);
        raycastDelay = 0;
    }
}

