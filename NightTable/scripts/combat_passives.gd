class_name CombatPassives
extends RefCounted
## Settlement is pure. Trap hooks never emit another hook, so effects cannot recurse.
static func settlement(duel, owner: int) -> Dictionary:
	var base: int = duel.score(owner)
	var flat := 0
	var percent := 0
	var names: Array[String] = []
	for instance in duel.sides[owner].functions:
		var card: CombatCard = instance.definition
		if card.function_type != "bonus": continue
		names.append(card.title)
		match card.effect:
			"flat": flat += card.amount
			"percent": percent += card.amount
			"formation":
				if duel.sides[owner].numbers.size()>=5: flat += card.amount
	return {"base":base,"flat":flat,"percent":percent,"total":floori((base+flat)*(100+percent)/100.0),"names":names}

static func dispatch(duel, event: String, actor: int, context: Dictionary = {}) -> void:
	var owner := 1-actor
	# Traps respond to the opponent's actions even after their owner has stopped.
	if duel.phase == LoadDuel.Phase.OVER or duel.sides[actor].stopped: return
	# Snapshot order avoids mutation skipping the next trap as consumed slots shift.
	var candidates: Array = duel.sides[owner].functions.duplicate()
	for instance in candidates:
		var card: CombatCard = instance.definition
		if card.function_type != "trap" or card.trigger != event: continue
		if duel.sides[actor].numbers.is_empty(): continue
		var detail := ""
		match event:
			"number_drawn":
				if context.is_empty() or context.value<7: continue
				context.value = maxi(0,context.value-card.amount)
				detail = "对方摸入大数字：新牌减少%d点" % card.amount
			"effect_played":
				duel.effects.apply(duel,owner,card)
				detail = "对方使用效果牌：最大数字减少%d点" % card.amount
			"turn_ended":
				if duel.score(actor)<20: continue
				duel.effects.apply(duel,owner,card)
				detail = "对方回合结束且数字≥20：最大数字减少%d点" % card.amount
			_: continue
		duel.sides[owner].functions.erase(instance)
		duel.sides[owner].discard.append(instance)
		duel.note("%s的陷阱「%s」触发 · %s；释放%d负荷。" % [duel.label_for(owner),card.title,detail,instance.load])
