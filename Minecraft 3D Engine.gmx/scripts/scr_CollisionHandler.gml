
//handle collisions with blocks
if position_meeting(x, y, obj_sand_block)
{
    if z > 79 && z < 96 && jump == false
    {
        if z < 96
        {
            //hitting the sand from the side
            move_bounce_all(false);
            show_debug_message("Colliding with sand from the side!")
        }
    }
    
    else if z >= 96
    {
        z = 96
        player_height = 96;
        show_debug_message("At Y = 96")   
    }
}

//if the player is not on the same block as sand and jump is false
if !position_meeting(x, y, obj_sand_block) && jump == false
{
    if z >= 96
    {
        z = 80
        player_height = 80;
        show_debug_message("Reset Height to 80")   
    }
}

//layer handler
if z == 80
{
    global.layer = 1;
}

else if z == 96
{
    global.layer = 2;    
}
