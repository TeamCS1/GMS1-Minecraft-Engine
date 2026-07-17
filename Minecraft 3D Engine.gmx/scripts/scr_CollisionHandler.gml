
//handle collisions with blocks
//
//Instead of one hardcoded z threshold per block type, find the highest
//solid block (any type, via obj_block_parent) under the player's x/y and
//derive the height standing on it would give: the block's own top
//(z + 32) plus the player's 32-unit eye offset above whatever they stand
//on -- the same offset sand was already tuned to (top 64 -> height 96).
//This supports any number of stacked layers: a block placed on top of
//another block (its own z at or above the lower block's top) just
//produces a taller "support_z", with no extra code needed per layer.

var support_z = 80;   //ground level when nothing solid is underneath
var found_block = false;

with (obj_block_parent)
{
    if (is_solid && other.x >= x + hit_x1 && other.x < x + hit_x1 + 32 && other.y >= y + hit_y1 && other.y < y + hit_y1 + 32)
    {
        found_block = true;

        var top = z + 32 + 32;
        if (top > support_z)
        {
            support_z = top;
        }
    }
}

if (found_block && jump == false)
{
    if (z < support_z)
    {
        //hitting the block from the side, below its top
        move_bounce_all(false);
        show_debug_message("Colliding with a block from the side!")
    }
    else
    {
        z = support_z;
        player_height = support_z;
        show_debug_message("At Z = " + string(support_z))
    }
}

//if the player is not over any solid block, drop back to ground level
if (!found_block && jump == false)
{
    if (z > 80)
    {
        z = 80;
        player_height = 80;
        show_debug_message("Reset Height to 80")
    }
}

//layer handler: 1 = ground, 2 = one block up, 3 = two blocks up, ...
global.layer = 1 + round((player_height - 80) / 16);
