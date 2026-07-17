
//handle collisions with blocks
//
//scr_FindSupportHeight() finds the standing height the tallest solid
//block under the player's x/y would give (or -1 if none), no matter how
//far below or above the player that block actually is -- see that script
//for details. React to it based on the gap to the player's current z:
//bump a taller block's side, snap onto one close enough to actually be
//standing on, or start falling (the same arc a jump uses) if it's far
//below -- e.g. after walking off the edge of a tall stack.

var support_z = scr_FindSupportHeight();
if (support_z == -1)
{
    support_z = 80;   //ground level fallback when nothing solid is underneath
}

if (jump == false)
{
    if (z < support_z)
    {
        //hitting a block from the side, below its top
        move_bounce_all(false);
    }
    else if (z - support_z > 32)
    {
        //well above whatever's below -- walked off an edge, start falling
        //using the same gravity arc as a jump, just with no initial
        //upward boost
        jump = true;
        jumpHeightModifier = 0;
    }
    else
    {
        z = support_z;
        player_height = support_z;
    }
}

//layer handler: 1 = ground, 2 = one block up, 3 = two blocks up, ...
global.layer = 1 + round((player_height - 80) / 16);
