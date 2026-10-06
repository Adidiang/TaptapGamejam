shader_type spatial;
uniform sampler2D wall : source_color, repeat_enable, filter_linear_mipmap;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world_pos.xy*1.15;
 p.x+=mod(floor(p.y),2.0)*.5;
 vec2 q=fract(p)-.5;
 float petal=abs(q.x)*1.4+abs(q.y)*.9;
 float line=1.0-smoothstep(.025,.055,abs(petal-.32));
 float dotmark=1.0-smoothstep(.045,.065,length(q));
 float tex=dot(texture(wall,world_pos.xy*.22).rgb,vec3(.333));
 ALBEDO=mix(vec3(.28,.43,.39),vec3(.65,.59,.4),max(line*.55,dotmark*.65))*mix(.88,1.12,tex);
 ROUGHNESS=1.0; SPECULAR=0.0;
}
