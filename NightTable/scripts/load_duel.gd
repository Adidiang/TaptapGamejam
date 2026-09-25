class_name LoadDuel
extends RefCounted
## No run economy or UI dependencies. Public actions validate all state transitions.
enum Phase { DECIDE, ACTION, OVER }
var sides: Array = []
var active := 0
var phase := Phase.ACTION
var winner := -2 # -2 ongoing, -1 tie, 0 player, 1 opponent
var overloaded := -1
var reason := ""
var events: Array[String] = []
var effects := CombatEffects.new()
var slots := CombatCatalog.SLOT_LIMIT
var limit := CombatCatalog.LOAD_LIMIT
var turns := 0
var final_scores: Array = []

func start(player_cards: Array[CombatCard], opponent_cards: Array[CombatCard], seed_value: int) -> void:
	sides.clear()
	events.clear()
	active = 0
	phase = Phase.ACTION
	winner = -2
	overloaded = -1
	reason = ""
	turns = 0
	final_scores.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var serial := 0
	for definitions in [player_cards,opponent_cards]:
		var side := {"pile":[],"numbers":[],"functions":[],"discard":[],"stopped":false,"first":true,"peek":[]}
		for definition in definitions:
			serial += 1
			side.pile.append(definition.instance(serial))
		for i in range(side.pile.size()-1,0,-1):
			var j := rng.randi_range(0,i)
			var card: Dictionary = side.pile[i]
			side.pile[i] = side.pile[j]
			side.pile[j] = card
		sides.append(side)
	for owner in range(2):
		for i in range(2):
			if phase != Phase.OVER: _draw(owner,false)
	if phase != Phase.OVER:
		sides[0].first = false
		note("双方各抽两张。你先操作，首回合不额外摸牌。")

func note(message: String) -> void:
	events.append(message)
	if events.size() > 10: events.pop_front()

func score(owner: int) -> int:
	var total := 0
	for card in sides[owner].numbers: total += int(card.value)
	return total

func load_total(owner: int) -> int:
	var total := 0
	for zone in ["numbers","functions"]:
		for card in sides[owner][zone]: total += int(card.load)
	return total

func projected_score(owner: int) -> int:
	return CombatPassives.settlement(self,owner).total

func _draw(owner: int, trigger_traps: bool = true) -> void:
	var side: Dictionary = sides[owner]
	side.peek.clear()
	if side.pile.is_empty(): return
	var card: Dictionary = side.pile.pop_back()
	var definition: CombatCard = card.definition
	if definition.kind == "function" and side.functions.size() >= slots:
		side.discard.append(card)
		note("%s功能槽已满，摸到的功能牌被弃掉。" % label_for(owner))
		return
	side["numbers" if definition.kind == "number" else "functions"].append(card)
	note("%s摸到%s。" % [label_for(owner),definition.title if definition.kind == "number" or owner == 0 else "一张功能暗牌"])
	if load_total(owner) > limit:
		overloaded = owner
		_finish(1-owner,"%s负荷超过%d，立即落败。" % [label_for(owner),limit])
		return
	if trigger_traps and definition.kind == "number": CombatPassives.dispatch(self,"number_drawn",owner,card)

func draw(owner: int) -> bool:
	if phase != Phase.DECIDE or owner != active or sides[owner].stopped: return false
	if sides[owner].pile.is_empty(): return stop(owner)
	phase = Phase.ACTION
	_draw(owner)
	return true

func can_play(owner: int, index: int) -> bool:
	if phase != Phase.ACTION or owner != active or sides[owner].stopped: return false
	if index not in range(sides[owner].functions.size()): return false
	if sides[owner].functions[index].definition.function_type != "effect": return false
	return effects.can_apply(self,owner,sides[owner].functions[index].definition)

func play(owner: int, index: int) -> bool:
	if not can_play(owner,index): return false
	var card: Dictionary = sides[owner].functions[index]
	var definition: CombatCard = card.definition
	# Remove first, so the load is released before the effect resolves.
	sides[owner].functions.remove_at(index)
	sides[owner].discard.append(card)
	effects.apply(self,owner,definition)
	note("%s使用「%s」，释放%d负荷。" % [label_for(owner),definition.title,card.load])
	CombatPassives.dispatch(self,"effect_played",owner)
	return true

func can_discard(owner: int, index: int) -> bool:
	return phase == Phase.ACTION and owner == active and not sides[owner].stopped and index in range(sides[owner].functions.size())

func discard_function(owner: int, index: int) -> bool:
	if not can_discard(owner,index): return false
	var card: Dictionary = sides[owner].functions[index]
	sides[owner].functions.remove_at(index)
	sides[owner].discard.append(card)
	# Discarding is not playing: never execute effects or reveal an opponent's card.
	note("%s弃掉一张功能牌，释放负荷与槽位。" % label_for(owner))
	return true

func end_turn(owner: int) -> bool:
	if phase != Phase.ACTION or owner != active: return false
	CombatPassives.dispatch(self,"turn_ended",owner)
	_advance()
	return true

func stop(owner: int) -> bool:
	if phase != Phase.DECIDE or owner != active: return false
	sides[owner].stopped = true
	note("%s停牌，数字%d已锁定。" % [label_for(owner),score(owner)])
	_advance()
	return true

func _advance() -> void:
	turns += 1
	if sides[0].stopped and sides[1].stopped:
		final_scores = [CombatPassives.settlement(self,0),CombatPassives.settlement(self,1)]
		var first: int = final_scores[0].total
		var second: int = final_scores[1].total
		_finish(-1 if first == second else (0 if first>second else 1),"结算比较：%d 对 %d（含加成）。" % [first,second])
		return
	var next := 1-active
	if sides[next].stopped: next = active
	active = next
	phase = Phase.ACTION if sides[active].first else Phase.DECIDE
	sides[active].first = false
	if phase == Phase.DECIDE and sides[active].pile.is_empty(): stop(active)

func _finish(result: int, message: String) -> void:
	winner = result
	reason = message
	phase = Phase.OVER
	note(message)

func label_for(owner: int) -> String:
	return "你" if owner == 0 else "对方"

func opponent_step() -> void:
	# One visible action per UI step; AI only reads its own hidden information.
	if phase == Phase.OVER or active != 1: return
	if phase == Phase.DECIDE:
		var ahead := projected_score(1) > score(0)
		if (sides[0].stopped and ahead) or load_total(1) >= 17:
			stop(1)
		else: draw(1)
		return
	for index in range(sides[1].functions.size()):
		var card: CombatCard = sides[1].functions[index].definition
		if card.function_type != "effect": continue
		if card.effect == "release" and (load_total(1) < 15 or sides[0].stopped): continue
		if can_play(1,index):
			play(1,index)
			return
	# Keep settlement bonuses and armed traps; discard only unusable active cards/dead traps.
	for index in range(sides[1].functions.size()):
		var card: CombatCard = sides[1].functions[index].definition
		if card.function_type == "effect" or (card.function_type == "trap" and sides[0].stopped):
			discard_function(1,index)
			return
	end_turn(1)
