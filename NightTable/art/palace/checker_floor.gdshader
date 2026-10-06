shader_type spatial;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world_pos.xz/.78;
 vec2 cell=floor(p);
 float check=mod(cell.x+cell.y,2.0);
 vec3 color=mix(vec3(.065,.052,.047),vec3(.22,.177,.17),check);
 vec2 uv=fract(p);
 float seam=1.0-smoothstep(.0,.011,min(min(uv.x,1.0-uv.x),min(uv.y,1.0-uv.y)));
 float grain=sin(world_pos.x*80.0+sin(world_pos.z*8.0)*4.0)*.0015;
 ALBEDO=mix(color+grain,vec3(.045,.031,.024),seam*.65);
 ROUGHNESS=.43+grain;
}
