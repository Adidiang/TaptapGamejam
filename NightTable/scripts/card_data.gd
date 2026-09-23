class_name MemoryCard
extends RefCounted
## A card definition; presentation does not own gameplay state.

var id: String
var rank: int
var suit: int

func _init(card_rank: int = 1, card_suit: int = 0) -> void:
	rank = card_rank
	suit = card_suit
	id = "%s_%s" % [suit, rank]

func rank_text() -> String:
	return {1: "A", 11: "J", 12: "Q", 13: "K"}.get(rank, str(rank))

func suit_text() -> String:
	return ["♠", "♥", "♣", "♦"][suit]

func is_old_memory() -> bool:
	return rank == 1 or rank >= 10

func points() -> int:
	return 11 if rank == 1 else mini(rank, 10)

func memory_text() -> String:
	return "旧日记忆" if is_old_memory() else "新的未来"
