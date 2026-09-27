extends RefCounted
var check: Callable

func duel(ids: Array = []) -> LoadDuel:
	var d := LoadDuel.new()
	d.start(RunInventory.starter(),RunInventory.starter(),41,ids,true)
	return d

func force_risk(d: LoadDuel, lose: bool) -> void:
	var probe := RandomNumberGenerator.new()
	for seed_value in range(10000):
		probe.seed = seed_value
		if (probe.randf()<d.public_risk(0)/100.0)==lose:
			d.public_rng.seed = seed_value
			return

func test(verify: Callable) -> void:
	check = verify
	var inv := RunInventory.new()
	inv.reset()
	check.call(inv.cards.size()==16,"starter sixteen cards")
	for i in range(4): check.call(inv.take({"type":"card","card":CombatCatalog.function_card(i)}),"add up to twenty")
	var old: CombatCard = inv.cards[0]
	var offer := {"type":"card","card":CombatCatalog.function_card(9),"cost":15}
	inv.points = 20
	check.call(not inv.take(offer) and inv.points==20 and not offer.get("sold",false),"full deck rejects purchase atomically")
	check.call(not inv.take(offer,99) and inv.cards[0]==old,"invalid replacement preserves deck")
	check.call(inv.take(offer,0) and inv.points==5 and inv.cards.size()==20 and inv.cards[0]!=old,"replacement commits payment and stock together")
	check.call(not inv.take(offer,1) and inv.points==5,"sold stock cannot charge twice")
	while inv.cards.size()>2: check.call(inv.remove(0),"safe removal")
	check.call(not inv.remove(0),"minimum two enforced")
	check.call(inv.take({"type":"relic","id":"R06"}) and not inv.take({"type":"relic","id":"R06"}),"unique relic IDs")
	inv.reset()
	check.call(inv.cards.size()==16 and inv.points==0 and inv.relics.is_empty(),"new run resets inventory")

	var d := duel(["R01","R02","R06","R07","R10"])
	check.call(d.load_limit(0)==20 and d.slot_limit(0)==3 and d.load_limit(1)==21,"relic parameter stacking affects owner only")
	d = duel(["R03"])
	check.call(d.sides[0].weight_used,"weight relic used by initial number")
	d.sides[0].numbers.clear()
	d.sides[0].functions.clear()
	d.sides[0].weight_used = false
	d.sides[0].numbers.append(CombatCatalog.number_card(9,18).instance(101))
	d.sides[0].pile.assign([CombatCatalog.number_card(8,4).instance(102)])
	d.phase = LoadDuel.Phase.DECIDE
	d.active = 0
	d.draw(0)
	check.call(d.phase!=LoadDuel.Phase.OVER and d.load_total(0)==21 and d.public_risk(0)==10,"weight applied before overload; last own card has no public risk")
	d = duel(["R04","R05","R06"])
	d.sides[0].numbers.assign([CombatCatalog.number_card(9,2).instance(103)])
	d.sides[0].functions.assign([CombatCatalog.function_card(7).instance(104),CombatCatalog.function_card(10).instance(105)])
	d.phase = LoadDuel.Phase.DECIDE
	d.stop(0)
	check.call(d.sides[0].watch_bonus==4,"watch records load at voluntary stand")
	d.sides[1].numbers.assign([CombatCatalog.number_card(8,4).instance(106)])
	CombatPassives.dispatch(d,"number_drawn",1,d.sides[1].numbers[0])
	check.call(d.sides[0].trap_bonus==3 and d.sides[0].stopped,"stopped trap owner still receives shuttle bonus")
	check.call(d.projected_score(0)==20,"card and relic percent add with a single floor")
	d = duel(["R07"])
	d.sides[0].numbers.clear()
	d.sides[0].functions.clear()
	for i in range(4): d.sides[0].numbers.append(CombatCatalog.number_card(2,1).instance(i))
	check.call(d.projected_score(0)==14 and d.slot_limit(0)==2,"candle formation and slot cost")
	d = LoadDuel.new()
	var two: Array[CombatCard] = [CombatCatalog.number_card(2,1),CombatCatalog.number_card(3,2)]
	d.start(two,two,12,["R09"],true)
	check.call(d.sides[0].peek.is_empty(),"gear does not peek public pile")
	d.phase = LoadDuel.Phase.DECIDE
	d.active = 0
	force_risk(d,true)
	d.draw(0)
	check.call(d.winner==1 and d.sides[0].public_draws==1 and d.sides[1].public_draws==0 and d.public_pile.is_empty(),"public failure is independent and precedes card entry")
	d.start(two,two,12,[],true)
	d.phase = LoadDuel.Phase.DECIDE
	d.sides[0].functions.assign([CombatCatalog.function_card(0).instance(1),CombatCatalog.function_card(1).instance(2),CombatCatalog.function_card(2).instance(3)])
	d.public_pile.assign([CombatCatalog.function_card(3).instance(999)])
	force_risk(d,false)
	d.draw(0)
	check.call(d.sides[0].public_draws==1 and d.sides[0].discard.size()==1 and d.public_risk(0)==20,"full slot discard still consumes public attempt")
	d.sides[0].public_draws = 100
	check.call(d.public_risk(0)==80,"public risk capped")
	d.start(two,two,12,[],true)
	check.call(d.sides[0].public_draws==0 and d.sides[0].numbers.size()==2,"new hand restores personal deck and resets risk")
	d.phase = LoadDuel.Phase.DECIDE
	d.stop(0)
	check.call(d.sides[0].stopped and d.sides[0].public_draws==0,"empty own pile can stand without risk")

	for seed_value in range(100):
		var run := NightRun.new()
		var profile := MemoryProfile.new()
		profile.persistence = false
		run.begin(seed_value,profile,true)
		var state := run.castle
		var shops := 0
		var events := 0
		for room in state.layout.rooms:
			if room.kind=="shop": shops += 1
			if room.kind=="event": events += 1
		check.call(shops>=1 and shops<=2 and events>=2,"guaranteed mixed room distribution")
		var key: int = state.layout.copper.a
		var gear: int = state.layout.copper.b
		var altar: int = state.layout.ladders.back().upper
		state.move(-10)
		check.call(state.current==key and state.interact()=="content" and not state.locked(),"key event reached without combat lock")
		state.move(-10)
		check.call(state.current==key and not state.can_pass(key,gear),"copper door physically blocks movement")
		state.player_x = -10
		check.call(run.claim_offer(0) and "R08" in state.relics,"key acquisition shared with traversal")
		check.call(not run.claim_offer(0),"event reward idempotent")
		state.move(-4)
		check.call(state.interact()=="unlock" and state.can_pass(key,gear),"key opens actual copper passage")
		state.move(-6)
		check.call(state.current==gear and state.room_visibility(altar)==0,"hidden ladder does not reveal adjacent altar")
		check.call(run.claim_offer(0) and state.interact()=="clock","gear event enables clock interaction")
		check.call(state.room_visibility(altar)==1,"clock activates real ladder connection and fog")
		state.move(-2.5)
		check.call(state.interact()=="ladder" and state.current==altar,"activated ladder traversable")
		state.move(2.5)
		check.call(run.claim_offer(0) and "R10" in run.inventory.relics,"altar grants ending relic")
		run.finish_run(true)
		check.call(run.can_choose_name_ending(),"clock and mark unlock optional victory ending")
		check.call(profile.loops==0,"new progression does not mutate legacy profile")

	for seed_value in range(100):
		var simulation := LoadDuel.new()
		simulation.start(two,two,seed_value,["R03","R05"],true)
		var actions := 0
		while simulation.phase!=LoadDuel.Phase.OVER and actions<500:
			load("res://tests/load_duel_test.gd").step(simulation)
			actions += 1
		check.call(actions<500,"public deck duels terminate")
