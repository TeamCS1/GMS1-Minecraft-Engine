//made this because I hate that I have to set the fog vars every time I disable/enable it somewhere
if (argument0){
    d3d_set_fog(true,c_skyfog,global.fog_near,global.fog_far);
    } else {
    d3d_set_fog(false,c_white,0,100);
    }
