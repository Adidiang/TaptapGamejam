class_name MemoryProfile
extends RefCounted
const PATH := "user://memory_profile_v1.json"
var save_path := PATH
var cards: Array = []
var upgrades: Array[int] = []
var removed_old := 0
var loops := 0
var next_id := 1
var persistence := true
var save_error := ""

func _init() -> void:
	reset()

func reset() -> void:
	cards.clear()
	upgrades.clear()
	removed_old = 0
	loops = 0
	next_id = 1
	for suit in range(4):
		for rank in range(1,14):
			cards.append({"id":str(next_id),"rank":rank,"suit":suit})
			next_id += 1

func load_profile() -> void:
	if not persistence or not FileAccess.file_exists(save_path): return
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary or data.get("version") != 1:
		_invalid()
		return
	var entries = data.get("cards",[])
	var unique: Dictionary = {}
	var valid: bool = entries is Array and entries.size() >= 20 and entries.size() <= 60
	if valid:
		for card in entries:
			if not card is Dictionary:
				valid = false
				break
			var key := str(card.get("id",""))
			if not key.is_valid_int() or int(key) < 1 or unique.has(key) or int(card.get("rank",0)) not in range(1,14) or int(card.get("suit",-1)) not in range(4):
				valid = false
				break
			unique[key] = true
	if not valid:
		_invalid()
		return
	cards.clear()
	next_id = 1
	for card in entries:
		cards.append({"id":str(card.id),"rank":int(card.rank),"suit":int(card.suit)})
		next_id = maxi(next_id,int(card.id)+1)
	upgrades.clear()
	var saved_upgrades = data.get("upgrades",[])
	if saved_upgrades is Array:
		for rank in saved_upgrades:
			if int(rank) in range(1,14) and int(rank) not in upgrades: upgrades.append(int(rank))
	removed_old = maxi(0,int(data.get("removed_old",0)))
	loops = maxi(0,int(data.get("loops",0)))

func _invalid() -> void:
	save_error = "存档格式异常，使用初始牌库；原文件未改动。"
	persistence = false

func save_profile() -> void:
	if not persistence: return
	var file := FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file == null:
		save_error = "无法写入存档，进度仍在内存中。"
		return
	file.store_string(JSON.stringify({"version":1,"cards":cards,"upgrades":upgrades,"removed_old":removed_old,"loops":loops}))
	file.close()
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path+".tmp"),ProjectSettings.globalize_path(save_path))
	save_error = "" if err == OK else "存档替换失败，进度仍在内存中。"

func upgrade(rank: int) -> bool:
	if rank not in range(1,14) or rank in upgrades: return false
	upgrades.append(rank)
	save_profile()
	return true

func add_card(rank: int,suit: int) -> bool:
	if cards.size() >= 60 or rank not in range(1,14) or suit not in range(4): return false
	cards.append({"id":str(next_id),"rank":rank,"suit":suit})
	next_id += 1
	save_profile()
	return true

func remove_card(id: String) -> bool:
	if cards.size() <= 20: return false
	for i in range(cards.size()):
		if cards[i].id == id:
			var rank: int = cards[i].rank
			if rank == 1 or rank >= 10: removed_old += 1
			cards.remove_at(i)
			save_profile()
			return true
	return false

func make_deck(seed_value: int) -> MemoryDeck:
	var deck := MemoryDeck.new()
	deck.rng.seed = seed_value
	for entry in cards:
		var card := MemoryCard.new(entry.rank,entry.suit)
		card.id = entry.id
		deck.cards.append(card)
	deck.reset_encounter()
	return deck

func upgrade_choices(rng: RandomNumberGenerator,count: int = 3) -> Array[int]:
	var options: Array[int] = []
	for rank in range(1,14):
		if rank not in upgrades: options.append(rank)
	var result: Array[int] = []
	while not options.is_empty() and result.size() < count:
		var i := rng.randi_range(0,options.size()-1)
		result.append(options[i])
		options.remove_at(i)
	return result
