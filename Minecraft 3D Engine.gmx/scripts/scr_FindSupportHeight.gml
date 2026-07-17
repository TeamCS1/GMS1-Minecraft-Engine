///scr_FindSupportHeight()
//Returns the standing height the tallest solid block under the calling
//instance's x/y would give (that block's own top, z + 32, plus the
//player's 32-unit eye offset), or -1 if no solid block is there. Shared
//by scr_CollisionHandler.gml and obj_camera's jump landing check so both
//agree on what surface is currently underneath, at any elevation.

var support_z = -1;

with (obj_block_parent)
{
    if (is_solid && other.x >= x + hit_x1 && other.x < x + hit_x1 + 32 && other.y >= y + hit_y1 && other.y < y + hit_y1 + 32)
    {
        var top = z + 32 + 32;
        if (top > support_z)
        {
            support_z = top;
        }
    }
}

// Never return a standing height below the flat ground baseline (80).
// obj_biome_gen places grass/snow at z=0 (top 32), which under the plain
// top+32 formula would sink the player to 64 -- lower than intended.
// Sand's already-tuned 96 (z=32, top 64) is unaffected since it's above 80.
if (support_z != -1 && support_z < 80)
{
    support_z = 80;
}

return support_z;
