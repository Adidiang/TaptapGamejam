extends RefCounted
static func walk(state: CastleExploration,point: Vector2) -> void:
	state.move(0,point.y-state.local_position().y)
	state.move(point.x-state.local_position().x,0)
static func left_landing(state: CastleExploration) -> void:
	if state.player_height>6:
		if state.local_position().x>3:
			walk(state,Vector2(3.85,2.6))
			walk(state,Vector2(-3.75,2.6))
		walk(state,Vector2(-3.75,-1.35))
	else:
		walk(state,Vector2(state.local_position().x,-1.35))
		walk(state,Vector2(-3.75,-1.35))
static func stair_level(state: CastleExploration,level: int) -> void:
	left_landing(state)
	if level==1 and state.player_height<1:
		walk(state,Vector2(-3.75,1.35))
		walk(state,Vector2(3.4,1.35))
		walk(state,Vector2(3.4,-1.35))
		walk(state,Vector2(-3.75,-1.35))
	elif level==0 and state.player_height>6:
		walk(state,Vector2(3.4,-1.35))
		walk(state,Vector2(3.4,1.35))
		walk(state,Vector2(-3.75,1.35))
		walk(state,Vector2(-3.75,-1.35))
static func cross(state: CastleExploration,destination: int) -> void:
	for link in state.room().ports:
		if link.to!=destination:continue
		if state.room().kind=="stairs":
			stair_level(state,link.level)
			if link.side>0:
				if link.level==1:walk(state,Vector2(-3.75,2.6));walk(state,Vector2(3.85,2.6))
				walk(state,Vector2(3.85,-1.346))
			else:walk(state,Vector2(-3.85,-1.346))
		else:
			state._set_local(state.definition().arrival(link.side))
		state.move(link.side*1.0)
		return
