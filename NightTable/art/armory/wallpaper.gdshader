shader_type spatial;
render_mode cull_disabled;
varying vec3 world_pos;
varying vec3 world_normal;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec2 p=vec2(abs(world_normal.x)>.5?world_pos.z:world_pos.x,world_pos.y);
 vec2 q=p*vec2(2.5,2.0); q.x+=mod(floor(q.y),2.0)*.5;
 vec2 v=fract(q)-.5;
 float diamond=abs(v.x)*1.1+abs(v.y);
 float border=1.0-smoothstep(.012,.033,abs(diamond-.37));
 float stem=exp(-abs(v.x)*90.0)*(1.0-smoothstep(.28,.42,abs(v.y)));
 float leaves=exp(-abs(abs(v.x)-(.11+.075*sin(v.y*22.0)))*60.0)*(1.0-smoothstep(.19,.34,abs(v.y)));
 float motif=clamp(border*.48+stem*.6+leaves*.65,0.0,1.0);
 float stripe=.5+.5*sin(p.x*62.83);
 float grain=fract(sin(dot(p,vec2(123.34,345.56)))*43578.3);
 ALBEDO=mix(vec3(.19,.34,.30),vec3(.48,.44,.30),motif)*(.92+.06*stripe+.05*grain);
 ROUGHNESS=.9;
}

