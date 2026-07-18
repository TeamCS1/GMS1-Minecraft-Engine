
//handle collisions with blocks
//
//scr_FindSupportHeight() finds the standing height the tallest solid
//block under the player's x/y would give (or -1 if none), no matter how
//far below or above the player that block actually is -- see that script
//for details. React to it based on the gap to the player's current z:
//bump a taller block's side, snap onto one close enough to actually be
//standing on, or start falling (the same arc a jump uses) if it's far
//below -- e.g. after walking off the edge of a tall stack.

//Horizontal push-back: stop the player from walking into the side of a
//block taller than their current eye height, before the engine's
//automatic hspeed/vspeed motion applies this step -- same practical
//effect move_bounce_all(false) used to give (can't walk through a wall),
//but checking only the single tile actually being stepped into via
//global.block_lookup (O(1)) instead of a room-wide scan against every
//solid-flagged instance (see obj_sand_block/obj_snow_block for why that
//scan was removed). Each axis is checked independently so the player can
//still slide along a wall instead of stopping dead on a diagonal.
if (hspeed != 0)
{
    var ahead_x = scr_FindSupportHeight(x + hspeed, y);
    if (ahead_x != -1 && ahead_x > z)
    {
        hspeed = 0;
    }
}

if (vspeed != 0)
{
    var ahead_y = scr_FindSupportHeight(x, y + vspeed);
    if (ahead_y != -1 && ahead_y > z)
    {
        vspeed = 0;
    }
}

var support_z = scr_FindSupportHeight();
if (support_z == -1)
{
    support_z = 80;   //ground level fallback when nothing solid is underneath
}

if (jump == false)
{
    if (z < support_z)
    {
        //hitting a block from the side, below its top. Normally the
        //horizontal push-back above already stopped the player from
        //walking into this position in the first place -- this branch is
        //what still catches it if a block appears underneath some other
        //way (placed by the player while standing there, edit replay on
        //chunk reload, etc.) by refusing to snap z upward early.
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
