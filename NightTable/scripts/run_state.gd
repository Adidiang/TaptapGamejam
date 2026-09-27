class_name NightRun
extends RefCounted
var profile: MemoryProfile
var run_seed := 0
var act := 0
var hp := 100
var layers: Array = []
var visited: Array[int] = []
var total_visited := 0
var current_node: Dictionary = {}
var deck := MemoryDeck.new()
var rng := RandomNumberGenerator.new()
var relics: Array[String] = []
var items: Array[String] = []
var active := false
var pending := false
var encounter_count := 0
var legacy_text := ""
var ending := ""
var castle: CastleExploration
var inventory := RunInventory.new()

func can_manage_inventory() -> bool:
	return active and castle!=null and not pending and not castle.in_battle and not castle.in_dialogue and not castle.locked()

func room_offers() -> Array:
	if castle==null: return []
	var room := castle.room()
	var offers: Array = room.get("offers",[])
	if room.kind=="event" and not room.get("completed",false) and not room.has("title"):
		var available := false
		for offer in offers:
			if offer.type!="relic" or offer.id not in inventory.relics: available = true
		if not available:
			room.offers = [{"type":"points","amount":20}]
			offers = room.offers
	return offers

func claim_offer(index: int, replace: int = -1) -> bool:
	if not can_manage_inventory(): return false
	var room := castle.room()
	if room.kind not in ["event","shop"] or (room.kind=="event" and room.get("completed",false)): return false
	var offers := room_offers()
	if index not in range(offers.size()) or not inventory.take(offers[index],replace): return false
	if room.kind=="event": room.completed = true
	return true

func skip_event() -> void:
	if can_manage_inventory() and castle.room().kind=="event": castle.room().completed = true

func can_choose_name_ending() -> bool:
	return ending=="dawn" and castle!=null and castle.layout.get("clock_started",false) and "R10" in inventory.relics

func begin(new_seed: int,memory: MemoryProfile = null,use_castle: bool = false) -> void:
	profile = memory if memory != null else MemoryProfile.new()
	run_seed = new_seed
	rng.seed = new_seed
	act = 0
	hp = 100
	relics.clear()
	items.assign(["undo"])
	active = true
	total_visited = 0
	ending = ""
	legacy_text = ""
	castle = null
	if use_castle:
		inventory.reset()
		items.clear()
		castle = CastleExploration.new()
		castle.start(new_seed,true)
		castle.relics = inventory.relics
		layers.clear()
		visited.clear()
		current_node = {}
		pending = false
		encounter_count = 0
		deck = profile.make_deck(new_seed)
		return
	_new_act()

func start_castle_encounter() -> bool:
	if castle==null or not active or pending or not castle.in_battle: return false
	var room := castle.room()
	if room.kind not in ["encounter","boss"] or room.cleared or not room.triggered: return false
	current_node = {"id":room.id,"kind":room.kind,"row":room.floor,"column":room.column}
	act = 2 if room.kind=="boss" else maxi(0,room.floor-1)
	pending = true
	total_visited += 1
	visited.append(room.id)
	if room.kind=="encounter": encounter_count += 1
	return true

func _new_act() -> void:
	layers = RouteGenerator.generate(run_seed+act*7919)
	for layer in layers:
		for node in layer:
			if node.row in [0,3,5]: node.kind = "encounter"
			elif node.row == 2: node.kind = "event" if node.column%2 == 0 else "rest"
			elif node.row == 4: node.kind = "shop"
	visited.clear()
	current_node = {}
	pending = false
	encounter_count = 0
	deck = profile.make_deck(run_seed+act*997)

func available_ids() -> Array:
	if castle!=null: return []
	if not active or pending: return []
	if current_node.is_empty(): return [layers[0][0].id]
	return current_node.next

func find_node(node_id: int) -> Dictionary:
	for layer in layers:
		for node in layer:
			if node.id == node_id: return node
	return {}

func enter(node_id: int) -> bool:
	if node_id not in available_ids(): return false
	current_node = find_node(node_id)
	visited.append(node_id)
	total_visited += 1
	pending = true
	if current_node.kind == "encounter": encounter_count += 1
	return true

func nominal_stake() -> int:
	if current_node.get("kind") == "boss": return hp
	return [50,30,15,8][mini(maxi(encounter_count-1,0),3)]

func heal(amount: int) -> void:
	hp = clampi(hp+amount,0,100)

func finish_node() -> void:
	if not active or not pending: return
	pending = false
	if castle!=null:
		if hp<=0: finish_run(false)
		else:
			castle.complete_room()
			if current_node.kind=="boss": finish_run(hp>1)
		return
	if hp <= 0: finish_run(false)
	elif current_node.kind == "boss":
		if act == 2: finish_run(hp > 1)
		else:
			act += 1
			_new_act()

func finish_run(victory: bool) -> void:
	if not active: return
	active = false
	pending = false
	if castle!=null:
		ending = "dawn" if victory else "again"
		legacy_text = "本轮结束。下一轮将重新配置起始牌组与遗物。"
		return
	ending = "release" if victory and profile.removed_old >= 8 else ("dawn" if victory else "again")
	profile.loops += 1
	var options := profile.upgrade_choices(rng,1)
	if not options.is_empty():
		profile.upgrade(options[0])
		legacy_text = "带往下次轮回：%s · %s 已升级" % [GameCatalog.rank_name(options[0]),GameCatalog.SKILLS[options[0]][0]]
	else: legacy_text = "所有点数均已升级，牌库与删除记录继续保留。"
	profile.save_profile()

func add_relic(id: String) -> bool:
	if not GameCatalog.RELICS.has(id) or id in relics or relics.size() >= 6: return false
	relics.append(id)
	return true

func remove_memory(id: String) -> bool:
	if not profile.remove_card(id): return false
	if "release" in relics: heal(3)
	return true
