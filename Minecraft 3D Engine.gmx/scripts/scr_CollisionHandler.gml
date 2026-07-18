
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
//
//Grounded only (jump == false): climbing up a tier has always worked by
//drifting laterally onto the taller tile's footprint mid-jump, while
//still below its top, then getting snapped up once the falling-phase
//landing check (obj_camera) finds the new, higher support underneath --
//see Jumping in CLAUDE.md. A single jump's arc doesn't actually rise the
//full tier height before that lateral drift happens, so blocking it
//during a jump the same way as while grounded made every tier climb
//impossible, not just wall-bumping.
if (jump == false)
{
    if (hspeed != 0)
    {
        var ahead_x = scr_FindSupportHeightAt(x + hspeed, y);
        if (ahead_x != -1 && ahead_x > z)
        {
            hspeed = 0;
        }
    }

    if (vspeed != 0)
    {
        var ahead_y = scr_FindSupportHeightAt(x, y + vspeed);
        if (ahead_y != -1 && ahead_y > z)
        {
            vspeed = 0;
        }
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
        //hitting a block from the side, below its top. While grounded,
        //the horizontal push-back above already stopped the player from
        //walking into this position in most cases -- this branch is what
        //still catches it otherwise: mid-jump drift onto a taller tile
        //(push-back is skipped while jumping, see above -- this is the
        //expected in-between state of a tier climb, not a bug), or a
        //block appearing underneath some other way (placed by the player
        //while standing there, edit replay on chunk reload, etc.). Either
        //way, just refuse to snap z upward early.
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
//Each layer is a consistent 32 units apart in player_height (see
//scr_FindSupportHeight), so this divides out exactly with no rounding.
global.layer = 1 + (player_height - 80) / 32;
