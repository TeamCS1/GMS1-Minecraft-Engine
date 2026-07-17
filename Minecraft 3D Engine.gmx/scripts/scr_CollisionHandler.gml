
//handle collisions with blocks
//
//scr_FindSupportHeight() finds the standing height the tallest solid
//block under the player would give (or -1 if none) -- see that script
//for how blocks of any type/elevation are combined. This just reacts to
//the result: step up onto it, bump its side, or fall back to flat ground.

var support_z = scr_FindSupportHeight();
var found_block = (support_z != -1);

if (!found_block)
{
    support_z = 80;   //ground level when nothing solid is underneath
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

//if the player walked off an edge (no block underneath, above ground),
//start falling using the same gravity arc as a jump -- jumpHeightModifier
//starts at 0 instead of 5, so there's no upward boost, just a fall that
//speeds up over time and lands via scr_FindSupportHeight() the same way
//a jump's descent already does.
if (!found_block && jump == false)
{
    if (z > 80)
    {
        jump = true;
        jumpHeightModifier = 0;
    }
}

//layer handler: 1 = ground, 2 = one block up, 3 = two blocks up, ...
global.layer = 1 + round((player_height - 80) / 16);
