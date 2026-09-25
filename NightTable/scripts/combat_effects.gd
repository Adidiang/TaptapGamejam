class_name CombatEffects
extends RefCounted
## Register a handler here to add an effect; the duel enforces turn/target/consumption rules.
var handlers: Dictionary = {}

func _init() -> void:
	handlers = {"boost":_boost,"lighten":_lighten,"cut":_cut,"release":_release,"scout":_scout,"rally":_rally,"weaken":_weaken}

func select_card(cards: Array, field: String, greatest: bool = true) -> Dictionary:
	var selected: Dictionary = {}
	for card in cards:
		if selected.is_empty() or (card[field] > selected[field] if greatest else card[field] < selected[field]): selected = card
	return selected

func can_apply(duel, owner: int, definition: CombatCard) -> bool:
	if not handlers.has(definition.effect): return false
	var target: int = owner if definition.target == "self" else 1-owner
	if duel.sides[target].stopped: return false
	if definition.effect == "scout": return not duel.sides[owner].pile.is_empty()
	return not duel.sides[target].numbers.is_empty()

func apply(duel, owner: int, definition: CombatCard) -> void:
	handlers[definition.effect].call(duel,owner,definition)

func _boost(duel, owner: int, card: CombatCard) -> void:
	select_card(duel.sides[owner].numbers,"value").value += card.amount

func _lighten(duel, owner: int, card: CombatCard) -> void:
	var target := select_card(duel.sides[owner].numbers,"load")
	target.load = maxi(1,target.load-card.amount)

func _cut(duel, owner: int, card: CombatCard) -> void:
	var target := select_card(duel.sides[1-owner].numbers,"value")
	target.value = maxi(0,target.value-card.amount)

func _rally(duel, owner: int, card: CombatCard) -> void:
	for target in duel.sides[owner].numbers: target.value += card.amount

func _weaken(duel, owner: int, card: CombatCard) -> void:
	var target := select_card(duel.sides[1-owner].numbers,"value",false)
	target.value = maxi(0,target.value-card.amount)

func _release(duel, owner: int, _card: CombatCard) -> void:
	var target := select_card(duel.sides[owner].numbers,"value",false)
	duel.sides[owner].numbers.erase(target)
	duel.sides[owner].discard.append(target)

func _scout(duel, owner: int, card: CombatCard) -> void:
	var pile: Array = duel.sides[owner].pile
	duel.sides[owner].peek.clear()
	for i in range(mini(card.amount,pile.size())):
		var definition: CombatCard = pile[pile.size()-1-i].definition
		duel.sides[owner].peek.append("%s（负荷%d）" % [definition.title,definition.load_cost])
