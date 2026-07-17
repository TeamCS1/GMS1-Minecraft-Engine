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

            with (obj_grass_block)
            {
                if (ray_x >= x && ray_x < x + 32 && ray_y >= y && ray_y < y + 32 && ray_z >= z && ray_z < z + 32)
                {
                    hit_block = id;
                }
            }

            if (hit_block == noone)
            with (obj_sand_block)
            {
                if (ray_x >= x && ray_x < x + 32 && ray_y >= y && ray_y < y + 32 && ray_z >= z && ray_z < z + 32)
                {
                    hit_block = id;
                }
            }

            if (hit_block == noone)
            with (obj_snow_block)
            {
                if (ray_x >= x && ray_x < x + 32 && ray_y >= y && ray_y < y + 32 && ray_z >= z && ray_z < z + 32)
                {
                    hit_block = id;
                }
            }

            // Tall grass decoration: centered on its own x/y instead of a corner,
            // so its box is offset by half a cell.
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

