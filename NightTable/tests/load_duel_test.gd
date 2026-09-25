extends RefCounted

var verify: Callable
var serial := 10000

func number(value: int = 5, cost: int = 2) -> Dictionary:
	serial += 1
	return CombatCatalog.number_card(value,cost).instance(serial)

func function(index: int) -> Dictionary:
	serial += 1
	return CombatCatalog.function_card(index).instance(serial)

func fresh() -> LoadDuel:
	var d := LoadDuel.new()
	var cards: Array[CombatCard] = []
	for i in range(12): cards.append(CombatCatalog.number_card(5,2))
	d.start(cards,cards,9)
	return d

func test(check: Callable) -> void:
	verify = check
	var d := fresh()
	verify.call(d.sides[0].numbers.size()==2 and d.sides[1].numbers.size()==2,"two initial cards for both")
	verify.call(not d.draw(0) and not d.stop(0),"opening operation cannot draw or stop")
	verify.call(not d.end_turn(1),"wrong actor rejected")
	d.end_turn(0)
	verify.call(d.active==1 and d.phase==LoadDuel.Phase.ACTION,"opponent opening no extra draw")
	d.end_turn(1)
	verify.call(d.active==0 and d.phase==LoadDuel.Phase.DECIDE,"next turn must choose draw/stop")
	d.draw(0)
	verify.call(not d.draw(0) and d.sides[0].numbers.size()==3,"exactly one draw per turn")
	d.sides[0].functions.assign([function(0),function(1)])
	var before := d.load_total(0)
	verify.call(d.play(0,0) and d.play(0,0),"multiple function plays in same turn")
	verify.call(d.load_total(0)<before-3 and d.sides[0].functions.is_empty(),"consumption releases load and lightens")
	verify.call(d.sides[0].discard.size()==2 and d.score(0)==18,"effects execute and used cards discarded")
	d = fresh()
	d.phase = LoadDuel.Phase.DECIDE
	d.sides[0].numbers.assign([number(10,5),number(10,5),number(10,5),number(5,4)])
	d.sides[0].pile.assign([number(8,2)])
	d.draw(0)
	verify.call(d.load_total(0)==21 and d.phase==LoadDuel.Phase.ACTION and d.score(0)>21,"load21 allowed; score above21 allowed")
	d = fresh()
	d.phase = LoadDuel.Phase.DECIDE
	d.sides[0].numbers.assign([number(10,5),number(10,5),number(10,5),number(2,3)])
	d.sides[0].functions.assign([function(0)])
	d.sides[0].pile.assign([number(8,2)])
	d.draw(0)
	verify.call(d.winner==1 and d.overloaded==0 and not d.play(0,0),"overload immediately loses with no rescue")
	d = fresh()
	d.phase = LoadDuel.Phase.DECIDE
	d.sides[0].functions.assign([function(2),function(2),function(2)])
	d.sides[0].numbers.assign([number(9,5),number(9,5)])
	d.sides[0].pile.assign([function(2)])
	d.draw(0)
	verify.call(d.phase==LoadDuel.Phase.ACTION and d.load_total(0)==19,"full slot discard before load check")
	verify.call(d.sides[0].functions.size()==3 and d.sides[0].discard.size()==1,"no replacement on slot overflow")
	d = fresh()
	d.sides[0].functions.assign([function(2)])
	d.sides[1].stopped = true
	var snapshot: Dictionary = d.sides[1].duplicate(true)
	verify.call(not d.play(0,0) and d.sides[0].functions.size()==1,"cannot target stopped side or spend invalid card")
	verify.call(d.sides[1]==snapshot,"stopped state immutable")
	var load_before := d.load_total(0)
	verify.call(d.discard_function(0,0),"discard blocked interference after enemy stops")
	verify.call(d.load_total(0)==load_before-3 and d.sides[0].functions.is_empty(),"discard releases exact load and slot")
	verify.call(d.sides[1]==snapshot and d.sides[0].discard.size()==1,"discard never executes interference")
	d.sides[0].functions.append(function(0))
	verify.call(d.play(0,0),"self effects still work after enemy stops")
	d.end_turn(0)
	verify.call(d.active==0 and d.phase==LoadDuel.Phase.DECIDE,"remaining side receives own next turn")
	d.stop(0)
	verify.call(d.winner==0,"compare once both stopped")
	verify.call(not d.draw(0) and not d.end_turn(0),"finished duel rejects actions")
	verify.call(not d.discard_function(0,0),"finished duel rejects discarding")
	d = fresh()
	d.sides[0].functions.assign([function(0),function(2)])
	var initial_score := d.score(0)
	verify.call(not d.discard_function(1,0) and not d.discard_function(0,-1) and not d.discard_function(0,2),"discard actor and index validation")
	verify.call(d.discard_function(0,0) and d.discard_function(0,0),"multiple discards before opponent stops")
	verify.call(d.score(0)==initial_score and d.score(1)==10 and d.phase==LoadDuel.Phase.ACTION,"discard no effect and no turn end")
	d.sides[0].functions.assign([function(2)])
	d.phase = LoadDuel.Phase.DECIDE
	verify.call(not d.discard_function(0,0),"cannot discard before draw choice")
	d.phase = LoadDuel.Phase.ACTION
	d.sides[0].stopped = true
	verify.call(not d.discard_function(0,0),"stopped owner cannot discard")
	d = fresh()
	d.active = 1
	d.sides[0].stopped = true
	d.sides[1].functions.assign([function(2)])
	d.opponent_step()
	verify.call(d.sides[1].functions.is_empty() and d.score(0)==10,"AI discards unusable interference safely")
	d = fresh()
	d.sides[0].functions.assign([function(2)])
	d.play(0,0)
	verify.call(d.score(1)==7,"interference modifies active enemy largest number")
	d = fresh()
	d.sides[0].functions.assign([function(3),function(4)])
	d.play(0,0)
	verify.call(d.sides[0].numbers.size()==1,"release removes smallest number")
	d.play(0,0)
	verify.call(d.sides[0].peek.size()==2 and d.sides[1].peek.is_empty(),"scout is owner only")
	d = fresh()
	d.sides[1].functions.assign([function(4)])
	d.end_turn(0)
	d.opponent_step()
	verify.call(not "数字 5（负荷2）" in " ".join(d.events),"AI private scout information not logged")
	d = fresh()
	for side in d.sides: side.pile.clear()
	d.end_turn(0)
	d.end_turn(1)
	verify.call(d.phase==LoadDuel.Phase.OVER and d.winner==-1,"empty decks stop without recycling or deadlock")
	var profile := MemoryProfile.new()
	profile.persistence = false
	var saved := profile.cards.duplicate(true)
	var definitions := CombatCatalog.from_profile(profile)
	verify.call(definitions.size()==52,"legacy deck mapped without card loss")
	for seed_value in range(200):
		d = LoadDuel.new()
		d.start(definitions,definitions,seed_value)
		var count := 0
		while d.phase != LoadDuel.Phase.OVER and count < 600:
			count += 1
			step(d)
			for owner in range(2):
				var side: Dictionary = d.sides[owner]
				verify.call(side.numbers.size()+side.functions.size()+side.pile.size()+side.discard.size()==52,"card conservation")
				verify.call(side.functions.size()<=3,"slot bound")
		verify.call(d.phase==LoadDuel.Phase.OVER,"duel terminates")
	verify.call(profile.cards==saved,"combat does not mutate profile")
	for boss in [false,true]:
		var state := NightRun.new()
		state.begin(21,profile)
		state.enter(state.available_ids()[0])
		if boss: state.current_node.kind = "boss"
		var encounter := DuelEncounter.new()
		encounter.start(state)
		var actions := 0
		while encounter.phase != DuelEncounter.Phase.MATCH_OVER and actions < 2000:
			actions += 1
			if encounter.phase == DuelEncounter.Phase.HAND_OVER: encounter.deal_hand()
			else:
				step(encounter.duel)
				encounter.resolve_if_finished()
		verify.call(encounter.phase==DuelEncounter.Phase.MATCH_OVER and state.hp in range(101),"outer settlement integration")
		var result_hp := state.hp
		encounter.resolve_if_finished()
		verify.call(state.hp==result_hp,"settlement idempotent")

static func step(d: LoadDuel) -> void:
	if d.active == 1:
		d.opponent_step()
	elif d.phase == LoadDuel.Phase.DECIDE:
		if d.load_total(0)>=16 or (d.sides[1].stopped and d.score(0)>d.score(1)): d.stop(0)
		else: d.draw(0)
	elif d.phase == LoadDuel.Phase.ACTION:
		for index in range(d.sides[0].functions.size()):
			if d.can_play(0,index):
				d.play(0,index)
				return
		d.end_turn(0)
