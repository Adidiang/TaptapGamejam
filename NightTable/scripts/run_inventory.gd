class_name RunInventory
extends RefCounted
## Run-owned definitions; combat always creates separate card instances.
const MIN_CARDS := 2
const MAX_CARDS := 20
var cards: Array[CombatCard] = []
var relics: Array[String] = []
var points := 0

func reset() -> void:
	cards = starter()
	relics.clear()
	points = 0

static func starter() -> Array[CombatCard]:
	var result: Array[CombatCard] = []
	for value in range(2,7):
		for copy in range(2): result.append(CombatCatalog.number_card(value,ceili(value/2.0)))
	for index in [0,1,3,4,8,10]: result.append(CombatCatalog.function_card(index))
	return result

static func pool() -> Array[CombatCard]:
	var result: Array[CombatCard] = []
	for value in range(1,10): result.append(CombatCatalog.number_card(value,ceili(value/2.0)))
	for index in range(CombatCatalog.FUNCTIONS.size()): result.append(CombatCatalog.function_card(index))
	return result

func remove(index: int) -> bool:
	if cards.size()<=MIN_CARDS or index not in range(cards.size()): return false
	cards.remove_at(index)
	return true

func take(offer: Dictionary, replace: int = -1) -> bool:
	# Validate the entire transaction before mutating inventory, balance or stock.
	var cost: int = offer.get("cost",0)
	if offer.get("sold",false) or cost<0 or points<cost: return false
	match offer.type:
		"card":
			if not offer.get("card") is CombatCard: return false
			if replace != -1 and replace not in range(cards.size()): return false
			if replace == -1 and cards.size()>=MAX_CARDS: return false
		"relic":
			if not RelicCatalog.DATA.has(offer.id) or offer.id in relics: return false
		"points":
			if offer.get("amount",0)<0: return false
		_: return false
	points -= cost
	match offer.type:
		"card":
			if replace>=0: cards[replace] = offer.card
			else: cards.append(offer.card)
		"relic": relics.append(offer.id)
		"points": points += offer.amount
	offer.sold = true
	return true
