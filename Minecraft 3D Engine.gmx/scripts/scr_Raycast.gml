with obj_camera
{
    if instance_number(obj_ray_cast) < 1
    {
        var nearest_block = noone;
        var closest_dist = 999999;

        // Check grass block
        var g = instance_nearest(x, y, obj_grass_block);
        if (g != noone)
        {
            var dist = point_distance(x, y, g.x, g.y);
            if (dist < closest_dist)
            {
                closest_dist = dist;
                nearest_block = g;
            }
        }

        // Check sand block
        var s = instance_nearest(x, y, obj_sand_block);
        if (s != noone)
        {
            var dist = point_distance(x, y, s.x, s.y);
            if (dist < closest_dist)
            {
                closest_dist = dist;
                nearest_block = s;
            }
        }

        // Check snow block
        var sn = instance_nearest(x, y, obj_snow_block);
        if (sn != noone)
        {
            var dist = point_distance(x, y, sn.x, sn.y);
            if (dist < closest_dist)
            {
                closest_dist = dist;
                nearest_block = sn;
            }
        }

        if (nearest_block != noone && closest_dist < 64)
        {
            var ex = nearest_block.x;
            var ey = nearest_block.y;

            if direction >= 0 && direction < 45  // East
            {
                directionText = "East";
                var new_ray = instance_create(ex + 64, ey, obj_ray_cast);
                new_ray.z_offset = z_scroll_offset;
            }
            else if direction >= 45 && direction < 135  // North
            {
                directionText = "North";
                var new_ray = instance_create(ex, ey - 64, obj_ray_cast);
                new_ray.z_offset = z_scroll_offset;
            }
            else if direction >= 135 && direction < 225  // West
            {
                directionText = "West";
                var new_ray = instance_create(ex - 64, ey, obj_ray_cast);
                new_ray.z_offset = z_scroll_offset;
            }
            else if direction >= 225 && direction < 315  // South
            {
                directionText = "South";
                var new_ray = instance_create(ex, ey + 64, obj_ray_cast);
                new_ray.z_offset = z_scroll_offset;
            }
            else if direction >= 315 && direction <= 360  // East (wrap around)
            {
                directionText = "East";
                var new_ray = instance_create(ex + 64, ey, obj_ray_cast);
                new_ray.z_offset = z_scroll_offset;
            }
        }
    }

    raycastDelay++;

    if raycastDelay >= 8
    {
        instance_destroy(obj_ray_cast, 1);
        raycastDelay = 0;
    }
}

