with obj_camera
{
    if instance_number(obj_ray_cast) < 1
    {
        var ex, ey;
        ex = instance_nearest(x, y, obj_grass_block.x);
        ey = instance_nearest(x, y, obj_grass_block.y);
        
        if distance_to_object(obj_grass_block) < 65
        {
            if direction > 0 && direction < 44  //face up
            {
                directionText = "East"
                instance_create(ex.x + 64,ey.y, obj_ray_cast);
            }
            
            else if direction > 45 && direction < 135  //face up
            {
                directionText = "North"
                instance_create(ex.x,ey.y - 64, obj_ray_cast);
            }
            
            else if direction > 136 && direction < 225  //face left
            {
                directionText = "West"
                instance_create(ex.x - 64,ey.y, obj_ray_cast);
            }
            
            else if direction > 226 && direction < 315  //face down
            {
                directionText = "South"
                instance_create(ex.x,ey.y, obj_ray_cast);
            }
            
            else if direction > 316 && direction < 360  //face right
            {
                directionText = "East"
                instance_create(ex.x + 64,ey.y, obj_ray_cast);
            }
        
        }         
    }
    
    raycastDelay++
    
    if raycastDelay >= 9
    {
        instance_destroy(obj_ray_cast,1)
        raycastDelay = 0;
    }
}
