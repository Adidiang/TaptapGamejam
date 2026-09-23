class_name MemoryDeck
extends RefCounted
## Owns card instances and the draw / hand / discard lifecycle.

var cards: Array[MemoryCard] = []
var draw_pile: Array[MemoryCard] = []
var hand: Array[MemoryCard] = []
var discard_pile: Array[MemoryCard] = []
var rng := RandomNumberGenerator.new()

func setup(run_seed: int) -> void:
	rng.seed = run_seed
	cards.clear()
	for suit in range(4):
		for rank in range(1, 14):
			cards.append(MemoryCard.new(rank, suit))
	reset_encounter()

func reset_encounter() -> void:
	draw_pile.assign(cards)
	hand.clear()
	discard_pile.clear()
	_shuffle(draw_pile)

func _shuffle(pile: Array[MemoryCard]) -> void:
	for i in range(pile.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var previous := pile[i]
		pile[i] = pile[j]
		pile[j] = previous

func draw_card() -> MemoryCard:
	if draw_pile.is_empty():
		draw_pile.assign(discard_pile)
		discard_pile.clear()
		_shuffle(draw_pile)
	if draw_pile.is_empty():
		return null
	var card: MemoryCard = draw_pile.pop_back()
	hand.append(card)
	return card

func discard_hand() -> void:
	discard_pile.append_array(hand)
	hand.clear()

func hand_points() -> int:
	var total := 0
	var aces := 0
	for card in hand:
		total += card.points()
		if card.rank == 1:
			aces += 1
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total
