shader_type spatial;
uniform sampler2D stone : source_color, repeat_enable, filter_linear_mipmap;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world_pos.xz/1.15;
 float check=mod(floor(p.x)+floor(p.y),2.0);
 vec3 a=vec3(.3,.43,.38),b=vec3(.65,.6,.5);
 vec2 edge=min(fract(p),1.0-fract(p));
 float seam=smoothstep(.004,.012,min(edge.x,edge.y));
 float stone_value=dot(texture(stone,p*.37).rgb,vec3(.333));
 vec3 color=mix(a,b,check)*mix(.88,1.12,stone_value);
 float side=abs(world_pos.z);
 if(side>1.7&&side<1.82)color=vec3(.5,.38,.19);
 if(side>1.82&&side<2.0)color=vec3(.18,.29,.27);
 if(side<1.7){
  float border=smoothstep(1.50,1.54,side);
  float weave=sin(world_pos.x*190.0)*sin(world_pos.z*190.0)*.012;
  color=mix(vec3(.27,.33,.32),vec3(.57,.47,.32),border*.7)+weave;
  seam=1.0;
 }
 ALBEDO=mix(vec3(.2,.23,.22),color,seam);
 ROUGHNESS=.62; SPECULAR=.25;
}
